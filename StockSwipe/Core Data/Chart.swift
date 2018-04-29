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
    var image: UIImage = UIImage(named: "no_chart")!
    
    fileprivate var chartImageURL: URL!
    
    var shortCount: Int = 0 
    var longCount: Int = 0
    
    var parseObject: PFObject?
    
    var searchDescription: String {
        
        if self.shortCount > 0 || self.shortCount > 0 {
            return companyName + "\n" + "Shorts: \(shortCount)" + "\n" + "Longs: \(longCount)"
        } else {
            return companyName
        }
    }
    
    init(parseObject: PFObject) {
        
        super.init()
    
        self.parseObject = parseObject
        
        let symbol = parseObject.object(forKey: "Symbol") as! String
        let companyName = parseObject.object(forKey: "Company") as! String
        
        self.symbol = symbol
        self.companyName = companyName
        
        // check for longs/shorts
        self.checkNumberOfShorts { (shorts) in
        }
        
        self.checkNumberOfLongs { (longs) in
        }
        
        // Index to Spotlight
        Functions.addToSpotlight(self, domainIdentifier: "com.stockswipe.stocksQueried")
    }
    
    init(symbol: String!, companyName: String?) {
        
        super.init()
        
        self.symbol = symbol
        self.companyName = companyName
        
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
    
    func getChartImage(completion: ((UIImage?) -> Void)?) {
        
        guard let chartImageURL = Functions.setImageURL(symbol) else { return }
        self.chartImageURL = chartImageURL
        Functions.getImage(chartImageURL, completion: { (image) in
            
            if let image = image {
                self.image = image
                print("chart image downloaded")
            }
            
            if let completion = completion {
                completion(image)
            }
        })
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
