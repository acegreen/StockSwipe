//
//  IdeaPostButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/27/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

@IBDesignable
class IdeaPostButton: UIButton {

    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = Constants.SSColors.greenDark
            } else {
                backgroundColor = UIColor.white
            }
        }
    }

}
