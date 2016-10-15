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

class QueryHelper {
    
    enum QueryOrder {
        case ascending
        case descending
    }
    
    enum QueryType {
        case new
        case older
        case update
    }
    
    static let sharedInstance = QueryHelper()
    static let tradeIdeaQueryLimit = 25

    func queryWith(queryString: String, useCacheIfPossible: Bool = false, completionHandler: @escaping (_ result: () throws -> Data) -> Void) -> Void {
        
        if let queryUrl: URL = URL(string: queryString) {
            
            var session: URLSession!
            if useCacheIfPossible {
                let config = URLSessionConfiguration.default
                config.urlCache = URLCache.shared
                config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
                session = URLSession(configuration: config)
            } else {
                session = URLSession.shared
            }
            
            let task = session.dataTask(with: queryUrl, completionHandler: { (queryData, response, error) -> Void in
                
                guard error == nil else { return completionHandler({throw Constants.Errors.errorQueryingForData}) }
                
                guard queryData != nil, let queryData = queryData else {
                    return completionHandler({throw Constants.Errors.queryDataEmpty})
                }
                
                return completionHandler({ queryData })
            })
            task.resume()
        }
    }
    
    func queryStockTwitsTrendingStocks(completionHandler: @escaping (_ trendingStocksData: () throws -> Data) -> Void) -> Void {
        
        if let trendingStocksUrl = URL(string: "https://api.stocktwits.com/api/2/trending/symbols/equities.json") {
            
            let trendingStocksSession = URLSession.shared
            
            let task = trendingStocksSession.dataTask(with: trendingStocksUrl, completionHandler: { (trendingStocksData, response, error) -> Void in
                
                guard error == nil else { return completionHandler({ throw Constants.Errors.errorQueryingForData }) }
                
                guard trendingStocksData != nil, let trendingStocksData = trendingStocksData else {
                    return completionHandler({ throw Constants.Errors.queryDataEmpty })
                }
                
                return completionHandler({ trendingStocksData })
            })
            task.resume()
        }
    }
    
    func queryYahooSymbolQuote(tickers: [String], completionHandler:@escaping (_ symbolQuote: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
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
        
        if let marketCarouselUrl: URL = URL(string: marketQueryString) {
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: marketCarouselUrl, completionHandler: { (marketData, response, error) in
                completionHandler(marketData, response, error)
            })
            task.resume()
        }
    }
    
    func queryYahooCompanyProfile(symbol: String, completionHandler:@escaping (_ queryData: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        let companyProfileurl1 = "http://finance.yahoo.com/q/pr?s=\(symbol)"
        let companyProfileurl2 = "\"\(companyProfileurl1)\""
        let profileQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let profileQueryPart2 = "select * from html where url=\(companyProfileurl2) and xpath='//table[@class=\"yfnc_datamodoutline1\"]'&format=json"
        
        guard let companyProfileQueryString = (profileQueryPart1 + profileQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: URL = URL(string: companyProfileQueryString) {
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: companyQuoteUrl, completionHandler: { (quoteData, response, error) in
                
                completionHandler(quoteData, response, error)
                
            })
            task.resume()
        }
    }
    
    func queryYahooCompanySummary(symbol: String, completionHandler:@escaping (_ queryData: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        let companySummaryurl1 = "http://finance.yahoo.com/q/pr?s=\(symbol)"
        let companySummaryurl2 = "\"\(companySummaryurl1)\""
        let summaryQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let summaryQueryPart2 = "select * from html where url=\(companySummaryurl2) and xpath='//p[not(node()[2])]'&format=json"
        
        guard let companySummaryQueryString = (summaryQueryPart1 + summaryQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: URL = URL(string: companySummaryQueryString) {
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: companyQuoteUrl, completionHandler: { (quoteData, response, error) in
                
                completionHandler(quoteData, response, error)
                
            })
            task.resume()
        }
    }
    
    func queryYahooCompanyAnalystRating(symbol: String, completionHandler:@escaping (_ queryData: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        let companyAnalystRatingStringPart1 = "https://ca.finance.yahoo.com/q/ao?s=\(symbol)"
        let companyAnalystRatingStringPart2 = "\"\(companyAnalystRatingStringPart1)\""
        let companyAnalystRatingQueryPart1 = "https://query.yahooapis.com/v1/public/yql?q="
        let companyAnalystRatingQueryPart2 = "select * from html where url=\(companyAnalystRatingStringPart2) and xpath='//table[@class=\"yfnc_datamodoutline1 equaltable\"]|//table[@class=\"yfnc_datamodoutline1\"]'&format=json"
        
        guard let companyAnalystQueryString = (companyAnalystRatingQueryPart1 + companyAnalystRatingQueryPart2).URLEncodedString() else { return }
        
        if let companyQuoteUrl: URL = URL(string: companyAnalystQueryString) {
            
            let session = URLSession.shared
            
            let task = session.dataTask(with: companyQuoteUrl, completionHandler: { (quoteData, response, error) in
                
                completionHandler(quoteData, response, error)
                
            })
            task.resume()
        }
    }
    
    func queryChartImage(symbol: String, completion: @escaping (_ result: () throws -> (UIImage)) -> Void) {
        
        guard let chartImageURL: URL = Functions.setImageURL(symbol) else {
            
            print("image URL is nil")
            return completion({throw Constants.Errors.urlEmpty})
        }
        
        let chartImageSession = URLSession.shared
        let task = chartImageSession.dataTask(with: chartImageURL, completionHandler: { (chartImagedata, response, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingServer})
            }
            guard chartImagedata != nil else {
                return completion({throw Constants.Errors.queryDataEmpty})
            }
            
            guard let chartImage = UIImage(data: chartImagedata!) else {
                return completion({throw Constants.Errors.chartImageCorrupt})
            }
            
            completion({return (chartImage)})
            
        })
        
        task.resume()
    }
    
    func queryUserObjectsFor(usernames: [String], cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFUser])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let usernamesLowercase = usernames.map { ($0.lowercased()) }
        
        let userQuery = PFUser.query()
        userQuery?.cachePolicy = cachePolicy
        
        userQuery?.whereKey("username_lowercase", containedIn: usernamesLowercase)
        
        userQuery?.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard objects?.isEmpty == false, let objects = objects as? [PFUser] else {
                return completion({throw Constants.Errors.parseUserObjectNotFound})
            }
            
            completion({return (objects: objects)})
            
        }
    }
    
    func queryStockObjectsFor(symbols: [String], cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let mappedSymbols = symbols.map ({ $0.uppercased() })
        
        let stockQuery = PFQuery(className:"Stocks")
        stockQuery.cachePolicy = cachePolicy
        
        stockQuery.whereKey("Symbol", containedIn: mappedSymbols)
        
        stockQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard objects?.isEmpty == false, let objects = objects else {
                return completion({throw Constants.Errors.parseStockObjectNotFound})
            }
            
            completion({return (objects: objects)})
            
        }
    }
    
    func queryTradeIdeaObjectsFor(key: String?, object: PFObject?, skip: Int?, limit: Int?, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let tradeIdeaQuery = PFQuery(className:"TradeIdea")
        tradeIdeaQuery.cachePolicy = cachePolicy
    
        switch order {
        case .ascending:
            tradeIdeaQuery.order(byAscending: "createdAt")
        case .descending:
            tradeIdeaQuery.order(byDescending: "createdAt")
        }
        
        if let creationDate = creationDate {
            tradeIdeaQuery.whereKey("createdAt", greaterThan: creationDate)
        }
        
        tradeIdeaQuery.includeKeys(["user", "reshare_of"])
        
        if let key = key, let object = object {
            tradeIdeaQuery.whereKey(key, equalTo: object)
        }
        
        if key != "user", let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            tradeIdeaQuery.whereKey("user", notContainedIn: blockedUsers)
        }
        
        if key != "user", let currentUser = PFUser.current() {
            
            let subTradeIdeaQuery = PFUser.query()
            subTradeIdeaQuery?.whereKey("blocked_users", notEqualTo: currentUser)
            
            tradeIdeaQuery.whereKey("user", matchesQuery: subTradeIdeaQuery!)
        }
        
        if let skip = skip, skip > 0 {
            tradeIdeaQuery.skip = skip
        }
        
        if let limit = limit, limit > 0 {
            tradeIdeaQuery.limit = limit
        }
        
        tradeIdeaQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard let objects = objects else {
                return completion({throw Constants.Errors.parseTradeIdeaObjectNotFound})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects: objects)})
        }
    }
    
    func countTradeIdeasFor(key: String, object: PFObject, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> (Int)) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let tradeIdeaQuery = PFQuery(className:"TradeIdea")
        tradeIdeaQuery.cachePolicy = cachePolicy
        
        tradeIdeaQuery.whereKey(key, equalTo: object)
        
        if key != "user", let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            tradeIdeaQuery.whereKey("user", notContainedIn: blockedUsers)
        }
        
        if key != "user", let currentUser = PFUser.current() {
            
            let subTradeIdeaQuery = PFUser.query()
            subTradeIdeaQuery?.whereKey("blocked_users", notEqualTo: currentUser)
            
            tradeIdeaQuery.whereKey("user", matchesQuery: subTradeIdeaQuery!)
        }
        
        tradeIdeaQuery.countObjectsInBackground { (count, error) in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            let count = Int(count)
            
            print("tradeIdeas count", count)
            
            completion({return (count: count)})
        }
    }
    
    func queryActivityFor(fromUser: PFUser?, toUser: PFUser?, originalTradeIdea: PFObject?, tradeIdea: PFObject?, stock: [PFObject]?, activityType: [String]? , skip: Int?, limit: Int?, includeKeys: [String]?, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let activityQuery = PFQuery(className:"Activity")
        activityQuery.cachePolicy = cachePolicy
        
        switch order {
        case .ascending:
            activityQuery.order(byAscending: "createdAt")
        case .descending:
            activityQuery.order(byDescending: "createdAt")
        }
        
        if let creationDate = creationDate {
            activityQuery.whereKey("createdAt", greaterThan: creationDate)
        }
        
        if let includeKeys = includeKeys {
            activityQuery.includeKeys(includeKeys)
        }
        
        if let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            activityQuery.whereKey("fromUser", notContainedIn: blockedUsers)
        }
        
        if let fromUser = fromUser {
            activityQuery.whereKey("fromUser", equalTo: fromUser)
        }
        
        if let toUser = toUser {
            activityQuery.whereKey("toUser", equalTo: toUser)
        }
        
        if let originalTradeIdea = originalTradeIdea {
            activityQuery.whereKey("originalTradeIdea", equalTo: originalTradeIdea)
        }
        
        if let tradeIdea = tradeIdea {
            activityQuery.whereKey("tradeIdea", equalTo: tradeIdea)
        }
        
        if let stock = stock {
            activityQuery.whereKey("stock", containedIn: stock)
        }
        
        if let activityType = activityType {
            activityQuery.whereKey("activityType", containedIn: activityType)
        }
        
        if let skip = skip, skip > 0 {
            activityQuery.skip = skip
        }
        
        if let limit = limit, limit > 0 {
            activityQuery.limit = limit
        }
        
        activityQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard let objects = objects else {
                return completion({throw Constants.Errors.parseTradeIdeaObjectNotFound})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects: objects)})
        }
    }
    
    func countActivityFor(fromUser: PFUser?, toUser: PFUser?, tradeIdea: PFObject?, stock: PFObject?, activityType: String?, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> (Int)) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let activityQuery = PFQuery(className:"Activity")
        activityQuery.cachePolicy = cachePolicy
        activityQuery.order(byDescending: "createdAt")
        
        if let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            activityQuery.whereKey("fromUser", notContainedIn: blockedUsers)
        }
        
        if let fromUser = fromUser {
            activityQuery.whereKey("fromUser", equalTo: fromUser)
        }
        
        if let toUser = toUser {
            activityQuery.whereKey("toUser", equalTo: toUser)
        }
        
        if let tradeIdea = tradeIdea {
            activityQuery.whereKey("tradeIdea", equalTo: tradeIdea)
        }
        
        if let stock = stock {
            activityQuery.whereKey("stock", equalTo: stock)
        }
        
        if let activityType = activityType {
            activityQuery.whereKey("activityType", equalTo: activityType)
        }
        
        activityQuery.countObjectsInBackground { (count, error) in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            let count = Int(count)
            
            print("userActivity count", count)
            
            completion({return (count: count)})
        }
    }
    
    func queryActivityForUser(user: PFUser, skip: Int?, limit: Int?, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let activityQuery = PFQuery(className:"Activity")
        activityQuery.cachePolicy = cachePolicy
        
        switch order {
        case .ascending:
            activityQuery.order(byAscending: "createdAt")
        case .descending:
            activityQuery.order(byDescending: "createdAt")
        }
        
        if let creationDate = creationDate {
            activityQuery.whereKey("createdAt", greaterThan: creationDate)
        }
        
        activityQuery.whereKey("fromUser", notEqualTo: user)
        activityQuery.whereKey("toUser", equalTo: user)
        activityQuery.whereKeyExists("fromUser")
        activityQuery.includeKeys(["fromUser", "toUser", "tradeIdea", "stock"])
        
        if let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            activityQuery.whereKey("fromUser", notContainedIn: blockedUsers)
        }
        
        if let skip = skip, skip > 0 {
            activityQuery.skip = skip
        }
        
        if let limit = limit, limit > 0 {
            activityQuery.limit = limit
        }
        
        activityQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard let objects = objects else {
                return completion({throw Constants.Errors.parseTradeIdeaObjectNotFound})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects: objects)})
        }
    }
    
    func queryActivityForFollowing(fromUser: PFUser, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
//        guard Functions.isConnectedToNetwork() else {
//            return completion({throw Constants.Errors.noInternetConnection})
//        }
        
        let followActivityQuery = PFQuery(className:"Activity")
        followActivityQuery.cachePolicy = cachePolicy
        
        followActivityQuery.whereKey("fromUser", equalTo: fromUser)
        followActivityQuery.whereKeyExists("toUser")
        followActivityQuery.whereKey("activityType", equalTo: Constants.ActivityType.Follow.rawValue)
        
        let activityQuery = PFQuery(className:"Activity")
        activityQuery.cachePolicy = cachePolicy
        activityQuery.order(byDescending: "createdAt")
        
        activityQuery.whereKey("fromUser", notEqualTo: fromUser)
        activityQuery.whereKey("fromUser", matchesKey: "fromUser", in: followActivityQuery)
        activityQuery.includeKeys(["fromUser", "toUser", "tradeIdea", "stock"])
        
        if let currentUser = PFUser.current(), let blockedUsers = currentUser["blocked_users"] as? [PFUser] {
            activityQuery.whereKey("fromUser", notContainedIn: blockedUsers)
        }
        
        activityQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard objects?.isEmpty == false, let objects = objects else {
                return completion({throw Constants.Errors.parseTradeIdeaObjectNotFound})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) activities")
            
            completion({return (objects: objects)})
            
        }
    }
}
