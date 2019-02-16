//
//  CardModel.swift
//  StockSwipe
//
//  Copyright (c) 2015 Ace Green. All rights reserved.
//


import UIKit
import CoreData

@objc (ChartModel)
class ChartModel: NSManagedObject {
    
    //properties feeding the attributes in "Charts" entity
    @NSManaged var symbol: String
    @NSManaged var companyName: String?
    @NSManaged var image: Data?
    @NSManaged var shorts: Int32
    @NSManaged var longs: Int32
    @NSManaged var userChoice: String
    @NSManaged var dateChoosen: Date
}

@objc (CardModel)
class CardModel: NSManagedObject {
    
    //properties feeding the attributes in "Card" entity
    @NSManaged var symbol: String
    @NSManaged var companyName: String?
    @NSManaged var exchange: String?
    @NSManaged var eodHistoricalData: Data?
    @NSManaged var eodFundamentalsData: Data?
    @NSManaged var shorts: Int32
    @NSManaged var longs: Int32
    @NSManaged var userChoice: String
    @NSManaged var dateChoosen: Date
}
