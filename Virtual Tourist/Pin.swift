//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 11/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    struct statics {
        static let BOUNDING_BOX_HALF_WIDTH: Double = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT: Double = 1.0
        static let LAT_MIN: Double = -90.0
        static let LAT_MAX: Double = 90.0
        static let LON_MIN: Double = -180.0
        static let LON_MAX: Double = 180.0
        static let entityName = "Pin"
    }
    
    var coordinate: CLLocationCoordinate2D {
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName(statics.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        // Dictionary
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
    }
    
    //overloaded init method to receive coordinates in different way
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName(statics.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.coordinate = coordinate
    }
    
    func getBoundingBoxString() -> String {
        return "\(max(Double(longitude) - statics.BOUNDING_BOX_HALF_WIDTH, statics.LON_MIN)),\(max(Double(latitude) - statics.BOUNDING_BOX_HALF_HEIGHT, statics.LAT_MIN)),\(min(Double(longitude) + statics.BOUNDING_BOX_HALF_HEIGHT, statics.LON_MAX)),\(min(Double(latitude) + statics.BOUNDING_BOX_HALF_HEIGHT, statics.LAT_MAX))"
    }
}