//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 10/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate {

    var pins = [Pin]()
    var droppedPin: Pin? = nil
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteInformation: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // some delegate assignments to react on different events within this class
        fetchedResultsControllerPin.delegate = self
        fetchedResultsControllerMapLocation.delegate = self
        myMap.delegate = self
        
        
        // fetch pins
        do {
            try fetchedResultsControllerPin.performFetch()
        } catch let error as NSError {
            showAlert(error.localizedDescription)
        }
        
        myMap.addAnnotations(fetchedResultsControllerPin.fetchedObjects as! [MKAnnotation])

        // fetch previous map location
        do {
            try fetchedResultsControllerMapLocation.performFetch()
        } catch let error as NSError {
            showAlert(error.localizedDescription)
        }
        // set map Region to stored values, if no mapLocation stored yet, create one
        let mapLocation = fetchedResultsControllerMapLocation.fetchedObjects as! [MapLocation]
        if mapLocation.count > 0 {
            myMap.setRegion(mapLocation.last!.region, animated: true)
        } else {
            _ = MapLocation(region: myMap.region, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    @IBAction func editPins(sender: UIBarButtonItem) {
        if sender.title == "Done" {
            sender.title = "Edit"
            deleteInformation.hidden = true
        } else {
            sender.title = "Done"
            deleteInformation.hidden = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var mapLocation: MapLocation {
        let storedLocation = fetchedResultsControllerMapLocation.fetchedObjects as! [MapLocation]
        return storedLocation.first!
    }
    
    // use this delegated method to react on changes made by standard gestures and store (UPDATE) latest region information in Core Data
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapLocation.region = mapView.region
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    //doing the segue and passing the pin to be able to show on the Album as well as work with the coordinates
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAlbum" {
            if let controller = segue.destinationViewController as? AlbumViewController {
                controller.pin = sender as! Pin
                controller.mapLocation = mapLocation
            }
        }
    }
    
    //if annotation got selected do the segue to the album
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if deleteInformation.hidden == true {
            performSegueWithIdentifier("showAlbum", sender: view.annotation)
        } else {
            sharedContext.deleteObject(view.annotation as! Pin)
        }
    }
    
    func preLoadImageSet(pin: Pin) {
        FlickRClient().searchPhotosByLocation(pin.getBoundingBoxString(), requiredPhotosCount: 21) { result, error in
            if let images = result {
                for a in images {
                    dispatch_async(dispatch_get_main_queue()) {
                        _ = Photo(dictionary: [Photo.Keys.Name: a[0], Photo.Keys.Path: a[1], Photo.Keys.Pin: pin], context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            }
        }
    }
    
    @IBAction func gesturePressMap(sender: UILongPressGestureRecognizer) {
        
        if deleteInformation.hidden == false {
            showAlert("Please exit Editmode to place new pins")
            return
        }
        
        let mapCoordinates: CLLocationCoordinate2D = myMap.convertPoint(sender.locationInView(myMap), toCoordinateFromView: myMap)
        
        // Check state of LongPressGesture
        switch sender.state {
            
        // Add the pin when LongPressGesture was fired
        case .Began:
            droppedPin = Pin(coordinate: mapCoordinates, context: sharedContext)
            myMap.addAnnotation(droppedPin! as Pin)
        
        // This will be executed while moving around
        case .Changed:
            droppedPin!.willChangeValueForKey("coordinate")
            droppedPin!.coordinate = mapCoordinates
            droppedPin!.didChangeValueForKey("coordinate")
            
        // released, we are good to store the pin now
        case .Ended:
            CoreDataStackManager.sharedInstance().saveContext()
            // load imageset already if new pin got set
            preLoadImageSet(droppedPin!)
            //performSegueWithIdentifier("showAlbum", sender: droppedPin)
            
        default:
            return
        }
    }
    
    // MARK: - Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsControllerPin: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Pin.statics.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Pin.Keys.Longitude, ascending: true)]
        
        let fetchedResultsControllerPin = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsControllerPin
        
    }()
    
    lazy var fetchedResultsControllerMapLocation: NSFetchedResultsController = {
        
        let fetchRequestMapLocation = NSFetchRequest(entityName: MapLocation.statics.entityName)
        fetchRequestMapLocation.sortDescriptors = [NSSortDescriptor(key: MapLocation.Keys.Latitude, ascending: true)]
        
        let fetchedResultsControllerMapLocation = NSFetchedResultsController(fetchRequest: fetchRequestMapLocation, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsControllerMapLocation
        
    }()

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if anObject is Pin {
            if type == .Insert {
                // let this be handled by the LongPressGesture now
                //myMap.addAnnotation(anObject as! Pin)
                //performSegueWithIdentifier("showAlbum", sender: anObject)
            } else if type == .Delete {
                myMap.removeAnnotation(anObject as! Pin)
            } else if type == .Update {
                // no use case at the moment on MapViewController, at the moment
            }
        }
    }
    
    func showAlert(message: String) {
        let messageForAlert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        messageForAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(messageForAlert, animated: true, completion: nil)
    }
    
}

