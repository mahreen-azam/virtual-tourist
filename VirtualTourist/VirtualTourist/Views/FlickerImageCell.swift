//
//  FlickerImageCell.swift
//  VirtualTourist
//
//  Created by Mahreen Azam on 10/2/19.
//  Copyright © 2019 Mahreen Azam. All rights reserved.
//

import UIKit

public class FlickerImageCell: UICollectionViewCell {
    @IBOutlet var ImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setSelected(isSelected: Bool) {
        ImageView.alpha = isSelected ? 0.3 : 1.0
    }
    
    func setActivityIndicator(isStopped: Bool) {
        if isStopped == true {
            activityIndicator.stopAnimating()
        } else {
            activityIndicator.startAnimating()
        }
    }
}
