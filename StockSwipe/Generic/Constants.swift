//
//  Constants.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation
import CoreData
import Parse

var chartWidth:CGFloat = 0
var chartHeight:CGFloat = 0
var frontCardOffsetFromCenter:CGFloat = 0

var horizontalPadding:CGFloat!
var verticalPadding:CGFloat!
var numberOfCellsHorizontally: CGFloat!
var numberOfCellsVertically: CGFloat!

var nsUserActivityArray = [NSUserActivity]()

let motionOffset: CGFloat = 20

public class Constants {
    
    public static let window: UIWindow? = UIApplication.sharedApplication().keyWindow
    public static let current = UIDevice.currentDevice()
    public static let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier
    public static let infoDict = NSBundle.mainBundle().infoDictionary
    public static let AppVersion = infoDict!["CFBundleShortVersionString"]!
    public static let BundleVersion = infoDict!["CFBundleVersion"]!
    
    public static let payloadShort = "Version: \(AppVersion) (\(BundleVersion)) \n Copyright © 2015"
    public static let payload = [ "BundleID" : infoDict!["CFBundleIdentifier"]!,
        "AppVersion" : AppVersion,
        "BundleVersion" : BundleVersion,
        "DeviceModel" : current.model,
        "SystemName" : current.systemName,
        "SystemVersion" : current.systemVersion ]
    
    public static let appLink: String = "https://itunes.apple.com/us/app/stockswipe-probably-funnest/id1009599685?ls=1&mt=8"
    public static let appLinkURL = NSURL(string: appLink)
    public static let appURL = NSURL(string: "itms-apps://itunes.apple.com/app/id1009599685")
    public static let appReviewURL = NSURL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1009599685")
    public static let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)
    
    public static let appEmail: String = "StockSwipe@gmail.com"
    public static let emailTitle = "StockSwipe Feedback/Bug"
    public static let messageBody = "Hello StockSwipe Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
    public static let toReceipients = [appEmail]
    public static let emailDiagnosticInfo = Array(payload.keys).reduce("", combine: { (input, key) -> String in
        return "\(input)\r\n\(key): \(payload[key]!)</br>"
    })
    
    public static let storyboard = UIStoryboard(name: "Main", bundle: nil)
    public static let app = UIApplication.sharedApplication()
    static let appDel:AppDelegate = app.delegate as! AppDelegate
    public static let context: NSManagedObjectContext = appDel.managedObjectContext
    public static let entity = NSEntityDescription.entityForName("Charts", inManagedObjectContext: context)
    public static let fetchRequest = NSFetchRequest(entityName: "Charts")
    
    public static let stockSwipeFont = UIFont(name: "HelveticaNeue", size: 20)
    public static let stockSwipeFontColor: UIColor = UIColor(red: 111/255, green: 113/255, blue: 121/255, alpha: 1.0)
    public static let stockSwipeGreenColor: UIColor = UIColor(red: 25/255, green: 215/255, blue: 25/255, alpha: 1.0)
    public static let okAlertAction = UIAlertAction(title: "Ok", style: .Default, handler:{ (ACTION :UIAlertAction!)in })
    
    public static let settingsAlertAction: UIAlertAction = UIAlertAction(title: "Settings", style: .Default, handler: { (action: UIAlertAction!) in
        
        UIApplication.sharedApplication().openURL(settingsURL!)
        
    })
    
    public static let cancelAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler:{ (ACTION :UIAlertAction!) in })
    
    public static let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
    
    public enum APIKeys: ErrorType {
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
    
    public enum Errors: ErrorType {
        case NoInternetConnection
        case NoExchangesOrSectorsSelected
        case RanOutOfChartCards
        case ErrorAccessingParseDatabase
        case ErrorAccessingServer
        case ErrorQueryingForData
        case QueryDataEmpty
        case ErrorParsingData
        case ParseObjectNotFound
        case ChartImageCorrupt
        case URLEmpty
        
        public func message() -> String {
            switch self {
            case .NoInternetConnection:
                return "No internet connection!\nMake sure your device is connected to begin search"
            case .NoExchangesOrSectorsSelected:
                return "No Filters?\nYou must have at least one exchange and one sector selected"
            case .RanOutOfChartCards:
                return "Temporarily out of Stock \n Check back soon!"
            case .ErrorAccessingParseDatabase:
                return  "There was an error while accessing the database"
            case .ErrorAccessingServer:
                return  "There was an error while accessing the server"
            case .ErrorQueryingForData:
                return  "Oops! We ran into an issue querying for data"
            case .QueryDataEmpty:
                return "Oops! We ran into an issue querying for data"
            case .ErrorParsingData:
                return "Oops! We ran into an issue querying for data"
            case .ParseObjectNotFound:
                return "We could not find this symbol in our database"
            case .ChartImageCorrupt:
                return "Oops! We ran into an issue querying for data"
            case .URLEmpty:
                return "Oops! We ran into an issue querying for data"
            }
        }
        static let allErrors = [NoInternetConnection, NoExchangesOrSectorsSelected, RanOutOfChartCards, ErrorAccessingParseDatabase, ErrorAccessingServer, ErrorQueryingForData, QueryDataEmpty, ErrorParsingData, ParseObjectNotFound, ChartImageCorrupt, URLEmpty]
    }
    
    public enum UserChoices: String {
        case LONG, SHORT, SKIP
        
        public func key() -> String {
            switch self {
            case .LONG:
                return "Longed_By"
            case .SHORT:
                return "Shorted_By"
            case .SKIP:
                return "Skipped_By"
            }
        }
        
        static let allChoices = [LONG, SHORT, SKIP]
    }
    
    public struct Symbol {
        
        public enum Exchange: String {
            case NASDAQ, NYSE, AMEX, TSX
            
            public func key() -> String {
                switch self {
                default:
                    return String(self)
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
        static let optJoin = "(?:" + ZWJ + "(?:" + [nonAstral, regional, surrPair].joinWithSeparator("|") + ")" + optVar + optMod + ")*"
        static let seq = optVar + optMod + optJoin
        static let emoji = "(?:" + [dingbat, regional, surrPair].joinWithSeparator("|") + ")" + seq
        static let symbol = "(?:" + [nonAstral + combo + "?", combo, regional, surrPair, astral].joinWithSeparator("|") + ")"
        
        /// Match non-compound words composed of alphanumeric characters
        static let basicWord = "[a-zA-Z0-9]+"
        
        /// Match complex or compound words
        static let complexWord = [
            upper + "?" + lower + "+(?=" + [breakGroup, upper, "$"].joinWithSeparator("|") + ")",
            upperMisc + "+(?=" + [breakGroup, upper + lowerMisc, "$"].joinWithSeparator("|") + ")",
            upper + "?" + lowerMisc + "+",
            digits + "(?:" + lowerMisc + "+)?",
            emoji
            ].joinWithSeparator("|")
        
        /// Detect strings that need a more robust regexp to match words
        static let hasComplexWord = "[a-z][A-Z]|[0-9][a-zA-Z]|[a-zA-Z][0-9]|[^a-zA-Z0-9 ]"
    }
    
    public static let informationViewHeight:CGFloat = 50
    public static let chartImageTopPadding:CGFloat = 10.0
}
