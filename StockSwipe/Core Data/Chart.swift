//
//  Chart.swift
//  StockSwipe
//
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import Parse

public class Chart: NSObject {
    
    let symbol: String!
    let companyName: String!
    var image: UIImage! {
        didSet {
            if image == nil {
                image = UIImage(named: "no_chart")
            }
        }
    }
    
    var shorts: Int?
    var longs: Int?
    let parseObject: PFObject?
    
    var searchDescription: String {
        
        if self.longs != nil && self.shorts != nil {
            
            return "\(companyName)\nLongs: \(longs)\nShorts: \(shorts)"
            
        } else {
            
            return "\(companyName)"
        }
    }
    
    init(symbol: String!, companyName: String!, image: UIImage!, shorts: Int?, longs: Int?, parseObject: PFObject?) {
        
        self.symbol = symbol ?? ""
        self.companyName = companyName!
        self.image = image
        self.shorts = shorts
        self.longs = longs
        self.parseObject = parseObject
    }
}

//extension Chart: Equatable {}
//
//public func ==(lhs: Chart, rhs: Chart) -> Bool {
//    let areEqual = lhs.symbol == rhs.symbol &&
//        lhs.companyName == rhs.companyName &&
//        lhs.image == rhs.image &&
//        lhs.shorts == rhs.shorts &&
//        lhs.longs == rhs.longs &&
//        lhs.parseObject == rhs.parseObject
//    
//    return areEqual
//}