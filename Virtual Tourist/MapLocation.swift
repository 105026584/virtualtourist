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
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    var span: MKCoordinateSpan {
        get {
            return MKCoordinateSpan(latitudeDelta: Double(spanlatitude), longitudeDelta: Double(spanlongitude))
        }
        set {
            spanlatitude = newValue.latitudeDelta
            spanlongitude = newValue.longitudeDelta
        }
    }
    
    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegion(center: coordinate, span: span)
        }
        set {
            coordinate = newValue.center
            span = newValue.span
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(region: MKCoordinateRegion, context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName(statics.entityName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.region = region
    }
}