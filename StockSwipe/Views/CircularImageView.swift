//
//  CircularImageView.swift
//  StockSwipe
//
//  Created by Ace Green on 4/3/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class CircularImageView: UIImageView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.layer.borderWidth = 3.0
        self.layer.borderColor = Constants.stockSwipeFontColor.CGColor
        self.clipsToBounds = true;
    }
}
