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
            case .Following:
                backgroundColor = Constants.stockSwipeGreenColor
                borderColor = Constants.stockSwipeGreenColor
                tintColor = UIColor.whiteColor()
                setImage(UIImage(named: "user_checked"), forState: .Normal)
                setTitle("Following", forState: .Normal)
            case .Blocked:
                backgroundColor = UIColor.redColor()
                borderColor = UIColor.whiteColor()
                tintColor = UIColor.whiteColor()
                setImage(UIImage(named: "user_blocked"), forState: .Normal)
                setTitle("Blocked", forState: .Normal)
            }
        }
    }
}
