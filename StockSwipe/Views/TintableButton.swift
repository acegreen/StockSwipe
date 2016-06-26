//
//  TintableButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/25/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class TintableButton: UIButton, Tintable {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override var selected: Bool {
        didSet {
            self.tint(selected)
        }
    }
}
