//
//  TransparentView.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Foundation

@IBDesignable
class TransparentView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let hitView: UIView? = super.hitTest(point, with: event)
        
        if hitView == self {
            return nil
        }
        
        return hitView

    }
}
