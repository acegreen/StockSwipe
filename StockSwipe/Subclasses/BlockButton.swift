//
//  BlockButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/27/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

@IBDesignable
class BlockButton: UIButton {
    
    enum state {
        case blocked
        case unblocked
        
        static let allStates = [blocked, unblocked]
    }
    
    var buttonState = state.unblocked {
        didSet {
            switch buttonState {
            case .blocked:
                backgroundColor = UIColor.red
                borderColor = UIColor.white
                tintColor = UIColor.white
                setImage(UIImage(named: "user_blocked"), for: UIControlState())
            case .unblocked:
                backgroundColor = UIColor.white
                borderColor = Constants.stockSwipeFontColor
                tintColor = Constants.stockSwipeFontColor
                setImage(UIImage(named: "user_blocked"), for: UIControlState())
            }
        }
    }
}
