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
        case Blocked
        case Unblocked
        
        static let allStates = [Blocked, Unblocked]
    }
    
    var buttonState = state.Unblocked {
        didSet {
            switch buttonState {
            case .Blocked:
                backgroundColor = UIColor.redColor()
                borderColor = UIColor.whiteColor()
                tintColor = UIColor.whiteColor()
                setImage(UIImage(named: "user_blocked"), forState: .Normal)
            case .Unblocked:
                backgroundColor = UIColor.whiteColor()
                borderColor = Constants.stockSwipeFontColor
                tintColor = Constants.stockSwipeFontColor
                setImage(UIImage(named: "user_blocked"), forState: .Normal)
            }
        }
    }
}
