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
    
    struct EODQuoteResult: Codable {
        let code: String
        let timestamp: Int
        let gmtoffset: Int
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Int
        let previousClose: Double
        let change: Double
        let changePercent: Double
        
        enum CodingKeys: String, CodingKey {
            case code
            case timestamp
            case gmtoffset
            case open
            case high
            case low
            case close
            case volume
            case previousClose
            case change
            case changePercent = "change_p"
        }
        
        static func encodeFrom(eodQuoteResult: [EODQuoteResult]) throws -> Data {
            guard !eodQuoteResult.isEmpty else { throw QueryError.errorParsingJSON }
            do {
                return try JSONEncoder().encode(eodQuoteResult)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
        
        static func decodeFrom(data: Data) throws -> [EODQuoteResult] {
            do {
                return try JSONDecoder().decode([EODQuoteResult].self, from: data)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
    }
    
    struct EODHistoricalResult: Codable {
        let date: String?
        let open: String?
        let high: String?
        let low: String?
        let close: String?
        let adjustedClose: String?
        let volume: String?
        
        var openValue: Double? {
            guard let open = open else { return nil }
            return Double(open)
        }
        var highValue: Double? {
            guard let high = high else { return nil }
            return Double(high)
        }
        var lowValue: Double? {
            guard let low = low else { return nil }
            return Double(low)
        }
        var closeValue: Double? {
            guard let close = close else { return nil }
            return Double(close)
        }
        var adjustedCloseValue: Double? {
            guard let adjustedClose = adjustedClose else { return nil }
            return Double(adjustedClose)
        }
        var volumeValue: Int? {
            guard let volume = volume else { return nil }
            return Int(volume)
        }
        
        enum CodingKeys: String, CodingKey {
            case date
            case open
            case high
            case low
            case close
            case adjustedClose = "adjusted_close"
            case volume
        }
        
        static func encodeFrom(eodHistoricalResults: [EODHistoricalResult]) throws -> Data {
            guard !eodHistoricalResults.isEmpty else { throw QueryError.errorParsingJSON }
            do {
                return try JSONEncoder().encode(eodHistoricalResults)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
        
        static func decodeFrom(data: Data) throws -> [EODHistoricalResult] {
            do {
                return try JSONDecoder().decode([EODHistoricalResult].self, from: data)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
    }
    
    struct EODFundamentalsResult: Codable {
        
        struct General: Codable {
            let code: String?
            let type: String?
            let name: String?
            let exchange: String?
            let currencyCode: String?
            let currencyName: String?
            let currencySymbol: String?
            let countryName: String?
            let countryISO: String?
            let ISIN: String?
            let CUSIP: String?
            let sector: String?
            let industry: String?
            let description: String?
            let fullTimeEmployees: Int?
            let updatedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case code = "Code"
                case type = "Type"
                case name = "Name"
                case exchange = "Exchange"
                case currencyCode = "CurrencyCode"
                case currencyName = "CurrencyName"
                case currencySymbol = "CurrencySymbol"
                case countryName = "CountryName"
                case countryISO = "CountryISO"
                case ISIN = "ISIN"
                case CUSIP = "CUSIP"
                case sector = "Sector"
                case industry = "Industry"
                case description = "Description"
                case fullTimeEmployees = "FullTimeEmployees"
                case updatedAt = "UpdatedAt"
            }
        }
        
        struct Highlights: Codable {
            let marketCapitalization: Int?
            let marketCapitalizationMln: String?
            let EBITDA: Int?
            let peRatio: String?
            let peGRatio: String?
            let wallStreetTargetPrice: String?
            let bookValue: String?
            let dividendShare: String?
            let dividendYield: String?
            let eps: String?
            let epsEstimateCurrentYear: String?
            let epsEstimateNextYear: String?
            let epsEstimateNextQuarter: String?
            let mostRecentQuarter: String?
            let profitMargin: String?
            let operatingMarginTTM: String?
            let returnOnAssetsTTM: String?
            let returnOnEquityTTM: String?
            let revenueTTM: String?
            let revenuePerShareTTM: String?
            let quarterlyRevenueGrowthYOY: String?
            let grossProfitTTM: String?
            let dilutedEpsTTM: String?
            let quarterlyEarningsGrowthYOY: String?
            
            enum CodingKeys: String, CodingKey {
                case marketCapitalization = "MarketCapitalization"
                case marketCapitalizationMln = "MarketCapitalizationMln"
                case EBITDA = "EBITDA"
                case peRatio = "PERatio"
                case peGRatio = "PEGRatio"
                case wallStreetTargetPrice = "WallStreetTargetPrice"
                case bookValue = "BookValue"
                case dividendShare = "DividendShare"
                case dividendYield = "DividendYield"
                case eps = "EarningsShare"
                case epsEstimateCurrentYear = "EPSEstimateCurrentYear"
                case epsEstimateNextYear = "EPSEstimateNextYear"
                case epsEstimateNextQuarter = "EPSEstimateNextQuarter"
                case mostRecentQuarter = "MostRecentQuarter"
                case profitMargin = "ProfitMargin"
                case operatingMarginTTM = "OperatingMarginTTM"
                case returnOnAssetsTTM = "ReturnOnAssetsTTM"
                case returnOnEquityTTM = "ReturnOnEquityTTM"
                case revenueTTM = "RevenueTTM"
                case revenuePerShareTTM = "RevenuePerShareTTM"
                case quarterlyRevenueGrowthYOY = "QuarterlyRevenueGrowthYOY"
                case grossProfitTTM = "GrossProfitTTM"
                case dilutedEpsTTM = "DilutedEpsTTM"
                case quarterlyEarningsGrowthYOY = "QuarterlyEarningsGrowthYOY"
            }
        }
        
        struct Valuation: Codable {
            let trailingPE: String?
            let forwardPE: String?
            let priceSalesTTM: String?
            let priceBookMRQ: String?
            let enterpriseValueRevenue: String?
            let enterpriseValueEbitda: String?
            
            enum CodingKeys: String, CodingKey {
                case trailingPE = "TrailingPE"
                case forwardPE = "ForwardPE"
                case priceSalesTTM = "PriceSalesTTM"
                case priceBookMRQ = "PriceBookMRQ"
                case enterpriseValueRevenue = "EnterpriseValueRevenue"
                case enterpriseValueEbitda = "EnterpriseValueEbitda"
            }
        }
        
        struct Technicals: Codable {
            let beta: String?
            let fiftyTwoWeekLow: String?
            let fiftyTwoWeekHigh: String?
            let fiftyDayMA: String?
            let twoHundredDayMA: String?
            let sharesShort: String?
            let sharesShortPriorMonth: String?
            let shortRatio: String?
            let shortPercent: String?
            
            enum CodingKeys: String, CodingKey {
                case beta = "Beta"
                case fiftyTwoWeekLow = "52WeekLow"
                case fiftyTwoWeekHigh = "52WeekHigh"
                case fiftyDayMA = "50DayMA"
                case twoHundredDayMA = "200DayMA"
                case sharesShort = "SharesShort"
                case sharesShortPriorMonth = "SharesShortPriorMonth"
                case shortRatio = "ShortRatio"
                case shortPercent = "ShortPercent"
            }
        }
        
        let general: General
        let highlights: Highlights
        let valuation: Valuation
        let technicals: Technicals
        
        enum CodingKeys: String, CodingKey {
            case general = "General"
            case highlights = "Highlights"
            case valuation = "Valuation"
            case technicals = "Technicals"
        }
        
        static func encodeFrom(eodFundamentalsResult: EODFundamentalsResult) throws -> Data {
            do {
                return try JSONEncoder().encode(eodFundamentalsResult)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
        
        static func decodeFrom(data: Data) throws -> EODFundamentalsResult {
            do {
                return try JSONDecoder().decode(EODFundamentalsResult.self, from: data)
            } catch {
                throw QueryError.errorParsingJSON
            }
        }
    }
    
    enum QueryError: Error {
        case noInternetConnection
        case noExchangesOrSectorsSelected
        case ranOutOfChartCards
        case errorAccessingServer
        case errorQueryingForCoreData
        case errorQueryingForData(error: Error)
        case queryDataEmpty
        case errorParsingJSON
        case parseObjectAlreadyExists
        case objectDoesntExists
        case chartImageCorrupt
        case urlEmpty
        
        public func message() -> String {
            switch self {
            case .noInternetConnection:
                return "No internet connection!\nMake sure your device is connected"
            case .noExchangesOrSectorsSelected:
                return "No Filters?\nYou must have at least one exchange and one sector selected"
            case .ranOutOfChartCards:
                return "Temporarily out of Stock \n Check back soon!"
            case .errorAccessingServer:
                return  "There was an error while accessing the server"
            case .errorQueryingForCoreData:
                return  "Oops! We ran into an issue querying for data"
            case .errorQueryingForData:
                return  "Oops! We ran into an issue querying for data"
            case .queryDataEmpty:
                return "Oops! We ran into an issue querying for data"
            case .errorParsingJSON:
                return "Oops! We ran into an issue querying for data"
            case .parseObjectAlreadyExists:
                return "This symbol already exists in our databse"
            case .objectDoesntExists:
                return "This symbol doesn't exist in our database"
            case .chartImageCorrupt:
                return "Oops! We ran into an issue querying for data"
            case .urlEmpty:
                return "Oops! We ran into an issue querying for data"
            }
        }
    }
    
    static let sharedInstance = QueryHelper()
    static let queryLimit = 25

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
                
                guard error == nil else { return completionHandler({ throw QueryError.errorQueryingForData(error: error!) }) }
                guard let queryData = queryData else {
                    return completionHandler({throw QueryError.queryDataEmpty})
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
                
                guard error == nil else { return completionHandler({ throw QueryError.errorQueryingForData(error: error!) }) }
                guard let trendingStocksData = trendingStocksData else {
                    return completionHandler({ throw QueryError.queryDataEmpty })
                }
                
                return completionHandler({ trendingStocksData })
            })
            task.resume()
        }
    }
    
    func queryEODQuotes(for symbols: [String], useCacheIfPossible: Bool = false, completionHandler:@escaping (_ eodQuoteResults: () throws -> ([EODQuoteResult], Data)) -> Void) -> Void {
        
        let firstSymbol = symbols[0]
        let remainingOfSymbols = symbols.suffix(from: 1)
        let stringOfRemainingOfSymbols = remainingOfSymbols.joined(separator: ",")
        
        let query = "https://eodhistoricaldata.com/api/real-time/" + firstSymbol +
                    "?api_token=" + Constants.APIKeys.EodHistorcalData.key() +
                    "&fmt=json&s=" + stringOfRemainingOfSymbols
        
        if let queryURLString = query.URLEncodedString(), let queryURL = URL(string: queryURLString) {
            
            var session: URLSession!
            if useCacheIfPossible {
                let config = URLSessionConfiguration.default
                config.urlCache = URLCache.shared
                config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
                session = URLSession(configuration: config)
            } else {
                session = URLSession.shared
            }
            
            let task = session.dataTask(with: queryURL, completionHandler: { (eodData, response, error) -> Void in
                
                guard error == nil else { return completionHandler({ throw QueryError.errorQueryingForData(error: error!) }) }
                guard let eodData = eodData else {
                    return completionHandler({ throw QueryError.queryDataEmpty })
                }
                
                do {
                    let eodQuoteResults = try EODQuoteResult.decodeFrom(data: eodData)
                    completionHandler({ (eodQuoteResults, eodData) })
                } catch {
                    completionHandler({ throw error })
                }
            })
            task.resume()
        }
    }
    
    func queryEODHistorical(for symbol: String, useCacheIfPossible: Bool = false, completionHandler: @escaping (_ eodQuoteResults: () throws -> [EODHistoricalResult]) -> Void) -> Void {
                
        let today = Date()
        let oneYearAgp = Date.dateBySubtractingDays(today, numberOfDays: -365)
        let query = "https://eodhistoricaldata.com/api/eod/" + symbol +
            "?from=" + oneYearAgp.dateFormattedString() +
            "&to=" + today.dateFormattedString() +
            "&api_token=" + Constants.APIKeys.EodHistorcalData.key() +
            "&period=d" +
            "&fmt=json"
        
        if let queryURLString = query.URLEncodedString(), let queryURL = URL(string: queryURLString) {
            
            var session: URLSession!
            if useCacheIfPossible {
                let config = URLSessionConfiguration.default
                config.urlCache = URLCache.shared
                config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
                session = URLSession(configuration: config)
            } else {
                session = URLSession.shared
            }
            
            let task = session.dataTask(with: queryURL, completionHandler: { (eodData, response, error) -> Void in
                
                guard error == nil else { return completionHandler({ throw QueryError.errorQueryingForData(error: error!) }) }
                guard let eodData = eodData else {
                    return completionHandler({ throw QueryError.queryDataEmpty })
                }
                
                do {
                    let eodHistoricalResults = try EODHistoricalResult.decodeFrom(data: eodData)
                    completionHandler({ (eodHistoricalResults) })
                } catch {
                    completionHandler({ throw error })
                }
            })
            task.resume()
        }
    }
    
    func queryEODFundamentals(for symbol: String, useCacheIfPossible: Bool = true, completionHandler: @escaping (_ eodQuoteResults: () throws -> (EODFundamentalsResult)) -> Void) -> Void {
        
        let query = "https://eodhistoricaldata.com/api/fundamentals/" + symbol +
            "?api_token=" + Constants.APIKeys.EodHistorcalData.key()
        
        if let queryURLString = query.URLEncodedString(), let queryURL = URL(string: queryURLString) {
            
            var session: URLSession!
            if useCacheIfPossible {
                let config = URLSessionConfiguration.default
                config.urlCache = URLCache.shared
                config.requestCachePolicy = NSURLRequest.CachePolicy.returnCacheDataElseLoad
                session = URLSession(configuration: config)
            } else {
                session = URLSession.shared
            }
            
            let task = session.dataTask(with: queryURL, completionHandler: { (eodData, response, error) -> Void in
                
                guard error == nil else { return completionHandler({ throw QueryError.errorQueryingForData(error: error!) }) }
                guard let eodData = eodData else {
                    return completionHandler({ throw QueryError.queryDataEmpty })
                }

                do {
                    let eodFundamentalsResult = try EODFundamentalsResult.decodeFrom(data: eodData)
                    completionHandler({ eodFundamentalsResult })
                } catch {
                    completionHandler({ throw error })
                }
            })
            task.resume()
        }
    }
    
    func queryUserObjectsFor(usernames: [String], cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFUser])) -> Void) {
        
        let usernamesLowercase = usernames.map { ($0.lowercased()) }
        
        let userQuery = User.query()
        userQuery?.cachePolicy = cachePolicy
        userQuery?.whereKey("username_lowercase", containedIn: usernamesLowercase)
        userQuery?.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects as? [PFUser] else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            completion({return (objects)})
            
        }
    }
    
    func queryStockObjectsFor(symbols: [String], cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
        let mappedSymbols = symbols.map ({ $0.uppercased() })
        
        let stockQuery = Stock.query()!
        stockQuery.cachePolicy = cachePolicy
        stockQuery.whereKey("Symbol", containedIn: mappedSymbols)
        stockQuery.findObjectsInBackground { (objects, error) -> Void in
            
            guard error == nil else {
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            completion({return (objects)})
            
        }
    }
    
    func queryTradeIdeaObjectsFor(key: String?, object: PFObject?, skip: Int?, limit: Int?, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
        let tradeIdeaQuery = TradeIdea.query()!
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
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects)})
        }
    }
    
    func countTradeIdeasFor(key: String, object: PFObject, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> (Int)) -> Void) {
        
        let tradeIdeaQuery = TradeIdea.query()!
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
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            let count = Int(count)
            completion({return (count)})
        }
    }
    
    func queryActivityFor(fromUser: PFUser? = nil, toUser: PFUser? = nil, originalTradeIdea: PFObject? = nil, tradeIdea: PFObject? = nil, stocks: [PFObject]? = nil, activityType: [String]? = nil, skip: Int? = nil, limit: Int? = nil, includeKeys: [String]? = nil, selectKeys: [String]? = nil, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
        let activityQuery = Activity.query()!
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
        
        if let selectKeys = selectKeys {
            activityQuery.selectKeys(selectKeys)
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
        
        if let stocks = stocks {
            activityQuery.whereKey("stock", containedIn: stocks)
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
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects)})
        }
    }
    
    func countActivityFor(fromUser: PFUser?, toUser: PFUser?, originalTradeIdea: PFObject?, tradeIdea: PFObject?, stocks: [PFObject]?, activityType: [String]?, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> (Int)) -> Void) {
        
        let activityQuery = Activity.query()!
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
        
        if let originalTradeIdea = originalTradeIdea {
            activityQuery.whereKey("originalTradeIdea", equalTo: originalTradeIdea)
        }
        
        if let tradeIdea = tradeIdea {
            activityQuery.whereKey("tradeIdea", equalTo: tradeIdea)
        }
        
        if let stocks = stocks {
            activityQuery.whereKey("stock", containedIn: stocks)
        }
        
        if let activityType = activityType {
            activityQuery.whereKey("activityType", containedIn: activityType)
        }
        
        activityQuery.countObjectsInBackground { (count, error) in
            
            guard error == nil else {
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            let count = Int(count)
            completion({return (count)})
        }
    }
    
    func queryActivityForUser(user: PFUser, skip: Int?, limit: Int?, order: QueryOrder = .descending, creationDate: Date? = nil, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
        let activityQuery = Activity.query()!
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
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            // The find succeeded.
            print("Successfully retrieved \(objects.count) objects")
            
            completion({return (objects)})
        }
    }
    
    func queryActivityForFollowing(fromUser: PFUser, cachePolicy: PFCachePolicy = .networkElseCache, completion: @escaping (_ result: () throws -> ([PFObject])) -> Void) {
        
        let followActivityQuery = Activity.query()!
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
                return completion({throw QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let objects = objects else {
                return completion({throw QueryError.queryDataEmpty})
            }
            
            completion({return (objects)})
            
        }
    }
}
