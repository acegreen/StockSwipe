//
//  CorneredBorderedUIButton.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-10.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

class CorneredBorderedUIButton: UIButton {
    
    override func drawRect(rect: CGRect) {
        
        super.drawRect(rect)
        
        self.layer.cornerRadius = 9
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.clipsToBounds = true
    }

}
