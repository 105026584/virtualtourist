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

    @IBOutlet weak var myMap: MKMapView!
    
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
            let errorMessage = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            errorMessage.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(errorMessage, animated: true, completion: nil)
        }
        
        myMap.addAnnotations(fetchedResultsControllerPin.fetchedObjects as! [MKAnnotation])

        
        
        // fetch previous map location
        do {
            try fetchedResultsControllerMapLocation.performFetch()
        } catch let error1 as NSError {
            let errorMessage = UIAlertController(title: nil, message: error1.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            errorMessage.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(errorMessage, animated: true, completion: nil)
        }
        // set map Region to stored values, if no mapLocation stored yet, create one
        let mapLocation = fetchedResultsControllerMapLocation.fetchedObjects as! [MapLocation]
        if mapLocation.count > 0 {
            myMap.setRegion(mapLocation[mapLocation.count-1].region, animated: false)
        } else {
            _ = MapLocation(dictionary: [MapLocation.Keys.Latitude: myMap.region.center.latitude, MapLocation.Keys.Longitude: myMap.region.center.longitude, MapLocation.Keys.SpanLatitude: myMap.region.span.latitudeDelta, MapLocation.Keys.SpanLongitude: myMap.region.span.longitudeDelta], context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
        }

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    var mapLocation: MapLocation {
        let storedLocation = fetchedResultsControllerMapLocation.fetchedObjects as! [MapLocation]
        return storedLocation[0]
    }
    
    // use this delegated method to react on changes made by standard gestures and store (UPDATE) latest region information in Core Data
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapLocation.update([MapLocation.Keys.Latitude: mapView.region.center.latitude, MapLocation.Keys.Longitude: mapView.region.center.longitude, MapLocation.Keys.SpanLatitude: mapView.region.span.latitudeDelta, MapLocation.Keys.SpanLongitude: mapView.region.span.longitudeDelta])
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
        performSegueWithIdentifier("showAlbum", sender: view.annotation)
    }
    

    @IBAction func gesturePressMap(sender: AnyObject) {
        if sender.state == UIGestureRecognizerState.Began {
            
            let fingerTip = myMap.convertPoint( sender.locationInView(myMap), toCoordinateFromView: myMap)
            _ = Pin(dictionary: [Pin.Keys.Latitude: Double(fingerTip.latitude), Pin.Keys.Longitude: Double(fingerTip.longitude)], context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            
            /*
            let alertController = UIAlertController(title: nil, message:
                "Long-Press Gesture Detected", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)*/
            
            //how to drag pin around till released !?!?!?!?
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
                myMap.addAnnotation(anObject as! Pin)
                performSegueWithIdentifier("showAlbum", sender: anObject)
            } else if type == .Delete {
                myMap.removeAnnotation(anObject as! Pin)
            } else if type == .Update {
            // TODO - this may be required to handle proper dragging of pin
            }
        }
    }
}

