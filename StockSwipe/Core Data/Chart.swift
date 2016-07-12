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
    
    var symbol: String!
    var companyName: String!
    var image: UIImage! {
        didSet {
            if image == nil {
                image = UIImage(named: "no_chart")
            }
        }
    }
    
    var shortCount: Int = 0 {
        didSet {
            self.parseObject?.setObject(self.shortCount, forKey: "shortCount")
            self.parseObject?.saveEventually()
        }
    }
    var longCount: Int = 0 {
        didSet {
            self.parseObject?.setObject(self.longCount, forKey: "longCount")
            self.parseObject?.saveEventually()
        }
    }
    var parseObject: PFObject?
    
    var searchDescription: String {
        
        if self.shortCount > 0 || self.shortCount > 0 {
            
            return "\(companyName)\nLongs: \(longCount)\nShorts: \(shortCount)"
            
        } else {
            
            return "\(companyName)"
        }
    }
    
    init(symbol: String!, companyName: String!, image: UIImage!, shortCount: Int!, longCount: Int!, parseObject: PFObject?) {
        
        super.init()
        
        self.symbol = symbol
        self.companyName = companyName
        ({  self.image = image })()
        self.shortCount = shortCount ?? 0
        self.longCount = longCount ?? 0
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