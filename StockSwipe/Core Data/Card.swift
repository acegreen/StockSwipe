//
//  Card.swift
//  StockSwipe
//
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import Parse

public class Card: NSObject {
    
    var symbol: String!
    var companyName: String?
    var exchange: String?
    
    var shortCount: Int = 0 
    var longCount: Int = 0
    
    var eodHistoricalData: [QueryHelper.EODHistoricalResult]?
    var eodFundamentalsData: QueryHelper.EODFundamentalsResult?
    
    var userChoice: Constants.UserChoices?
    
    var parseObject: PFObject?
    
//    var searchDescription: String {
//        if self.shortCount > 0 || self.shortCount > 0 {
//            return companyName + "\n" + "Shorts: \(shortCount)" + "\n" + "Longs: \(longCount)"
//        } else {
//            return companyName
//        }
//    }
    
    init(parseObject: PFObject, eodHistoricalData: [QueryHelper.EODHistoricalResult]?, eodFundamentalsData: QueryHelper.EODFundamentalsResult?, userChoice: Constants.UserChoices? = nil) {
        
        super.init()
    
        self.parseObject = parseObject
        self.eodHistoricalData = eodHistoricalData
        self.eodFundamentalsData = eodFundamentalsData
        
        self.symbol = parseObject.object(forKey: "Symbol") as? String
        self.companyName = parseObject.object(forKey: "Company") as? String
        self.exchange = parseObject.object(forKey: "Exchange") as? String
        
        self.userChoice = userChoice
        
        // Index to Spotlight
        Functions.addToSpotlight(self, domainIdentifier: "com.stockswipe.stocksQueried")
    }
    
    func checkNumberOfShorts(completion: ((Int) -> Void)?) {
        
        guard let parseObject = self.parseObject else { return }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: [parseObject], activityType: [Constants.ActivityType.StockShort.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.shortCount = activityObjects.count
                
            } catch {
                //TODO: handle error
            }
            
            if let completion = completion {
                completion(self.shortCount)
            }
        })
    }
    
    func checkNumberOfLongs(completion: ((Int) -> Void)?) {
        
        guard let parseObject = self.parseObject else { return }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: [parseObject], activityType: [Constants.ActivityType.StockLong.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.longCount = activityObjects.count
                
            } catch {
                //TODO: handle error
            }
            
            if let completion = completion {
                completion(self.longCount)
            }
        })
    }
}

//extension Card: Equatable {}
//
//public func ==(lhs: Card, rhs: Card) -> Bool {
//    let areEqual = lhs.symbol == rhs.symbol &&
//        lhs.companyName == rhs.companyName &&
//        lhs.image == rhs.image &&
//        lhs.shorts == rhs.shorts &&
//        lhs.longs == rhs.longs &&
//        lhs.parseObject == rhs.parseObject
//    
//    return areEqual
//}
