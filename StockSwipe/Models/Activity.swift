//
//  Activity.swift
//  StockSwipe
//
//  Created by Ace Green on 2/19/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import Parse

class Activity: PFObject, PFSubclassing {
    
    @NSManaged var fromUser: User!
    @NSManaged var toUser: User?
    @NSManaged var activityType: String
    @NSManaged var tradeIdea: TradeIdea?
    @NSManaged var originalTradeIdea: TradeIdea?
    @NSManaged var stock: Stock?
    
    static func parseClassName() -> String {
        return String(describing: Activity.self)
    }
}
