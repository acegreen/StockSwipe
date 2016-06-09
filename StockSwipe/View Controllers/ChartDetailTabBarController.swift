//
//  ChartDetailTabBarController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-02.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

//protocol chartDetailDelegate {
//    var symbol: String! { get set }
//    var companyName: String! { get set }
//}

class ChartDetailTabBarController: UITabBarController {
    
    // symbol should be passed as we segue to here
    var symbol: String!
    var companyName: String?
}
