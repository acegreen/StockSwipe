//
//  ChartCollectionViewCell.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-30.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import QuartzCore

class ChartCollectionViewCell: UICollectionViewCell {
    
    let overlayWidth:  CGFloat = 100.0
    let overlayHeight: CGFloat = 50.0
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var shortLabel: UILabel!
    @IBOutlet weak var longLabel: UILabel!
    @IBOutlet weak var overlayLabel: UILabel!
    
    func configure(withDataSource dataSource: ChartModel) {
        
        if dataSource.image != nil, let image = UIImage(data: dataSource.image!) {
            self.imageView.image = image
        }
        
        self.nameLabel.text = "\(dataSource.symbol)"
        self.longLabel.text = Int(dataSource.longs).suffixNumber()
        self.shortLabel.text = Int(dataSource.shorts).suffixNumber()
        
        if dataSource.userChoice == Constants.UserChoices.SHORT.key() {
            
            self.overlayLabel.layer.borderColor = UIColor.redColor().CGColor
            self.overlayLabel.text = "\(Constants.UserChoices.SHORT)"
            self.overlayLabel.textColor = UIColor.redColor()
            self.overlayLabel.transform = CGAffineTransformRotate(CGAffineTransformIdentity, CGFloat(Functions.degreesToRadians(15)))
            
        } else if dataSource.userChoice == Constants.UserChoices.LONG.key() {
            
            self.overlayLabel.layer.borderColor = Constants.stockSwipeGreenColor.CGColor
            self.overlayLabel.text = "\(Constants.UserChoices.LONG)"
            self.overlayLabel.textColor = Constants.stockSwipeGreenColor
            self.overlayLabel.transform = CGAffineTransformRotate(CGAffineTransformIdentity, CGFloat(Functions.degreesToRadians(-15)))
        }
        
        self.overlayLabel.layer.borderWidth = 3.0
        self.overlayLabel.layer.cornerRadius = 7.5
    }
    
    override var selected: Bool {
        didSet {
            if self.selected {
                
                // Set self border to show selection
                self.layer.cornerRadius = 7.5
                self.layer.borderWidth = 1.5
                self.layer.borderColor = Constants.stockSwipeFontColor.CGColor
                
            } else {
                
                // Remove bold cell border
                self.layer.cornerRadius = 7.5
                self.layer.borderWidth = 0.5
                self.layer.borderColor = Constants.stockSwipeFontColor.CGColor
                
            }
        }
    }

}
