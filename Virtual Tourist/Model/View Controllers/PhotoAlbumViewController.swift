//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Gilman on 3/10/19.
//  Copyright © 2019 Matt Gilman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController{
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    var pin: Pin!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    //MARK: Fetch result controller
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        //change this later no need for NSFetchedResult thing
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Views
    // Load view must setupMapview, get Fetched Result Controller and possible grab new photos
    override func viewDidLoad() {
        super.viewDidLoad()
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //dataController = appDelegate.dataController
        setupMapView()
        setupFetchedResultsController()
        print("done")
        
        if fetchedResultsController.fetchedObjects!.count == 0{
            grabPhotos()
        }
        
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //collectionView?.reloadData()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: sets up mapview in collection view
    private func setupMapView(){
        var annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.addAnnotation(annotation)
        
        //get the region I want surrounded by the pin
        let newRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        //set the correct viewing region
        mapView.setRegion(newRegion, animated: true)
        
    }
    
    
    // MARK Collection Button: Delete current photos from core data and add new ones from api
    @IBAction func retrieveNewCollection(_ sender: Any) {
        print("Clicked new collection")
        // delete old photos
        if fetchedResultsController.fetchedObjects!.count > 0 {
            print("deleting photos")
            fetchedResultsController.fetchedObjects?.forEach(){ oldPhoto in
                dataController.viewContext.delete(oldPhoto)
                do{
                    try dataController.viewContext.save()
                }
                catch{
                    self.showMessageToUser(title: "Error deleting old photos", msg: "Old photos / saving aftwards did not work!")
                }
                
            }
            collectionView.reloadData()
            // grab new ones
        }
        grabPhotos()
        
    }
    
    // MARK: Grab the photos from the API here
    func grabPhotos(){
        PhotoClient.sharedInstance().taskForGETMethod(lat: pin.lat, lon: pin.lon) { (success, results, error) in
            if success == false{
                self.showMessageToUser(title: "Error", msg: "Could not load data")
                return
            }
            if let photoArray = results{
                if photoArray.count > 0{
                    print("PHOTO ARRAY COUNT = \(photoArray.count)")
                    for photo in photoArray {
                        // get url
                        guard let imageUrlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
                            self.showMessageToUser(title: "Error", msg: "There was an issue grabbing the url")
                            return
                        }
                        let url = URL(string: imageUrlString)
                        if let imageDataTest = try? Data(contentsOf: url!) {
                            self.addPhoto(url: imageUrlString, data: imageDataTest)
                        }
                        else{
                            self.showMessageToUser(title: "Bad URL or Data", msg: "this url is bad \(imageUrlString)")
                        }
                    }
                }
                else{
                    self.showMessageToUser(title: "No Pictues", msg: "There are no pictures for this location")
                }
            }
        }
    }
    
    private func addPhoto(url: String, data: Data){
        
        let photo = Photo(context: dataController.viewContext)
        photo.url = url
        photo.pin = self.pin
        photo.photo = data
        print("Photo Added")
        try? dataController.viewContext.save()
    }
    
    //MARK: Error Handling
    func showMessageToUser(title: String, msg: String)  {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Here is the number of items\(fetchedResultsController.fetchedObjects!.count)")
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    // here is where i will load each photo
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        let currentPhoto = fetchedResultsController.object(at: indexPath)
        
        print("Setting up view")
        //check if data is already in the core data datafield
        if let photoData = currentPhoto.photo {
            print("there is data \(currentPhoto.url!)")
            cell.imageView.image = UIImage(data: photoData)
        }
        cell.imageView.layoutIfNeeded()
        cell.imageView.layer.masksToBounds = true
        cell.imageView.layer.cornerRadius = cell.imageView.frame.height / 2
        
        return cell
        
        
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        
    }
    
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("INserting in NSFetchedResultCOntrollerDelegate")
            collectionView?.insertItems(at: [newIndexPath!])
            break
        case .delete:
            print("DEleting in NSFetchedResultsControllerDelegate")
            collectionView?.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
            break
        case .move: // do nothing for this option
            break
        }

    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: collectionView.insertSections(indexSet)
        case .delete: collectionView.deleteSections(indexSet)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
}
