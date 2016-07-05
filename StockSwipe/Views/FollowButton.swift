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
    
    var buttonState = state.Following {
        didSet {
            switch buttonState {
            case .NotFollowing:
                backgroundColor = UIColor.whiteColor()
                borderColor = Constants.stockSwipeGreenColor
                tintColor = Constants.stockSwipeGreenColor
                setImage(UIImage(named: "user_add"), forState: .Normal)
                self.setTitle("Follow", forState: .Normal)
                self.enabled = true
            case .Following:
                backgroundColor = Constants.stockSwipeGreenColor
                borderColor = Constants.stockSwipeGreenColor
                tintColor = UIColor.whiteColor()
                setImage(UIImage(named: "user_checked"), forState: .Normal)
                setTitle("Following", forState: .Normal)
                self.enabled = true
            case .Blocked:
                backgroundColor = UIColor.redColor()
                borderColor = UIColor.whiteColor()
                tintColor = UIColor.whiteColor()
                setImage(UIImage(named: "user_blocked"), forState: .Normal)
                setTitle("Blocked", forState: .Normal)
                self.enabled = true
            case .Disabled:
                backgroundColor = UIColor.whiteColor()
                borderColor = Constants.stockSwipeFontColor
                tintColor = Constants.stockSwipeFontColor
                setImage(UIImage(named: "user_add"), forState: .Normal)
                self.setTitle("Follow", forState: .Normal)
                self.enabled = false
            }
        }
    }
}
