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
    
    var shortCount: Int = 0 {
        willSet {
            if newValue > shortCount {
                self.parseObject?.incrementKey("shortCount")
            } else if shortCount > 0 {
                self.parseObject?.incrementKey("shortCount", byAmount: -1)
            }
            self.parseObject?.saveEventually()
        }
    }
    var longCount: Int = 0 {
        willSet {
            if newValue > longCount {
                self.parseObject?.incrementKey("longCount")
            } else if longCount > 0 {
                self.parseObject?.incrementKey("longCount", byAmount: -1)
            }
            self.parseObject?.saveEventually()
        }
    }
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
        
        let symbol = parseObject.object(forKey: "Symbol") as! String
        let companyName = parseObject.object(forKey: "Company") as! String
        let shortCount = parseObject.object(forKey: "shortCount") as? Int
        let longCount = parseObject.object(forKey: "longCount") as? Int
        
        self.symbol = symbol
        self.companyName = companyName
        self.shortCount = shortCount ?? 0
        self.longCount = longCount ?? 0
        self.parseObject = parseObject
        
        // Index to Spotlight
        Functions.addToSpotlight(self, domainIdentifier: "com.stockswipe.stocksQueried")
    }
    
    init(symbol: String!, companyName: String?) {
        
        super.init()
        
        self.symbol = symbol
        self.companyName = companyName ?? "Company Name N/A"
        
        // Index to Spotlight
        Functions.addToSpotlight(self, domainIdentifier: "com.stockswipe.stocksQueried")
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
