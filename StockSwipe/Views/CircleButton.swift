//
//  CorneredBorderedUIButton.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-10.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

class CircleButton: UIButton {
    
    override func drawRect(rect: CGRect) {
        
        super.drawRect(rect)
        
        self.layer.cornerRadius = self.frame.size.height / 2.0
        self.clipsToBounds = true

    }

}
