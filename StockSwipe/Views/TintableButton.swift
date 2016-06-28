//
//  TintableButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/25/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class TintableButton: UIButton, Tintable {
    
    override var selected: Bool {
        didSet {
            self.tint(selected)
        }
    }
}
