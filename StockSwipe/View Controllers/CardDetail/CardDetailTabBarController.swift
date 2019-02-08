//
//  CardDetailTabBarController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-02.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

protocol ChartDetailDelegate {
    var symbol: String! { get }
    var companyName: String! { get }
}

class CardDetailTabBarController: UITabBarController {
    
    // Symbol should be passed as we segue here
    var chart: Chart! {
        didSet {
            self.symbol = chart.symbol
            self.companyName = chart.companyName
        }
    }
    
    // Will be set below
    fileprivate(set) var symbol: String! {
        didSet {
            if symbol != symbol.uppercased() {
                symbol = symbol.uppercased()
            }
        }
    }
    
    fileprivate(set) var companyName: String!
}