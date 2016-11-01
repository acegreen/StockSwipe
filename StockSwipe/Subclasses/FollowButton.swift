//
//  FollowButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/27/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

@IBDesignable
class FollowButton: UIButton {
    
    enum state {
        case following
        case notFollowing
        case blocked
        case disabled
        
        static let allStates = [following, notFollowing, blocked]
    }
    
    var buttonState = state.notFollowing {
        didSet {
            switch buttonState {
            case .notFollowing:
                isEnabled = true
                backgroundColor = UIColor.white
                borderColor = Constants.stockSwipeGreenColor
                tintColor = Constants.stockSwipeGreenColor
                setTitleColor(Constants.stockSwipeGreenColor, for: UIControlState())
                setImage(UIImage(named: "user_add"), for: UIControlState())
                setTitle("Follow", for: UIControlState())
            case .following:
                isEnabled = true
                backgroundColor = Constants.stockSwipeGreenColor
                borderColor = Constants.stockSwipeGreenColor
                tintColor = UIColor.white
                setTitleColor(UIColor.white, for: UIControlState())
                setImage(UIImage(named: "user_checked"), for: UIControlState())
                setTitle("Following", for: UIControlState())
            case .blocked:
                isEnabled = true
                backgroundColor = UIColor.red
                borderColor = UIColor.white
                tintColor = UIColor.white
                setTitleColor(UIColor.white, for: UIControlState())
                setImage(UIImage(named: "user_blocked"), for: UIControlState())
                setTitle("Blocked", for: UIControlState())
            case .disabled:
                isEnabled = false
                backgroundColor = UIColor.white
                borderColor = Constants.stockSwipeFontColor
                tintColor = UIColor.lightGray
                setTitleColor(UIColor.lightGray, for: .disabled)
                setImage(UIImage(named: "user_add"), for: .disabled)
                setTitle("Follow", for: UIControlState())
            }
        }
    }
}
