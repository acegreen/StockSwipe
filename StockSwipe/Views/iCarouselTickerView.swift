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
    let mainViewFontColor: UIColor = UIColor.white
    
    let priceViewFont = UIFont(name: "HelveticaNeue", size: 15)
    let priceViewFontColor: UIColor = UIColor.white
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        constructViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    func constructViews() -> Void {
        
        let nameViewFrame:CGRect = CGRect(x: 0, y: topPadding, width: self.bounds.width, height: viewHeight);
        self.nameLabel = UILabel(frame:nameViewFrame)
        self.nameLabel.backgroundColor = UIColor.clear
        self.nameLabel.textAlignment = .center
        self.nameLabel.font = mainViewFont
        self.nameLabel.text = "PlaceHolder"
        self.nameLabel.textColor = mainViewFontColor
        
        self.nameLabel.numberOfLines = 1
        self.nameLabel.adjustsFontSizeToFitWidth = true
        
        if !nameLabel.isDescendant(of: self) {
            
            self.addSubview(self.nameLabel)
        }
        
        let priceViewFrame:CGRect = CGRect(x: 0, y: self.nameLabel.frame.height + topPadding, width: self.bounds.width * 0.40, height: viewHeight);
        self.priceLabel = UILabel(frame:priceViewFrame)
        self.priceLabel.backgroundColor = UIColor.clear
        self.priceLabel.textAlignment = .center
        self.priceLabel.font = priceViewFont
        self.priceLabel.text = "0.0"
        self.priceLabel.textColor = priceViewFontColor
        
        self.priceLabel.numberOfLines = 1
        self.priceLabel.adjustsFontSizeToFitWidth = true
        
        if !priceLabel.isDescendant(of: self) {
            
            self.addSubview(self.priceLabel)
        }
        
        let priceChangeViewFrame:CGRect = CGRect(x: self.priceLabel.frame.width, y: self.nameLabel.frame.height + topPadding, width: self.bounds.width * 0.60, height: viewHeight);
        self.priceChangeLabel = UILabel(frame:priceChangeViewFrame)
        self.priceChangeLabel.backgroundColor = UIColor.clear
        self.priceChangeLabel.textAlignment = .center
        self.priceChangeLabel.font = priceViewFont
        self.priceChangeLabel.text = "+0.0 (0.0%)"
        self.priceChangeLabel.textColor = priceViewFontColor
        
        self.priceChangeLabel.numberOfLines = 1
        self.priceChangeLabel.adjustsFontSizeToFitWidth = true
        
        if !priceChangeLabel.isDescendant(of: self) {
            
            self.addSubview(self.priceChangeLabel)
        }
    }

}
