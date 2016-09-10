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
    
    private var chartImageURL: NSURL!
    
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
    
    init(parseObject: PFObject) {
        
        super.init()
        
        let symbol = parseObject.objectForKey("Symbol") as! String
        let companyName = parseObject.objectForKey("Company") as! String
        let shortCount = parseObject.objectForKey("shortCount") as? Int
        let longCount = parseObject.objectForKey("longCount") as? Int
        
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
    
    func getChartImage(completion completion: ((UIImage?) -> Void)?) {
        
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