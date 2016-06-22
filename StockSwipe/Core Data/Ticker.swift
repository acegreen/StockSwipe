//
//  Tickers.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

public struct Ticker {
    
    let symbol: String?
    let companyName:String?
    let exchange: String?
    let currentPrice: String?
    let changeInDollar: String?
    let changeInPercent: String?
}

extension Ticker: Equatable {}

public func ==(lhs: Ticker, rhs: Ticker) -> Bool {
    let areEqual = lhs.symbol == rhs.symbol &&
        lhs.companyName == rhs.companyName &&
        lhs.exchange == rhs.exchange &&
        lhs.currentPrice == rhs.currentPrice &&
        lhs.changeInDollar == rhs.changeInDollar &&
        lhs.changeInPercent == rhs.changeInPercent
    
    return areEqual
}