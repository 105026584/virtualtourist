//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 10/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)

class Photo: NSManagedObject {
    
    struct Keys {
        static let Name = "name"
        static let Path = "path"
    }
    
    struct statics {
        static let entityName = "Photo"
    }
    
    @NSManaged var name: String
    @NSManaged var path: String?
    //@NSManaged var imageData: NSData // TODO << better to store in CoreData or in fileSystem, do some research !
    @NSManaged var pin : Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        // Dictionary
        name = dictionary[Keys.Name] as! String
        path = dictionary[Keys.Path] as! String
    }
    
    var imageIdentifier: String {
        get {
            return NSURL(fileURLWithPath: path!).lastPathComponent!
        }
    }
    
    var image: UIImage? {
        get {
            return FlickRClient.Caches.imageCache.imageWithIdentifier(imageIdentifier)
            //return UIImage(data:imageData)
        }
        set {
            FlickRClient.Caches.imageCache.storeImage(image, withIdentifier: imageIdentifier)
            //imageData = UIImagePNGRepresentation(image!)!
        }
    }
    
}