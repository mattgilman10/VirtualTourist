//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Matthew Gilman on 3/10/19.
//  Copyright © 2019 Matt Gilman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

/**
 * This view controller demonstrates the objects involved in displaying pins on a map.
 *
 * The map is a MKMapView.
 * The pins are represented by MKPointAnnotation instances.
 *
 * The view controller conforms to the MKMapViewDelegate so that it can receive a method
 * invocation when a pin annotation is tapped. It accomplishes this using two delegate
 * methods: one to put a small "info" button on the right side of each pin, and one to
 * respond when the "info" button is tapped.
 */

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    // The map. See the setup in the Storyboard file. Note particularly that the view controller
    // is set up as the map view's delegate.
    @IBOutlet weak var mapView: MKMapView!
    
//    fileprivate func setupFetchedResultsController() {
//        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
//        fetchRequest.sortDescriptors = []
//
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
//        fetchedResultsController.delegate = self
//        do {
//            try fetchedResultsController.performFetch()
//            //setupMap()
//        } catch {
//            fatalError("The fetch could not be performed: \(error.localizedDescription)")
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        // need this for long press to add pin
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        mapView.addGestureRecognizer(longGesture)

        //setupFetchedResultsController()
        setupMap()
        
    }
    
    private func setupMap(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        // display all of the saved data
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            for location in result {
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = location.coordinate
                mapView.addAnnotation(newAnnotation)
            }
        }

    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizer.State.ended {
            let touchLocation = gestureReconizer.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
            //print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            // add coordinates
            let coordinate = CLLocationCoordinate2D(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            //save the pin to the datacontroller
            addPin(location: coordinate)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            return
        }
        if gestureReconizer.state != UIGestureRecognizer.State.began {
            return
        }
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let newLocation = Pin(context: dataController.viewContext)
        newLocation.lat = Double(location.latitude)
        newLocation.lon = Double(location.longitude)
        try? dataController.viewContext.save()
    }
    
    
   
    
    
    
}

extension MapViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Point instances")
        }
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
            
        case .delete:
            mapView.removeAnnotation(pin)
            
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
            
        case .move:
            // N.B. The fetched results controller was set up with a single sort descriptor that produced a consistent ordering for its fetched Point instances.
            fatalError("How did we move a Pin? We have a stable sort.")
        }
    }
}




extension MapViewController: MKMapViewDelegate {
    // MARK: - MKMapViewDelegate
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let value = view.annotation{
            let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            let latitude = value.coordinate.latitude
            let longitude = value.coordinate.longitude
            let predicate = NSPredicate(format: "lat == %@ and lon == %@", argumentArray: [latitude, longitude])
            fetchRequest.predicate = predicate
            if let result = try? dataController.viewContext.fetch(fetchRequest),
                let newPin = result.first {
                performSegue(withIdentifier: "Go", sender: newPin)
            }
        }
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        let DestViewController = segue.destination as! UINavigationController
        if let vc = DestViewController.topViewController as? PhotoAlbumViewController {
            let newPin = sender as? Pin
            vc.pin = newPin
            vc.dataController = dataController
        }
    }
   
    
}

