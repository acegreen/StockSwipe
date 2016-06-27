//
//  QueryHelper.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-12-23.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import SwiftyJSON

public class QueryHelper {
    
    static let sharedInstance = QueryHelper()
    
    public func queryWith(queryString: String, completionHandler: (result: () throws -> NSData) -> Void) -> Void {
        
        if let companyQuoteUrl: NSURL = NSURL(string: queryString) {
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(companyQuoteUrl, completionHandler: { (queryData, response, error) -> Void in
                
                guard error == nil else {
                    return completionHandler(result: {throw Constants.Errors.ErrorQueryingForData})
                }
                
                guard queryData != nil, let queryData = queryData else {
                    return completionHandler(result: {throw Constants.Errors.QueryDataEmpty})
                }
                
                return completionHandler(result: { queryData })
                
            })
            task.resume()
        }
    }
    
    public func queryStockTwitsTrendingStocks(completionHandler: (trendingStocksData: () throws -> NSData) -> Void) -> Void {
        
        if let trendingStocksUrl = NSURL(string: "https://api.stocktwits.com/api/2/trending/symbols/equities.json") {
            
            let trendingStocksSession = NSURLSession.sharedSession()
            
            let task = trendingStocksSession.dataTaskWithURL(trendingStocksUrl, completionHandler: { (trendingStocksData, response, error) -> Void in
                
                guard error == nil else { return completionHandler(trendingStocksData: { throw Constants.Errors.ErrorQueryingForData })}
                guard trendingStocksData != nil else { return completionHandler(trendingStocksData: { throw Constants.Errors.QueryDataEmpty })}
                
                return completionHandler(trendingStocksData: { trendingStocksData! })
            })
            task.resume()
        }
    }
    
    public func queryYahooSymbolQuote(tickers: [String], completionHandler:(symbolQuote: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        
        let stringICarouselTickers = "(\(tickers))"
        
        // Company quote query
        let queryStringPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let queryStringPart2 = "select * from yahoo.finance.quotes "
        let queryStringPart3 = "where symbol in "
        
        let queryStringPart4:String = {
            
            var queryStringPart4: String!
            queryStringPart4 = stringICarouselTickers.replace("[", withString: "")
            queryStringPart4 = queryStringPart4.replace("]", withString: "")
            
            return queryStringPart4
        }()
        
        let queryStringPart5 = "&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
        
        guard let marketQueryString:String = (queryStringPart1 + queryStringPart2 + queryStringPart3 + queryStringPart4).URLEncodedString()! + queryStringPart5 else { return }
        
        if let marketCarouselUrl: NSURL = NSURL(string: marketQueryString) {
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(marketCarouselUrl, completionHandler: { (marketData, response, error) -> Void in
                
                completionHandler(symbolQuote: marketData, response: response, error: error)
            })
            task.resume()
        }
    }
    
    public func queryYahooCompanyProfile(symbol: String, completionHandler:(queryData: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        
        let companyProfileurl1 = "http://finance.yahoo.com/q/pr?s=\(symbol)"
        let companyProfileurl2 = "\"\(companyProfileurl1)\""
        let profileQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let profileQueryPart2 = "select * from html where url=\(companyProfileurl2) and xpath='//table[@class=\"yfnc_datamodoutline1\"]'&format=json"
        
        guard let companyProfileQueryString = (profileQueryPart1 + profileQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: NSURL = NSURL(string: companyProfileQueryString) {
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(companyQuoteUrl, completionHandler: { (quoteData, response, error) -> Void in
                
                completionHandler(queryData: quoteData, response: response, error: error)
                
            })
            task.resume()
        }
    }
    
    public func queryYahooCompanySummary(symbol: String, completionHandler:(queryData: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        
        let companySummaryurl1 = "http://finance.yahoo.com/q/pr?s=\(symbol)"
        let companySummaryurl2 = "\"\(companySummaryurl1)\""
        let summaryQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let summaryQueryPart2 = "select * from html where url=\(companySummaryurl2) and xpath='//p[not(node()[2])]'&format=json"
        
        guard let companySummaryQueryString = (summaryQueryPart1 + summaryQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: NSURL = NSURL(string: companySummaryQueryString) {
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(companyQuoteUrl, completionHandler: { (quoteData, response, error) -> Void in
                
                completionHandler(queryData: quoteData, response: response, error: error)
                
            })
            task.resume()
        }
    }
    
    public func queryYahooCompanyAnalystRating(symbol: String, completionHandler:(queryData: NSData?, response: NSURLResponse?, error: NSError?) -> Void) {
        
        let companyAnalystRatingStringPart1 = "https://ca.finance.yahoo.com/q/ao?s=\(symbol)"
        let companyAnalystRatingStringPart2 = "\"\(companyAnalystRatingStringPart1)\""
        let companyAnalystRatingQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let companyAnalystRatingQueryPart2 = "select * from html where url=\(companyAnalystRatingStringPart2) and xpath='//table[@class=\"yfnc_datamodoutline1 equaltable\"]|//table[@class=\"yfnc_datamodoutline1\"]'&format=json"
        
        guard let companyAnalystQueryString = (companyAnalystRatingQueryPart1 + companyAnalystRatingQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: NSURL = NSURL(string: companyAnalystQueryString) {
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithURL(companyQuoteUrl, completionHandler: { (quoteData, response, error) -> Void in
                
                completionHandler(queryData: quoteData, response: response, error: error)
                
            })
            task.resume()
        }
    }
    
    public func queryChartImage(symbol: String, completion: (result: () throws -> (UIImage)) -> Void) {
        
        guard let chartImageURL: NSURL = Functions.setImageURL(symbol) else {
            
            print("image URL is nil")
            return completion(result: {throw Constants.Errors.URLEmpty})
        }
        
        let chartImageSession = NSURLSession.sharedSession()
        let task = chartImageSession.dataTaskWithURL(chartImageURL, completionHandler: { (chartImagedata, response, error) -> Void in
            
            guard error == nil else {
                return completion(result: {throw Constants.Errors.ErrorAccessingServer})
            }
            guard chartImagedata != nil else {
                return completion(result: {throw Constants.Errors.QueryDataEmpty})
            }
            
            guard let chartImage = UIImage(data: chartImagedata!) else {
                return completion(result: {throw Constants.Errors.ChartImageCorrupt})
            }
            
            completion(result: {return (chartImage)})
            
        })
        
        task.resume()
    }
    
    public func queryUserObjectFor(username: String, completion: (result: () throws -> (PFUser)) -> Void) {
        
        guard Functions.isConnectedToNetwork() else {
            return completion(result: {throw Constants.Errors.NoInternetConnection})
        }
        
        let userQuery = PFUser.query()
        userQuery?.whereKey("username", equalTo: username)
        
        userQuery?.findObjectsInBackgroundWithBlock { (object, error) -> Void in
            
            guard error == nil else {
                return completion(result: {throw Constants.Errors.ErrorAccessingParseDatabase})
            }
            
            guard object?.isEmpty == false, let object = object?.first as? PFUser else {
                return completion(result: {throw Constants.Errors.ParseUserObjectNotFound})
            }
            
            completion(result: {return (objects: object)})
            
        }
    }
    
    public func queryStockObjectsFor(symbols: [String], completion: (result: () throws -> ([PFObject])) -> Void) {
        
        guard Functions.isConnectedToNetwork() else {
            return completion(result: {throw Constants.Errors.NoInternetConnection})
        }
        
        let mappedSymbols = symbols.map ({ $0.uppercaseString })
        
        let stockQuery = PFQuery(className:"Stocks")
        stockQuery.cancel()
        stockQuery.includeKeys(["Shorted_By", "Longed_By"])
        stockQuery.whereKey("Symbol", containedIn: mappedSymbols)
        
        stockQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            guard error == nil else {
                return completion(result: {throw Constants.Errors.ErrorAccessingParseDatabase})
            }
            
            guard objects?.isEmpty == false, let objects = objects else {
                return completion(result: {throw Constants.Errors.ParseStockObjectNotFound})
            }
            
            completion(result: {return (objects: objects)})
            
        }
    }
    
    public func queryTradeIdeaObjectsFor(key: String, object: PFObject, skip: Int, limit: Int?, completion: (result: () throws -> ([PFObject])) -> Void) {
        
        guard Functions.isConnectedToNetwork() else {
            return completion(result: {throw Constants.Errors.NoInternetConnection})
        }
        
        let tradeIdeaQuery = PFQuery(className:"TradeIdea")
        tradeIdeaQuery.cancel()
        tradeIdeaQuery.whereKey(key, equalTo: object)
        tradeIdeaQuery.includeKeys(["user","stock", "reply_to", "reshare_of"])
        tradeIdeaQuery.orderByDescending("createdAt")
        
        if let limit = limit  where limit > 0 {
            tradeIdeaQuery.limit = limit
        }
        tradeIdeaQuery.skip  = skip
        
        tradeIdeaQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            
            guard error == nil else {
                return completion(result: {throw Constants.Errors.ErrorAccessingParseDatabase})
            }
            
            guard objects?.isEmpty == false, let objects = objects else {
                return completion(result: {throw Constants.Errors.ParseTradeIdeaObjectNotFound})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion(result: {return (objects: objects)})
            
        }
    }
}