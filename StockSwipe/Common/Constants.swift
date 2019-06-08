//
//  Constants.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation
import CoreData
import Reachability

var cardWidth: CGFloat = 0
var cardHeight: CGFloat = 0

var numberOfCellsHorizontally: CGFloat!
var numberOfCellsVertically: CGFloat!

var nsUserActivityArray = [NSUserActivity]()

let motionOffset: CGFloat = 20

class Constants {
    
    static var window: UIWindow? {
        get {
            return UIApplication.shared.keyWindow
        }
    }
    
    static let current = UIDevice.current
    static let bundleIdentifier = Bundle.main.bundleIdentifier
    static let infoDict = Bundle.main.infoDictionary
    static let AppVersion = infoDict!["CFBundleShortVersionString"]!
    static let BundleVersion = infoDict!["CFBundleVersion"]!
    
    static let userDefaults: UserDefaults = UserDefaults.standard
    static var swipeAddToWatchlist: Bool = false
    
    static let payloadShort = "Version: \(AppVersion) (\(BundleVersion)) \n Copyright © 2015"
    static let payload = [ "BundleID" : infoDict!["CFBundleIdentifier"]!,
        "AppVersion" : AppVersion,
        "BundleVersion" : BundleVersion,
        "DeviceModel" : current.model,
        "SystemName" : current.systemName,
        "SystemVersion" : current.systemVersion ]
    
    static let appLinkURL = URL(string: "https://itunes.apple.com/us/app/stockswipe-probably-funnest/id1009599685?ls=1&mt=8")
    static let facebookAppLink = URL(string: "https://fb.me/1156458804442388")
    static let appURL = URL(string: "itms-apps://itunes.apple.com/app/id1009599685")!
    static let appReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id1009599685?action=write-review")!
    static let settingsURL = URL(string: UIApplication.openSettingsURLString)
    static let publicationURL = URL(string: "https://medium.com/stockswipe-trade-ideas")
    static let branchURL = URL(string: "https://n5qlr.app.link/VpY8IrjnmX")
    
    static let appEmail: String = "StockSwipe@gmail.com"
    static let emailTitle = "StockSwipe Feedback/Bug"
    static let messageBody = "Hello StockSwipe Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + emailDiagnosticInfo
    static let toReceipients = [appEmail]
    static let emailDiagnosticInfo = Array(payload.keys).reduce("", { (input, key) -> String in
        return "\(input)\r\n\(key): \(payload[key]!)</br>"
    })

    static let app = UIApplication.shared
    static let appDel:AppDelegate = app.delegate as! AppDelegate
    static let context: NSManagedObjectContext = appDel.managedObjectContext
    static let entity = NSEntityDescription.entity(forEntityName: "Card", in: context)
    
    static let okAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!)in })
    static let settingsAlertAction: UIAlertAction = UIAlertAction(title: "Settings", style: .default, handler: { (action: UIAlertAction!) in
        UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
    })
    static let cancelAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (ACTION :UIAlertAction!) in })
    
    static let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
    
    struct Storyboards {
        static let launchStoryboard = UIStoryboard(name: "Main", bundle: nil)
        static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        static let cardDetailStoryboard = UIStoryboard(name: "CardDetail", bundle: nil)
        static let tradeIdeaStoryboard = UIStoryboard(name: "TradeIdea", bundle: nil)
        static let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        static let loginStoryboard = UIStoryboard(name: "Login", bundle: nil)
        static let feedbackStoryboard = UIStoryboard(name: "Feedback", bundle: nil)
    }
    
    struct SSFonts {
        static let standard = UIFont(name: "HelveticaNeue", size: 15)!
        static let small = UIFont(name: "HelveticaNeue", size: 12)!
        static let medium = UIFont(name: "HelveticaNeue", size: 20)!
        static let large = UIFont(name: "HelveticaNeue", size: 25)!
        static let xl = UIFont(name: "HelveticaNeue", size: 45)!
        
        static func makeFont(size: CGFloat) -> UIFont {
            return UIFont(name: "HelveticaNeue", size: size)!
        }
    }
    
    struct SSColors {
        static let grey: UIColor = UIColor(named: "grey")!
        static let lightGrey: UIColor = UIColor(named: "lightGrey")!
        static let green: UIColor = UIColor(named: "green")!
        static let greenGradientStart: UIColor = UIColor(named: "greenGradientStart")!
        static let greenGradientEnd: UIColor = UIColor(named: "greenGradientEnd")!
        static let red: UIColor = UIColor(named: "red")!
        static let gold: UIColor = UIColor(named: "gold")!
    }
    
    enum APIKeys: String {
        case Parse
        case TwitterKit
        case LaunchKit
        case ChimpKit
        case EodHistorcalData
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
            case .ChimpKit:
                return "549c43655bcc48fb60af6a1c24e77495-us12"
            case .EodHistorcalData:
                return "5c5b6db11b85d5.07117487"
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
        
        static let allAPIKeys = [Parse, TwitterKit, LaunchKit, ChimpKit, EodHistorcalData, TradeItDev, TradeItProd]
    }
    
    enum UserChoices: String {
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
        case AddToWatchlistLong = "addToWatchlistLong"
        case AddToWatchlistShort = "addToWatchlistShort"
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
    
    struct Symbol {
        
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
    
    enum CacheKey {
        case Carousel
        case Cloud
        case TopStories
        case UserAvatar(objectId: String)
        
        public func key() -> String {
            switch self {
            case .Carousel:
                return "CAROUSELCACHEDATA"
            case .Cloud:
                return "TRENDINGSTOCKSCACHEDATA"
            case .TopStories:
                return "TOPSTORIESCACHEDATA"
            case .UserAvatar(let objectId):
                return "USERAVATARCACHE_" + objectId
            }
        }
    }
    
    static let cardHighlightedFactor: CGFloat = 0.95
    static let cardCornerRadius: CGFloat = 15
    static let dismissalAnimationDuration = 0.60

    enum CardVerticalExpandingStyle {
        /// Expanding card pinning at the top of animatingContainerView
        case fromTop
        
        /// Expanding card pinning at the center of animatingContainerView
        case fromCenter
    }
    
    static let cardVerticalExpandingStyle: CardVerticalExpandingStyle = .fromTop
    
    /// Without this, there'll be weird offset (probably from scrollView) that obscures the card content view of the cardDetailView.
    static let isEnabledWeirdTopInsetsFix = true
    
    /// If true, will draw borders on animating views.
    static let isEnabledDebugAnimatingViews = false
    
    /// If true, this will add a 'reverse' additional top safe area insets to make the final top safe area insets zero.
    static let isEnabledTopSafeAreaInsetsFixOnCardDetailViewController = false
    
    /// If true, will always allow user to scroll while it's animated.
    static let isEnabledAllowsUserInteractionWhileHighlightingCard = true
}
