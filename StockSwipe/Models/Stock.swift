//
//  Stock.swift
//  StockSwipe
//
//  Created by Ace Green on 2/19/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import Parse

class Stock: PFObject, PFSubclassing {
    
    @NSManaged var Symbol: String!
    @NSManaged var Company: String?
    @NSManaged var Sector: String?
    @NSManaged var Exchange: String?
    
    static func parseClassName() -> String {
        return "Stocks"
    }
}
