//
//  IdeaPostButton.swift
//  StockSwipe
//
//  Created by Ace Green on 6/27/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class IdeaPostButton: CorneredBorderedUIButton {

    override var enabled: Bool {
        didSet {
            if enabled {
                backgroundColor = Constants.stockSwipeGreenColor
            } else {
                backgroundColor = UIColor.whiteColor()
            }
        }
    }

}
