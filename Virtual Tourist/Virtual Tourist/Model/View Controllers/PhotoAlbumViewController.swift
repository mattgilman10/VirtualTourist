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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupFetchedResultsController()
        
        if fetchedResultsController.fetchedObjects!.count == 0{
            grabPhotos()
        }
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // sets up mapview in collection view
    private func setupMapView(){
        var annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.addAnnotation(annotation)
        
        //get the region I want surrounded by the pin
        let newRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        //set the correct viewing region
        mapView.setRegion(newRegion, animated: true)
        
    }
    
    
    
    @IBAction func retrieveNewCollection(_ sender: Any) {
        
    }
    
    func grabPhotos(){
        PhotoClient.sharedInstance().taskForGETMethod(lat: pin.lat, lon: pin.lon) { (success, results, error) in
            if success == false{
                self.showMessageToUser(title: "Error", msg: "Could not load data")
                return
            }
            if let photoArray = results{
                if photoArray.count > 0{
                    for photo in photoArray {
                        // get url
                        guard let imageUrlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
                            self.showMessageToUser(title: "Error", msg: "There was an issue grabbing the url")
                            return
                        }
                        let imageURL = URL(string: imageUrlString)
                        
                    }
                }
                else{
                    self.showMessageToUser(title: "No Pictues", msg: "There are no pictures for this location")
                }
            }
            self.uploadPhotos(photoArray: results)
        }
    }
    
    private func addPhoto(url: String){
        let photo = Photo(context: dataController.viewContext)
        photo.url = url
        photo.pin = self.pin
    }
    
    func uploadPhotos(photoArray: [[String:AnyObject]]?){
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
        return fetchedResultsController.fetchedObjects!.count
    }
    
    // here is where i will load each photo
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        let currentPhoto = fetchedResultsController.object(at: indexPath)
        
        //check if data is already in the core data datafield
        if let photoData = currentPhoto.photo {
            cell.imageView.image = UIImage(data: photoData)
        }
        // no data for this item yet, must go get photo data
        else{
            let url = URL(string: currentPhoto.url!)
            if let imageDataTest = try? Data(contentsOf: url!) {
                let imageData = UIImage(data: imageDataTest)
                DispatchQueue.main.async {
                    cell.imageView.image = imageData
                }
                currentPhoto.photo = imageDataTest
            }
        }
        cell.imageView.layoutIfNeeded()
        cell.imageView.layer.masksToBounds = true
        cell.imageView.layer.cornerRadius = cell.imageView.frame.height / 2
        
        return cell
        
        
    }
    
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
            break
        case .move: // do nothing for this option
            break
        }

    }
    
}
