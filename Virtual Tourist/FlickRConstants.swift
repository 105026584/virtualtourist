//
//  FlickRConstants.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 11/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import Foundation

extension FlickRClient {
    
    // MARK: - Constants
    struct Constants {
        
        static let ApiKey : String = "117b4aa1e6dd620d8ea859c6f36f53be"
        static let Extras : String = "url_m"
        static let SafeSearch : String = "1"
        static let DataFormat : String = "json"
        static let NoJSONCallback : String = "1"
        // MARK: URLs
        static let BaseURL : String = "https://api.flickr.com/services/rest/"
    }
    
    // MARK: - Methods
    struct Methods {
        
        // MARK: Photo search method
        static let PhotoSearch = "flickr.photos.search"

    }
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let SafeSearch = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    struct JSONResponseKeys {
        static let PhotoContainer = "photos"
        static let Pages = "pages"
        static let Total = "total"
        static let Title = "title"
        static let ImageUrl = "url_m"
    }
}