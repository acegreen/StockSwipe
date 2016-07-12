//
//  News.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public struct TradeIdea {
    
    let user: PFUser!
    let description: String!
    
    var likeCount: Int = 0 {
        didSet {
            self.parseObject.setObject(self.likeCount, forKey: "likeCount")
            self.parseObject.saveEventually()
        }
    }
    var reshareCount: Int = 0 {
        didSet {
            self.parseObject.setObject(self.reshareCount, forKey: "reshareCount")
            self.parseObject.saveEventually()
        }
    }
    
    let publishedDate: NSDate!
    let parseObject: PFObject!
}

extension TradeIdea: Equatable {}

public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
    let areEqual = lhs.user == rhs.user &&
        lhs.description == rhs.description &&
        lhs.likeCount == rhs.likeCount &&
        lhs.reshareCount == rhs.reshareCount &&
        lhs.parseObject == rhs.parseObject
    
    return areEqual
}