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

    override var selected: Bool {
        didSet {
            if selected {
                backgroundColor = Constants.stockSwipeGreenColor
            } else {
                backgroundColor = UIColor.whiteColor()
            }
        }
    }

}
