//
//  AlbumCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Andreas Pfister on 14/10/15.
//  Copyright © 2015 iOS Development Blog. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    /*
    override func prepareForReuse() {
        super.prepareForReuse()
        if image.image == nil {
            loadIndicator.startAnimating()
        }
    }
*/
}