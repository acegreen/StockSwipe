//
//  iCarouselTickerView.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

class iCarouselTickerView: UIView {
    
    var ticker: Ticker!
    var nameLabel: UILabel!
    var priceLabel: UILabel!
    var priceChangeLabel: UILabel!
    
    let viewHeight:CGFloat = 20
    let rightPadding:CGFloat = 20.0
    let leftPadding:CGFloat = 10.0
    let topPadding:CGFloat = 10.0
    
    let mainViewFont = UIFont(name: "HelveticaNeue", size: 18)
    let mainViewFontColor: UIColor = UIColor.whiteColor()
    
    let priceViewFont = UIFont(name: "HelveticaNeue", size: 15)
    let priceViewFontColor: UIColor = UIColor.whiteColor()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        constructViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    func constructViews() -> Void {
        
        let nameViewFrame:CGRect = CGRectMake(0, topPadding, CGRectGetWidth(self.bounds), viewHeight);
        self.nameLabel = UILabel(frame:nameViewFrame)
        self.nameLabel.backgroundColor = UIColor.clearColor()
        self.nameLabel.textAlignment = .Center
        self.nameLabel.font = mainViewFont
        self.nameLabel.text = "PlaceHolder"
        self.nameLabel.textColor = mainViewFontColor
        
        self.nameLabel.numberOfLines = 1
        self.nameLabel.adjustsFontSizeToFitWidth = true
        
        if !nameLabel.isDescendantOfView(self) {
            
            self.addSubview(self.nameLabel)
        }
        
        let priceViewFrame:CGRect = CGRectMake(0, self.nameLabel.frame.height + topPadding, CGRectGetWidth(self.bounds) * 0.40, viewHeight);
        self.priceLabel = UILabel(frame:priceViewFrame)
        self.priceLabel.backgroundColor = UIColor.clearColor()
        self.priceLabel.textAlignment = .Center
        self.priceLabel.font = priceViewFont
        self.priceLabel.text = "0.0"
        self.priceLabel.textColor = priceViewFontColor
        
        self.priceLabel.numberOfLines = 1
        self.priceLabel.adjustsFontSizeToFitWidth = true
        
        if !priceLabel.isDescendantOfView(self) {
            
            self.addSubview(self.priceLabel)
        }
        
        let priceChangeViewFrame:CGRect = CGRectMake(self.priceLabel.frame.width, self.nameLabel.frame.height + topPadding, CGRectGetWidth(self.bounds) * 0.60, viewHeight);
        self.priceChangeLabel = UILabel(frame:priceChangeViewFrame)
        self.priceChangeLabel.backgroundColor = UIColor.clearColor()
        self.priceChangeLabel.textAlignment = .Center
        self.priceChangeLabel.font = priceViewFont
        self.priceChangeLabel.text = "+0.0 (0.0%)"
        self.priceChangeLabel.textColor = priceViewFontColor
        
        self.priceChangeLabel.numberOfLines = 1
        self.priceChangeLabel.adjustsFontSizeToFitWidth = true
        
        if !priceChangeLabel.isDescendantOfView(self) {
            
            self.addSubview(self.priceChangeLabel)
        }
    }

}
