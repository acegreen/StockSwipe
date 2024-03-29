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
                setImage(UIImage(named: "user_blocked"), for: UIControl.State())
            case .unblocked:
                backgroundColor = UIColor.white
                borderColor = Constants.SSColors.grey
                tintColor = Constants.SSColors.grey
                setImage(UIImage(named: "user_blocked"), for: UIControl.State())
            }
        }
    }
}
