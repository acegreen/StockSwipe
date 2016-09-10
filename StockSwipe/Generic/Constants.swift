//
//  Constants.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation
import CoreData

var chartWidth:CGFloat = 0
var chartHeight:CGFloat = 0
var frontCardOffsetFromCenter:CGFloat = 0

var horizontalPadding:CGFloat!
var verticalPadding:CGFloat!
var numberOfCellsHorizontally: CGFloat!
var numberOfCellsVertically: CGFloat!

var nsUserActivityArray = [NSUserActivity]()

let motionOffset: CGFloat = 20

open class Constants {
    
    open static var window: UIWindow? {
        get {
            return UIApplication.shared.keyWindow
        }
    }
    
    open static let current = UIDevice.current
    open static let bundleIdentifier = Bundle.main.bundleIdentifier
    open static let infoDict = Bundle.main.infoDictionary
    open static let AppVersion = infoDict!["CFBundleShortVersionString"]!
    open static let BundleVersion = infoDict!["CFBundleVersion"]!
    
    open static let userDefaults: UserDefaults = UserDefaults.standard
    
    open static let payloadShort = "Version: \(AppVersion) (\(BundleVersion)) \n Copyright © 2015"
    open static let payload = [ "BundleID" : infoDict!["CFBundleIdentifier"]!,
        "AppVersion" : AppVersion,
        "BundleVersion" : BundleVersion,
        "DeviceModel" : current.model,
        "SystemName" : current.systemName,
        "SystemVersion" : current.systemVersion ]
    
    open static let appLink: String = "https://itunes.apple.com/us/app/stockswipe-probably-funnest/id1009599685?ls=1&mt=8"
    open static let appLinkURL = URL(string: appLink)
    open static let facebookAppLink = URL(string: "https://fb.me/1156458804442388")
    open static let appURL = URL(string: "itms-apps://itunes.apple.com/app/id1009599685")
    open static let appReviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1009599685")
    open static let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
    
    open static let appEmail: String = "StockSwipe@gmail.com"
    open static let emailTitle = "StockSwipe Feedback/Bug"
    open static let messageBody = "Hello StockSwipe Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
    open static let toReceipients = [appEmail]
    open static let emailDiagnosticInfo = Array(payload.keys).reduce("", { (input, key) -> String in
        return "\(input)\r\n\(key): \(payload[key]!)</br>"
    })
    
    open static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    open static let app = UIApplication.shared
    static let appDel:AppDelegate = app.delegate as! AppDelegate
    open static let context: NSManagedObjectContext = appDel.managedObjectContext
    open static let entity = NSEntityDescription.entity(forEntityName: "Charts", in: context)
    open static let fetchRequest = NSFetchRequest(entityName: "Charts")
    
    open static let stockSwipeFont: UIFont? = UIFont(name: "HelveticaNeue", size: 20)
    open static let stockSwipeFontColor: UIColor = UIColor(red: 111/255, green: 113/255, blue: 121/255, alpha: 1.0)
    open static let stockSwipeGreenColor: UIColor = UIColor(red: 25/255, green: 200/255, blue: 25/255, alpha: 1.0)
    open static let stockSwipeGoldColor: UIColor = UIColor(red: 245, green: 192, blue: 24)
    open static let okAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!)in })
    
    open static let settingsAlertAction: UIAlertAction = UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
        UIApplication.shared.openURL(settingsURL!)
    })
    
    open static let cancelAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (ACTION :UIAlertAction!) in })
    
    open static let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
    
    public enum APIKeys: String {
        case Parse
        case TwitterKit
        case LaunchKit
        case Rollout
        case ChimpKit
        case TradeItDev
        case TradeItProd
        
        public func key() -> String {
            switch self {
            case .Parse:
                return "23DjJFgzcSmSyqxJEC4FYf5e0aOc6iTtlVJP7l7k"
            case .TwitterKit:
                return "ANFH82HYTm0L9IAjlA0bH4nmK"
            case .LaunchKit:
                return "FYwLCkgJpT_r8kEp1O_-PSg-UnhaD3B7PMPxkG5qIIfq"
            case .Rollout:
                return "568730c9045462554abcb4cc"
            case .ChimpKit:
                return "549c43655bcc48fb60af6a1c24e77495-us12"
            case .TradeItDev:
                return "3e6d674e62714a1ea041a455ae0d2fe2"
            case .TradeItProd:
                return "3972dfa21434487b9fe084f30edb8f3c"
            }
        }
        
        public func consumerKey() -> String? {
            switch self {
            case .TwitterKit:
                return "jPLlObo3SDOtm5ny8s5t0cWa6JV0u9kNr4v2DFwiX9Dtdl7sRg"
            default:
                return nil
            }
        }
        
        static let allAPIKeys = [Parse, TwitterKit, LaunchKit, Rollout, ChimpKit, TradeItDev, TradeItProd]
    }
    
    public enum Errors: Error {
        case noInternetConnection
        case noExchangesOrSectorsSelected
        case ranOutOfChartCards
        case errorAccessingParseDatabase
        case errorAccessingServer
        case errorQueryingForData
        case queryDataEmpty
        case errorParsingData
        case parseUserObjectNotFound
        case parseStockObjectNotFound
        case parseTradeIdeaObjectNotFound
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
            case .errorAccessingParseDatabase:
                return  "There was an error while accessing the database"
            case .errorAccessingServer:
                return  "There was an error while accessing the server"
            case .errorQueryingForData:
                return  "Oops! We ran into an issue querying for data"
            case .queryDataEmpty:
                return "Oops! We ran into an issue querying for data"
            case .errorParsingData:
                return "Oops! We ran into an issue querying for data"
            case .parseUserObjectNotFound:
                return "We could not find this user in our database"
            case .parseStockObjectNotFound:
                return "We could not find this symbol in our database"
            case .parseTradeIdeaObjectNotFound:
                return "We could not find this trade idea in our database"
            case .chartImageCorrupt:
                return "Oops! We ran into an issue querying for data"
            case .urlEmpty:
                return "Oops! We ran into an issue querying for data"
            }
        }
        static let allErrors = [noInternetConnection, noExchangesOrSectorsSelected, ranOutOfChartCards, errorAccessingParseDatabase, errorAccessingServer, errorQueryingForData, queryDataEmpty, errorParsingData, parseUserObjectNotFound,parseStockObjectNotFound,parseTradeIdeaObjectNotFound, chartImageCorrupt, urlEmpty]
    }
    
    public enum UserChoices: String {
        case LONG = "LONG"
        case SHORT = "SHORT"
        case SKIP = "SKIP"
    }
    
    enum ActivityType: String {
        case Follow = "follow"
        case TradeIdeaNew = "tradeIdeaNew"
        case TradeIdeaReply = "tradeIdeaReply"
        case TradeIdeaLike = "tradeIdeaLike"
        case TradeIdeaReshare = "tradeIdeaReshare"
        case StockLong = "stockLong"
        case StockShort = "stockShort"
        case Block = "block"
        case Mention = "mention"
    }
    
    enum TradeIdeaType {
        case new
        case reply
        case reshare
    }
    
    enum PushType: String {
        case ToUser = "pushNotificationToUser"
        case ToFollowers = "pushNotificationToFollowers"
    }
    
    enum TimeFormat {
        case short
        case long
    }
    
    public struct Symbol {
        
        public enum Exchange: String {
            case NASDAQ, NYSE, AMEX, TSX
            
            public func key() -> String {
                switch self {
                default:
                    return String(describing: self)
                }
            }
            
            static var allExchanges = [NASDAQ, NYSE, AMEX, TSX]
        }
        
        public enum Sector: String {
            case BasicMaterials, Conglomerates, ConsumerGoods, Financial, Healthcare, IndustrialGoods, Services, Technology, Utilities
            
            public func key() -> String {
                switch self {
                case .BasicMaterials:
                    return "BASIC MATERIALS"
                case .Conglomerates:
                    return "CONGLOMERATES"
                case .ConsumerGoods:
                    return "CONSUMER GOODS"
                case .Financial:
                    return "FINANCIAL"
                case .Healthcare:
                    return "HEALTHCARE"
                case .IndustrialGoods:
                    return "INDUSTRIAL GOODS"
                case .Services:
                    return "SERVICES"
                case .Technology:
                    return "TECHNOLOGY"
                case .Utilities:
                    return "UTILITIES"
                }
            }
            
            static var allSectors = [BasicMaterials, Conglomerates, ConsumerGoods, Financial, Healthcare, IndustrialGoods, Services, Technology, Utilities]
        }
    }
    
    struct RegexHelper {
        
        /// Unicode character classes
        static let astralRange = "\\ud800-\\udfff"
        static let comboRange = "\\u0300-\\u036f\\ufe20-\\ufe23"
        static let dingbatRange = "\\u2700-\\u27bf"
        static let lowerRange = "a-z\\xdf-\\xf6\\xf8-\\xff"
        static let mathOpRange = "\\xac\\xb1\\xd7\\xf7"
        static let nonCharRange = "\\x00-\\x2f\\x3a-\\x40\\x5b-\\x60\\x7b-\\xbf"
        static let quoteRange = "\\u2018\\u2019\\u201c\\u201d"
        static let spaceRange = "\\t\\x0b\\f\\xa0\\ufeff\\n\\r\\u2028\\u2029\\u1680\\u180e\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2007\\u2008\\u2009\\u200a\\u202f\\u205f\\u3000"
        static let upperRange = "A-Z\\xc0-\\xd6\\xd8-\\xde"
        static let varRange = "\\ufe0e\\ufe0f"
        static let breakRange = mathOpRange + nonCharRange + quoteRange + spaceRange
        
        /// Unicode capture groups
        static let astral = "[" + astralRange + "]"
        static let breakGroup = "[" + breakRange + "]"
        static let combo = "[" + comboRange + "]"
        static let digits = "\\d+"
        static let dingbat = "[" + dingbatRange + "]"
        static let lower = "[" + lowerRange + "]"
        static let misc = "[^" + astralRange + breakRange + digits + dingbatRange + lowerRange + upperRange + "]"
        static let modifier = "(?:\\ud83c[\\udffb-\\udfff])"
        static let nonAstral = "[^" + astralRange + "]"
        static let regional = "(?:\\ud83c[\\udde6-\\uddff]){2}"
        static let surrPair = "[\\ud800-\\udbff][\\udc00-\\udfff]"
        static let upper = "[" + upperRange + "]"
        static let ZWJ = "\\u200d"
        
        /// Unicode regex composers
        static let lowerMisc = "(?:" + lower + "|" + misc + ")"
        static let upperMisc = "(?:" + upper + "|" + misc + ")"
        static let optMod = modifier + "?"
        static let optVar = "[" + varRange + "]"
        static let optJoin = "(?:" + ZWJ + "(?:" + [nonAstral, regional, surrPair].joined(separator: "|") + ")" + optVar + optMod + ")*"
        static let seq = optVar + optMod + optJoin
        static let emoji = "(?:" + [dingbat, regional, surrPair].joined(separator: "|") + ")" + seq
        static let symbol = "(?:" + [nonAstral + combo + "?", combo, regional, surrPair, astral].joined(separator: "|") + ")"
        
        /// Match non-compound words composed of alphanumeric characters
        static let basicWord = "[a-zA-Z0-9]+"
        
        /// Match complex or compound words
        static let complexWord = [
            upper + "?" + lower + "+(?=" + [breakGroup, upper, "$"].joined(separator: "|") + ")",
            upperMisc + "+(?=" + [breakGroup, upper + lowerMisc, "$"].joined(separator: "|") + ")",
            upper + "?" + lowerMisc + "+",
            digits + "(?:" + lowerMisc + "+)?",
            emoji
            ].joined(separator: "|")
        
        /// Detect strings that need a more robust regexp to match words
        static let hasComplexWord = "[a-z][A-Z]|[0-9][a-zA-Z]|[a-zA-Z][0-9]|[^a-zA-Z0-9 ]"
    }
    
    open static let informationViewHeight:CGFloat = 50
    open static let chartImageTopPadding:CGFloat = 10.0
}
