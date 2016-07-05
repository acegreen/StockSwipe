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
        case Following
        case NotFollowing
        case Blocked
        case Disabled
        
        static let allStates = [Following, NotFollowing, Blocked]
    }
    
    var buttonState = state.NotFollowing {
        didSet {
            switch buttonState {
            case .NotFollowing:
                enabled = true
                backgroundColor = UIColor.whiteColor()
                borderColor = Constants.stockSwipeGreenColor
                tintColor = Constants.stockSwipeGreenColor
                setTitleColor(Constants.stockSwipeGreenColor, forState: .Normal)
                setImage(UIImage(named: "user_add"), forState: .Normal)
                setTitle("Follow", forState: .Normal)
            case .Following:
                enabled = true
                backgroundColor = Constants.stockSwipeGreenColor
                borderColor = Constants.stockSwipeGreenColor
                tintColor = UIColor.whiteColor()
                setTitleColor(UIColor.whiteColor(), forState: .Normal)
                setImage(UIImage(named: "user_checked"), forState: .Normal)
                setTitle("Following", forState: .Normal)
            case .Blocked:
                enabled = true
                backgroundColor = UIColor.redColor()
                borderColor = UIColor.whiteColor()
                tintColor = UIColor.whiteColor()
                setTitleColor(UIColor.whiteColor(), forState: .Normal)
                setImage(UIImage(named: "user_blocked"), forState: .Normal)
                setTitle("Blocked", forState: .Normal)
            case .Disabled:
                enabled = false
                backgroundColor = UIColor.whiteColor()
                borderColor = Constants.stockSwipeFontColor
                tintColor = UIColor.lightGrayColor()
                setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
                setImage(UIImage(named: "user_add"), forState: .Disabled)
                setTitle("Follow", forState: .Normal)
            }
        }
    }
}
