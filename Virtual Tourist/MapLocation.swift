//
//  MapLocation.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 12/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(MapLocation)

class MapLocation: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let SpanLatitude = "spanlatitude"
        static let SpanLongitude = "spanlongitude"
    }
    
    struct statics {
        static let entityName: String = "MapLocation"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var spanlatitude: NSNumber
    @NSManaged var spanlongitude: NSNumber
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
    }
    
    var span: MKCoordinateSpan {
        return MKCoordinateSpanMake(Double(spanlatitude), Double(spanlongitude))
    }
    
    var region: MKCoordinateRegion {
        return MKCoordinateRegion(center: coordinate, span: span)
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName(statics.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        // Dictionary
        update(dictionary)
    }
    
    func update(dictionary: [String : AnyObject]) {
        latitude = dictionary[Keys.Latitude] as! NSNumber
        longitude = dictionary[Keys.Longitude] as! NSNumber
        spanlatitude = dictionary[Keys.SpanLatitude] as! NSNumber
        spanlongitude = dictionary[Keys.SpanLongitude] as! NSNumber
    }
}