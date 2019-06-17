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
                borderColor = Constants.SSColors.greenDark
                tintColor = Constants.SSColors.greenDark
                setTitleColor(Constants.SSColors.greenDark, for: UIControl.State())
                setImage(UIImage(named: "user_add"), for: UIControl.State())
                setTitle("Follow", for: UIControl.State())
            case .following:
                isEnabled = true
                backgroundColor = Constants.SSColors.greenDark
                borderColor = Constants.SSColors.greenDark
                tintColor = UIColor.white
                setTitleColor(UIColor.white, for: UIControl.State())
                setImage(UIImage(named: "user_checked"), for: UIControl.State())
                setTitle("Following", for: UIControl.State())
            case .blocked:
                isEnabled = true
                backgroundColor = UIColor.red
                borderColor = UIColor.white
                tintColor = UIColor.white
                setTitleColor(UIColor.white, for: UIControl.State())
                setImage(UIImage(named: "user_blocked"), for: UIControl.State())
                setTitle("Blocked", for: UIControl.State())
            case .disabled:
                isEnabled = false
                backgroundColor = UIColor.white
                borderColor = Constants.SSColors.grey
                tintColor = UIColor.lightGray
                setTitleColor(UIColor.lightGray, for: .disabled)
                setImage(UIImage(named: "user_add"), for: .disabled)
                setTitle("Follow", for: UIControl.State())
            }
        }
    }
}
