//
//  AlbumViewController.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 14/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {

    var pin: Pin!
    var mapLocation: MapLocation!
    var isDeleteMode: Bool = false
    var imagesToDelete = [String]()
    
    struct bottomButtonContent {
        static let NewCollection: String = "Load new Collection"
        static let DeleteSelected: String = "Delete highlighted Photos"
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchedResultsController.delegate = self
        photoCollection.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.addAnnotation(pin)
        mapView.setRegion(mapLocation.region, animated: false)
        mapView.userInteractionEnabled = false
        mapView.setCenterCoordinate(pin.coordinate, animated: true)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            let errorMessage = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            errorMessage.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(errorMessage, animated: true, completion: nil)
        }
        
        if pin.photos.isEmpty {
            //no photos yet, get some ( = new pin )
            getImageSet()
        } else {
            bottomButton.titleLabel?.text = bottomButtonContent.NewCollection
            bottomButton.titleLabel?.tintColor = UIColor.redColor()
            bottomButton.enabled = true
        }

        
    }
    
    // MARK: - Core Data
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Photo.statics.entityName)
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.Name, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
    }()

    func getImageSet() {
        FlickRClient().searchPhotosByLocation(pin.getBoundingBoxString(), requiredPhotosCount: 21) { result, error in
            if let images = result {
                dispatch_async(dispatch_get_main_queue()) {
                    for a in images {
                        let photo = Photo(dictionary: [Photo.Keys.Name: a[0], Photo.Keys.Path: a[1]], context: self.sharedContext)
                        photo.pin = self.pin
                    }
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Photo.statics.entityName, forIndexPath: indexPath) as! AlbumCollectionViewCell
        configureCell(cell, photo: photo)
        return cell
    }
    
    
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Step 4: This would be a great place to add the delegate methods

    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
        switch type {
            case .Insert:
                self.photoCollection.insertSections(NSIndexSet(index: sectionIndex))
                
            case .Delete:
                self.photoCollection.deleteSections(NSIndexSet(index: sectionIndex))
            
            default:
                return
        }
    }
    
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    /*
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
        switch type {
            case .Insert:
                photoCollection.insertItemsAtIndexPaths([newIndexPath!])
                
            case .Delete:
                photoCollection.deleteItemsAtIndexPaths([indexPath!])
                
            case .Update:
                let cell = photoCollection.cellForItemAtIndexPath(indexPath!) as! AlbumCollectionViewCell
                let photo = controller.objectAtIndexPath(indexPath!) as! Photo
                self.configureCell(cell, photo: photo)
                
            case .Move:
                photoCollection.deleteItemsAtIndexPaths([indexPath!])
                photoCollection.insertItemsAtIndexPaths([newIndexPath!])
                
            default:
                return
        }
    }
    */
    /*
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.photoCollection!.performBatchUpdates({
            if !self.pendingInserts.isEmpty {
                
                //self.photoCollection.insertSections(self.pendingInserts)
            }
            if !self.pendingDeletes.isEmpty {
                
            }
            }, completion: { finished in
                self.pendingInserts.removeAll(keepCapacity: false)
                self.pendingDeletes.removeAll(keepCapacity: false)
                
                dispatch_async(dispatch_get_main_queue()) {
                    if !self.fetchedResultsController.fetchedObjects!.isEmpty {
                        self.bottomButton.enabled = true
                    }
                }
        })
    }
    */
    
    /*
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                self.photoCollection.insertItemsAtIndexPaths(self.pendingInserts)
            case .Delete:
                self.photoCollection.deleteItemsAtIndexPaths(self.pendingDeletes)
            default:
                break
        }
    }
*/    

    /*
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        //self.tableView.endUpdates()
    }
    */
    
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spaces = CGFloat(2 * 3)
        let width = (collectionView.bounds.width - (5.0 * spaces)) / CGFloat(3)
        return CGSize(width: width, height: width)
    }
    
    
    // MARK: - Delete Image
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! AlbumCollectionViewCell
        if cell.image.layer.opacity == 0.4 {
            for var index:Int = 0 ; index < imagesToDelete.count ;index++ {
                if imagesToDelete[index] == cell.image.image?.accessibilityIdentifier {
                    imagesToDelete.removeAtIndex(index)
                }
            }
            cell.image.layer.opacity = 1
        } else {
            imagesToDelete.append((cell.image.image?.accessibilityIdentifier)!)
            cell.image.layer.opacity = 0.4
        }
        
        if imagesToDelete.count > 0 {
            setDeleteButton()
        } else {
            setNewCollectionButton()
        }
    }
    
    func setDeleteButton() {
        bottomButton.setTitle(bottomButtonContent.DeleteSelected, forState: .Normal)
        bottomButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        bottomButton.backgroundColor = UIColor.redColor()
        bottomButton.enabled = true
    }
    
    func setNewCollectionButton() {
        bottomButton.setTitle(bottomButtonContent.NewCollection, forState: .Normal)
        bottomButton.setTitleColor(UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0), forState: .Normal)
        bottomButton.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
        bottomButton.enabled = true
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        print(String(sectionInfo.numberOfObjects) + " Objects to show")
        return sectionInfo.numberOfObjects
    }
    
    @IBAction func bottomButtonPress(sender: UIButton) {
        
        if sender.titleLabel?.text == bottomButtonContent.NewCollection {
            for photo in self.pin.photos {
                sharedContext.deleteObject(photo)
            }
            photoCollection.reloadData()
            getImageSet()
        } else if sender.titleLabel?.text == bottomButtonContent.DeleteSelected {
            for var index:Int = 0 ; index < imagesToDelete.count ;index++ {
                for photo in self.pin.photos {
                    if imagesToDelete[index] == photo.name {
                        sharedContext.deleteObject(photo)
                    }
                }
            }
            setNewCollectionButton()
            photoCollection.reloadData()
        }
    }
    
    
    // MARK: - Configure Cell --> adapted from tableViewCell to collectionViewCell
    
    func configureCell(cell: AlbumCollectionViewCell, photo: Photo) {
        var currentImage = UIImage(named: "posterPlaceHoldr")
        
        cell.image.image = nil
        cell.loadIndicator.startAnimating()
        
        if photo.path == nil || photo.path == "" {
            currentImage = UIImage(named: "noImage")
        } else if photo.image != nil {
            currentImage = photo.image
            currentImage?.accessibilityIdentifier = photo.name
        }
            
        else { // This is the interesting case. The movie has an image name, but it is not downloaded yet.
            
            // Start the task that will eventually download the image
            let task = FlickRClient.sharedInstance().taskForImage(photo.path!) { data, error in
                
                if let error = error {
                    print("photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    photo.image = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.image.image = image
                        cell.loadIndicator.stopAnimating()
                        cell.image.image?.accessibilityIdentifier = photo.name
                    }
                }
            }
            
            // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.image.image = currentImage
    }
    
}