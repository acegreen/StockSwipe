//
//  Chart.swift
//  StockSwipe
//
//  Copyright (c) 2015 Ace Green. All rights reserved.
//


import UIKit
import CoreData

public class Chart: NSObject {
    
    let symbol: String!
    let companyName: String!
    var image: UIImage?
    var shorts: Int?
    var longs: Int?
    
    var searchDescription: String {
        
        if self.longs != nil && self.shorts != nil {
            
            return "\(companyName)\nLongs: \(longs)\nShorts: \(shorts)"
            
        } else {
            
            return "\(companyName)"
        }
    }
    
    init(symbol: String?, companyName: String?, image: UIImage?, shorts: Int?, longs: Int?) {
        
        self.symbol = symbol ?? ""
        self.companyName = companyName!
        self.image = image
        self.shorts = shorts
        self.longs = longs
    }
}