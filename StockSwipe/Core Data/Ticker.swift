//
//  Tickers.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import SwiftyJSON

public struct Ticker {
    
    let symbol: String?
    let companyName:String?
    let exchange: String?
    var currentPrice: Double = 0.0
    var changeInDollar: Double = 0.0
    var changeInPercent: Double = 0.0
    
    var priceFormatted: String {
        return "\(currentPrice.roundTo(places: 2))"
    }
    
    var changeFormatted: String {
        return "\(changeInDollar.roundTo(places: 2)) " + "(\(changeInPercent.roundTo(places: 2))%)"
    }
}

extension Ticker {
    
    static func makeTickers(from symbolQuote: Data) -> [Ticker] {
        
        var tickers = [Ticker]()
        
        let carsouelJson = JSON(data: symbolQuote)
        let carsouelJsonResults = carsouelJson["query"]["results"]
        guard let quoteJsonResultsQuote = carsouelJsonResults["quote"].array else { return tickers }
        
        for quote in quoteJsonResultsQuote {
            
            let symbol = quote["Symbol"].string
            let companyName = quote["Name"].string
            let exchange = quote["StockExchange"].string
            let currentPrice = quote["LastTradePriceOnly"].doubleValue
            let changeInDollar = quote["Change"].doubleValue
            let changeInPercent = quote["ChangeinPercent"].doubleValue
            
            let ticker = Ticker(symbol: symbol, companyName: companyName, exchange: exchange, currentPrice: currentPrice, changeInDollar: changeInDollar, changeInPercent: changeInPercent)
            
            tickers.append(ticker)
        }
        
        return tickers
    }
}

extension Ticker: Equatable { }

public func ==(lhs: Ticker, rhs: Ticker) -> Bool {
    let areEqual = lhs.symbol == rhs.symbol &&
        lhs.companyName == rhs.companyName &&
        lhs.exchange == rhs.exchange &&
        lhs.currentPrice == rhs.currentPrice &&
        lhs.changeInDollar == rhs.changeInDollar &&
        lhs.changeInPercent == rhs.changeInPercent
    
    return areEqual
}
