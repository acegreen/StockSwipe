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
    let stock: PFObject!
    let description: String!
    
    var likeCount: Int?
    var reshareCount: Int?
    
    let publishedDate: NSDate!
    let parseObject: PFObject!
    
}

extension TradeIdea: Equatable {}

public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
    let areEqual = lhs.user == rhs.user &&
        lhs.stock == rhs.stock &&
        lhs.description == rhs.description &&
        lhs.likeCount == rhs.likeCount &&
        lhs.reshareCount == rhs.reshareCount &&
        lhs.parseObject == rhs.parseObject
    
    return areEqual
}