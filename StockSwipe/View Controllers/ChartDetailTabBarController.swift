//
//  ChartDetailTabBarController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-02.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

protocol ChartDetailDelegate {
    var symbol: String! { get set }
    var companyName: String? { get set }
}

class ChartDetailTabBarController: UITabBarController {
    
    // Symbol should be passed as we segue here
    var chart: Chart!
    
    // Will be set below
    var symbol: String! {
        didSet {
            if symbol != symbol.uppercaseString {
                symbol = symbol.uppercaseString
            }
        }
    }
    
    var companyName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.symbol = chart.symbol
        self.companyName = chart.companyName
    }
}
