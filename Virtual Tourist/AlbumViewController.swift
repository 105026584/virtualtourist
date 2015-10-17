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

class AlbumViewController: UIViewController, UICollectionViewDelegate {

    var pin: Pin!
    var mapLocation: MapLocation!
    var isDeleteMode: Bool = false
    var imagesToDelete = [String]()
    var newPin: Bool = false
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    struct bottomButtonContent {
        static let NewCollection: String = "Load new Collection"
        static let DeleteSelected: String = "Delete highlighted Photos"
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
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
        
        // fetch photos
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            let errorMessage = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
            errorMessage.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(errorMessage, animated: true, completion: nil)
        }
        
        bottomButton.setTitle( bottomButtonContent.NewCollection, forState: .Normal )
        bottomButton.enabled = false
        
        if pin.photos!.isEmpty || newPin == true {
            //no photos yet, get some ( check on new pin )
            getImageSet()
        } else {
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
                for a in images {
                    dispatch_async(dispatch_get_main_queue()) {
                        _ = Photo(dictionary: [Photo.Keys.Name: a[0], Photo.Keys.Path: a[1], Photo.Keys.Pin: self.pin], context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
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
/*
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
*/
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
        let width = (collectionView.bounds.width - (5.0 * CGFloat(6))) / CGFloat(3)
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
            bottomButton.enabled = false
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            getImageSet()
        } else if sender.titleLabel?.text == bottomButtonContent.DeleteSelected {
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                if imagesToDelete.contains(photo.imageIdentifier) {
                    sharedContext.deleteObject(photo)
                }
            }
            imagesToDelete = [String]()
            
            CoreDataStackManager.sharedInstance().saveContext()
            setNewCollectionButton()
        }
    }
    
    
    // MARK: - Configure Cell --> adapted from tableViewCell to collectionViewCell
    
    func configureCell(cell: AlbumCollectionViewCell, photo: Photo) {
        var currentImage = UIImage(named: "noImage")
        
        cell.image.image = nil
        
        //print(String(cell.image.layer.opacity))
        if imagesToDelete.contains(photo.imageIdentifier) {
            print("marked for deletion set proper opacity == 0.4")
            cell.image.layer.opacity = 0.4
        } else {
            cell.image.layer.opacity = 1
        }
        
        if photo.path == nil || photo.path == "" {
            currentImage = UIImage(named: "noImage")
        } else if photo.image != nil {
            currentImage = photo.image
            currentImage?.accessibilityIdentifier = photo.imageIdentifier
        }
            
        else { // This is the interesting case. has an image name, but it is not downloaded yet.
            cell.loadIndicator.startAnimating()
            // Start the task that will eventually download the image
            let task = FlickRClient.sharedInstance().taskForImage(photo.path!) { data, error in
                
                if let error = error {
                    print("photo download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Create the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    photo.image = image
                    
                    // update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.image.image = image
                        cell.image.image!.accessibilityIdentifier = photo.imageIdentifier
                        cell.loadIndicator.stopAnimating()
                    }
                }
            }
            
            // This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.image.image = currentImage
    }
    
}



//MARK: - NSFetchedResultsControllerDelegate 

extension AlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        //Prepare for changed content from Core Data
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        noImagesLabel.hidden = controller.fetchedObjects?.count > 0
        bottomButton.enabled = controller.fetchedObjects?.count > 0

        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        photoCollection.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.photoCollection.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollection.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.photoCollection.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}
