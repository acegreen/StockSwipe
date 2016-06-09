//
//  TransparentView.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

class TransparentView: UIView {
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        
        let hitView: UIView? = super.hitTest(point, withEvent: event)
        
        if hitView == self {
            return nil
        }
        
        return hitView

    }
}
