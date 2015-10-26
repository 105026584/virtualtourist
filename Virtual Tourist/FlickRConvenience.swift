//
//  FlickRConvenience.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 11/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import Foundation

extension FlickRClient {
    
    // requiring some random functions to not get same images over and over again
    // either NSNumber or String can be used (the JSON response for total comes as String)
    // function is recursive and tries to pick different images based on the alreadyTaken Array
    func parseForRandom(number: AnyObject, alreadyTaken: [Int]?) -> Int {
        var randomNumber: Int
        if let parse = number as? NSNumber {
            randomNumber = Int(arc4random_uniform(UInt32(Int(parse))))
        } else {
            randomNumber = Int(arc4random_uniform(UInt32((number as? Int)!)))
        }
        if let takenArray = alreadyTaken {
            while takenArray.contains(randomNumber) && takenArray.count < randomNumber {
                randomNumber = parseForRandom(number, alreadyTaken: takenArray)
            }
        }
        return randomNumber
    }
    
    func searchPhotosByLocation(locationBoundingBox: String, requiredPhotosCount: Int, completionHandler: (result: [[String]]?, error: NSError?) -> Void) {
        
        //method covered within parameters, keeping Client functionality as-is to be able to cover other use-cases more convenient in future
        var mutableMethod: String = ""
        var parameters = [
            ParameterKeys.Method: Methods.PhotoSearch,
            ParameterKeys.ApiKey: Constants.ApiKey,
            ParameterKeys.BoundingBox: locationBoundingBox,
            ParameterKeys.SafeSearch: Constants.SafeSearch,
            ParameterKeys.Extras: Constants.Extras,
            ParameterKeys.Format: Constants.DataFormat,
            ParameterKeys.NoJSONCallback: Constants.NoJSONCallback
        ]
        
        taskForGETMethod(mutableMethod, parameters: parameters) { JSONResult, error in
            
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let results = JSONResult.valueForKey(FlickRClient.JSONResponseKeys.PhotoContainer) as? [String:AnyObject] {
                    
                    // First get random page and use that to get a random image from that specific page
                    if let totalPages = results[FlickRClient.JSONResponseKeys.Pages] as? Int {
                        // append random page to parameters
                        parameters[ParameterKeys.Page] = String(self.parseForRandom(totalPages, alreadyTaken: nil))
                        // do another round requesting the specific page
                        self.taskForGETMethod(mutableMethod, parameters: parameters) { JSONResult, error in
                            if let results = JSONResult.valueForKey(FlickRClient.JSONResponseKeys.PhotoContainer) as? [String:AnyObject] {
                                var totalPhotosVal = 0
                                if let totalPhotos = results[FlickRClient.JSONResponseKeys.Total] as? String {
                                    totalPhotosVal = (totalPhotos as NSString).integerValue
                                }
                                
                                if totalPhotosVal > 0 {
                                    var imageCollection = [[String]]()
                                    var alreadyTaken = [Int]()
                                    if let photos = results["photo"] as? [[String: AnyObject]] {
                                        for _ in 0 ..< ((photos.count > requiredPhotosCount) ?requiredPhotosCount:photos.count) {
                                            let currentIndex = self.parseForRandom(photos.count, alreadyTaken: alreadyTaken)
                                            alreadyTaken.append(currentIndex)
                                            var chosenPicture = photos[currentIndex] as [String: AnyObject]
                                            let name = chosenPicture[FlickRClient.JSONResponseKeys.Title] as! String
                                            let url = chosenPicture[FlickRClient.JSONResponseKeys.ImageUrl] as! String
                                            imageCollection.append([name, url])
                                        }
                                        completionHandler(result:imageCollection, error:nil)
                                    }
                                } else {
                                    // just return an empty result, to be handled by request
                                    completionHandler(result:[], error:nil)
                                }
                            }
                        }
                    }
                    
                } else {
                    completionHandler(result: nil, error: NSError(domain: "photoContainer parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse photos"]))
                }
            }
            
        }
    }
    
    // MARK: - All purpose task method for images --> adapted from Favorite actors
    
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string: filePath)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let _ = downloadError {
                let newError = FlickRClient.errorForData(data, response: response, error: downloadError!)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        task.resume()
        return task
    }

    
}