//
//  Funtions.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-03-28.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import Foundation
import CoreData
import CoreSpotlight
import MobileCoreServices
import SystemConfiguration
import SDVersion
import Parse
import Crashlytics
import SafariServices
import SwiftyJSON
import AMPopTip
import Reachability
import NotificationBannerSwift

class Functions {
    
    class func isConnectedToNetwork() -> Bool {
        if Reachability()?.isReachable == true {
            return true
        } else {
            showNotificationBanner(title: "No Internet Connection", subtitle: "Make sure your device is connected to the internet", style: .warning)
            return false
        }
    }
    
    class func isUserLoggedIn(presenting viewController: UIViewController) -> Bool {
        
        guard PFUser.current() == nil else { return true }
        
        DispatchQueue.main.async {
            
            SweetAlert().showAlert("Login Required!", subTitle: "Please login to continue", style: AlertStyle.warning, dismissTime: nil, buttonTitle: "Ok", buttonColor: UIColor(rgbValue: 0xD0D0D0)) { (isOtherButton) -> Void in
                
                if isOtherButton {
                    let logInViewcontroller = LoginViewController.sharedInstance
                    logInViewcontroller.logIn(viewController)
                    logInViewcontroller.loginDelegate = viewController as? LoginDelegate
                }
            }
        }
        
        return false
    }
    
    class func setCardsSize() {
        
        switch UIDevice.current.userInterfaceIdiom {
            
        case .pad:
            
            cardWidth = UIScreen.main.bounds.width - 60
            cardHeight = cardWidth
            
            numberOfCellsHorizontally = 2
            numberOfCellsVertically = 2
            
        default:
            
            cardWidth = UIScreen.main.bounds.width - 30
            cardHeight = cardWidth * 1.3
            numberOfCellsHorizontally = 1
            
            switch SDiOSVersion.deviceSize() {
            case .Screen5Dot8inch, .Screen5Dot5inch, .Screen4Dot7inch:
                numberOfCellsVertically = 3
            default:
                numberOfCellsVertically = 2
            }
        }
    }
    
    class func setChartURL(_ symbol: String) -> URL {
        
        let formattedSymbol = symbol.URLEncodedString()!
        if UIDevice.current.userInterfaceIdiom == .pad {
            return URL(string: "http://45.55.137.153/?symbol=\(formattedSymbol)&interval=D")!
        } else {
            return URL(string: "http://45.55.137.153/mobile_white.html?symbol=\(formattedSymbol)&interval=D")!
        }
    }
    
    class func fetchParseObjectAndEODData(for symbol: String, completion: @escaping (_ result: () throws -> (parseObject: PFObject, eodHistoricalResult: [QueryHelper.EODHistoricalResult], eodFundamentalsResult: QueryHelper.EODFundamentalsResult)) -> Void) -> Void {
        
        self.getParseObject(symbol) { object in
            do {
                
                guard let object = try object() else { throw QueryHelper.QueryError.objectDoesntExists }
                
                QueryHelper.sharedInstance.queryEODHistorical(for: symbol) { eodHistoricalResult in
                    do {
                        let eodHistoricalResult = try eodHistoricalResult()
                        
                        QueryHelper.sharedInstance.queryEODFundamentals(for: symbol, completionHandler: { eodFundamentalsResult in
                            
                            do {
                                let eodFundamentalsResult = try eodFundamentalsResult()
                                completion( { (object, eodHistoricalResult, eodFundamentalsResult) })
                            } catch {
                                completion({throw error})
                            }
                        })
                        
                    } catch {
                        completion({throw error})
                    }
                }
            } catch {
                completion({throw error})
            }
        }
    }
    
    class func fetchEODData(for symbol: String, completion: @escaping (_ result: () throws -> (eodHistoricalResult: [QueryHelper.EODHistoricalResult], eodFundamentalsResult: QueryHelper.EODFundamentalsResult)) -> Void) -> Void {
        
        QueryHelper.sharedInstance.queryEODHistorical(for: symbol) { eodHistoricalResult in
            do {
                let eodHistoricalResult = try eodHistoricalResult()
                
                QueryHelper.sharedInstance.queryEODFundamentals(for: symbol, completionHandler: { eodFundamentalsResult in
                    
                    do {
                        let eodFundamentalsResult = try eodFundamentalsResult()
                        completion( { (eodHistoricalResult, eodFundamentalsResult) })
                    } catch {
                        completion({throw error})
                    }
                })
                
            } catch {
                completion({throw error})
            }
        }
    }
    
    class func makeCard(for symbol: String, userChoice: Constants.UserChoices? = nil, completion: @escaping (_ result: () throws -> Card) -> Void) -> Void {
        
        self.fetchParseObjectAndEODData(for: symbol) { result in
            do {
                
                let result = try result()
                
                let card = Card(parseObject: result.parseObject as! Stock, eodHistoricalData: result.eodHistoricalResult, eodFundamentalsData: result.eodFundamentalsResult, userChoice: userChoice)
                
                completion({ card })
                
            } catch {
                completion({throw error})
            }
        }
    }
    
    class func makeCardsFromCoreData(symbols: [String]? = nil, completion: @escaping (_ result: () throws -> [Card]) -> Void) -> Void {
        
        do {
            
            let cardModels = try fetchFromCoreData(symbols: symbols)
            var cards = [Card]()
            for (index, cardModel) in cardModels.enumerated() {
                self.makeCard(for: cardModel.symbol, userChoice: Constants.UserChoices(rawValue: cardModel.userChoice)) { card in
                    do {
                        let card = try card()
                        cards.append(card)
                    } catch {
                        print("error", error.localizedDescription)
                    }
                    
                    // TODO: this isn't a good implementation, needs rework
                    if index == cardModels.count - 1 {
                        completion({ cards })
                    }
                }
            }
            
        } catch {
            completion({ throw error })
        }
    }
    
    class func createParseObject(for symbol: String, completion: @escaping (_ result: () throws -> PFObject) -> Void) -> Void {
        
        self.getParseObject(symbol) { object in
            do {
                
                guard try object() == nil else { throw QueryHelper.QueryError.parseObjectAlreadyExists }
                
                QueryHelper.sharedInstance.queryEODFundamentals(for: symbol) { eodFundamentalsResult in
                    
                    do {
                        let eodFundamentalsResult = try eodFundamentalsResult()
                        let parseObject = Stock()
                        parseObject["Symbol"] = symbol
                        parseObject["Company"] = eodFundamentalsResult.general.name ?? ""
                        parseObject["Exchange"] = eodFundamentalsResult.general.exchange ?? ""
                        parseObject["Sector"] = eodFundamentalsResult.general.sector ?? "Other"
                        let newACL = PFACL()
                        newACL.hasPublicReadAccess = true
                        newACL.hasPublicWriteAccess = false
                        parseObject.acl = newACL
                        parseObject.saveInBackground()
                        
                        completion( { parseObject })
                    } catch {
                        completion({throw error})
                    }
                }
            } catch {
                completion({throw error})
            }
        }
    }
    
    class func getParseObject(_ symbol: String, completion: @escaping (_ result: () throws -> PFObject?) -> Void) -> Void {
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [symbol]) { (result) in
            
            do {
                let parseObject = try result().first
                completion({ parseObject })
                
            } catch {
                completion({throw error})
            }
        }
    }
    
    class func blockUser(_ user: PFUser, postAlert: Bool) {
        
        guard let currentUser = PFUser.current() else { return }
        if currentUser.object(forKey: "blocked_users") != nil {
            currentUser.addUniqueObject(user, forKey: "blocked_users")
        } else {
            currentUser.setObject([user], forKey: "blocked_users")
        }
        
        currentUser.saveEventually { (success, error) in
            
            if success {
                
                if postAlert == true {
                    
                    DispatchQueue.main.async {
                        Functions.showNotificationBanner(title: "Blocked", subtitle: "", style: .success)
                    }
                }
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: user, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        //TODO: handle error
                    }
                })
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: user, toUser: currentUser, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        //TODO: handle error
                    }
                })
                
            } else {
                DispatchQueue.main.async {
                    Functions.showNotificationBanner(title: nil, subtitle: error?.localizedDescription, style: .warning)
                }
            }
        }
    }
    
    class func registerUserChoice(_ card: Card, with choice: Constants.UserChoices) {
        
        guard let currentUser = PFUser.current() else { return }
        guard let parseObject = card.parseObject else {
            Functions.showNotificationBanner(title: "Stock Unknown", subtitle: "We couldn't find this symbol in our database", style: .warning)
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: [parseObject], activityType: [Constants.ActivityType.StockLong.rawValue, Constants.ActivityType.StockShort.rawValue], skip: nil, limit: 1, includeKeys: nil) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                if let firstActivityObject = activityObjects.first {
                    
                    let firstActivityObjectActivityType = firstActivityObject["activityType"] as! String
                    if (firstActivityObjectActivityType == Constants.ActivityType.StockLong.rawValue &&  choice == .LONG) || (firstActivityObjectActivityType == Constants.ActivityType.StockShort.rawValue &&  choice == .SHORT) {
                        
                        firstActivityObject["activityType"] = firstActivityObject["activityType"]
                        firstActivityObject.saveEventually()
                        
                    } else {
                        
                        switch choice {
                            
                        case .LONG:
                            
                            firstActivityObject["activityType"] = Constants.ActivityType.StockLong.rawValue
                            
                            if card.shortCount > 0 {
                                card.shortCount -= 1
                            }
                            card.longCount += 1
                            
                        case .SHORT:
                            
                            firstActivityObject["activityType"] = Constants.ActivityType.StockShort.rawValue
                            
                            if card.longCount > 0 {
                                card.longCount -= 1
                            }
                            card.shortCount += 1
                            
                        default:
                            break
                        }
                        firstActivityObject.saveEventually()
                    }
                    
                } else if activityObjects.isEmpty {
                    
                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["stock"] = parseObject
                    
                    switch choice {
                        
                    case .LONG:
                        
                        activityObject["activityType"] = Constants.ActivityType.StockLong.rawValue
                        card.longCount += 1
                        
                    case .SHORT:
                        
                        activityObject["activityType"] = Constants.ActivityType.StockShort.rawValue
                        card.shortCount += 1
                        
                    default:
                        break
                    }
                    
                    activityObject.saveEventually()
                }
                
                // Update Spotlight
                self.addToSpotlight(card, domainIdentifier: "com.stockswipe.stocksQueried")
                
            } catch {
                //TODO: handle error
            }
            
            print("registerUserChoice", card)
        }
    }
    
    class func registerAddToWatchlist(_ card: Card, with choice: Constants.UserChoices) {
        
        guard let currentUser = PFUser.current() else { return }
        guard let parseObject = card.parseObject else {
            Functions.showNotificationBanner(title: "Stock Unknown", subtitle: "We couldn't find this symbol in our database", style: .warning)
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: [parseObject], activityType: [Constants.ActivityType.AddToWatchlistLong.rawValue, Constants.ActivityType.AddToWatchlistShort.rawValue], skip: nil, limit: 1, includeKeys: nil) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                if let firstActivityObject = activityObjects.first {
                    
                    switch choice {
                    case .LONG:
                        firstActivityObject["activityType"] = Constants.ActivityType.AddToWatchlistLong.rawValue
                        card.userChoice = .LONG
                    case .SHORT:
                        firstActivityObject["activityType"] = Constants.ActivityType.AddToWatchlistShort.rawValue
                        card.userChoice = .SHORT
                    default:
                        break
                    }
                    
                    firstActivityObject.saveEventually { (success, error) in
                        if success {
                            NotificationCenter.default.post(name: Notification.Name("AddToWatchlist"), object: nil, userInfo: ["card": card])
                        }
                        print("registerAddToWatchlist", card)
                    }
                    
                } else if activityObjects.isEmpty {
                    
                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["stock"] = parseObject
                    
                    switch choice {
                    case .LONG:
                        activityObject["activityType"] = Constants.ActivityType.AddToWatchlistLong.rawValue
                        card.userChoice = .LONG
                    case .SHORT:
                        activityObject["activityType"] = Constants.ActivityType.AddToWatchlistShort.rawValue
                        card.userChoice = .SHORT
                    default:
                        break
                    }
                    
                    activityObject.saveEventually { (success, error) in
                        if success {
                            NotificationCenter.default.post(name: Notification.Name("AddToWatchlist"), object: nil, userInfo: ["card": card])
                        }
                        print("registerAddToWatchlist", card)
                    }
                }
                
            } catch {
                //TODO: handle error
            }
            
        }
    }
    
    class func fetchFromCoreData(symbols: [String]?) throws -> [CardModel] {
    
        let chartFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Card")
        if let symbols = symbols {
            chartFetchRequest.predicate = NSPredicate(format: "symbol = %@", argumentArray: symbols)
        }
        chartFetchRequest.returnsObjectsAsFaults = false
        
        do {
            return try Constants.context.fetch(chartFetchRequest) as! [CardModel]
        } catch {
            throw error
        }
    }
    
    class func saveIntoCoreData(_ card: Card, userChoice: Constants.UserChoices) {
        
        do {
            
            let fetchedObjects = try fetchFromCoreData(symbols: [card.symbol])
            
            if fetchedObjects.count == 0 {
                let newChart = CardModel(entity: Constants.entity!, insertInto: Constants.context)
                newChart.symbol = card.symbol
                newChart.companyName = card.companyName
                if let eodHistoricalData = card.eodHistoricalData, let encodedData = try? QueryHelper.EODHistoricalResult.encodeFrom(eodHistoricalResults: eodHistoricalData) {
                    newChart.eodHistoricalData = encodedData
                }
                if let eodFundamentalsData = card.eodFundamentalsData, let encodedData = try? QueryHelper.EODFundamentalsResult.encodeFrom(eodFundamentalsResult: eodFundamentalsData) {
                    newChart.eodFundamentalsData = encodedData
                }
                newChart.shorts = Int32(card.shortCount)
                newChart.longs = Int32(card.longCount)
                newChart.userChoice = userChoice.rawValue
                newChart.dateChoosen = Date()
                
            } else if fetchedObjects.count > 0 {
                let fetchedObject: NSManagedObject = fetchedObjects.first!
                fetchedObject.setValue(card.symbol, forKey: "symbol")
                fetchedObject.setValue(card.companyName, forKey: "companyName")
                if card.eodHistoricalData != nil, let eodHistoricalData = try? QueryHelper.EODHistoricalResult.encodeFrom(eodHistoricalResults: card.eodHistoricalData!) {
                    fetchedObject.setValue(eodHistoricalData, forKey: "eodHistoricalData")
                }
                if card.eodFundamentalsData != nil, let eodFundamentalsData = try? QueryHelper.EODFundamentalsResult.encodeFrom(eodFundamentalsResult: card.eodFundamentalsData!) {
                    fetchedObject.setValue(eodFundamentalsData, forKey: "eodFundamentalsData")
                }
                fetchedObject.setValue(card.shortCount, forKey: "shorts")
                fetchedObject.setValue(card.longCount, forKey: "longs")
                fetchedObject.setValue(userChoice.rawValue, forKey: "userChoice")
                fetchedObject.setValue(Date(), forKey: "dateChoosen")
            }
            
            do {
                try Constants.context.save()
            } catch let error as NSError {
                print("Fetch failed: \(error.localizedDescription)")
                abort()
            }
            
        } catch let error as NSError {
            //TODO: handle error
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
    
    class func setupConfigParameter(_ parameter:String, completion: @escaping (_ parameterValue: Any?) -> Void) {
        
        PFConfig.getInBackground { (config, error) in
            let configParameter = config?[parameter]
            completion(configParameter)
        }
    }
    
    @available(iOS 9.0, *)
    class func createNSUserActivity(_ card: Card, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.contentDescription = card.companyName
        attributeSet.artist = "Shorts: \(card.shortCount)"
        attributeSet.album = "Longs: \(card.longCount)"
        attributeSet.relatedUniqueIdentifier = card.symbol
        
        let activity = NSUserActivity(activityType: domainIdentifier)
        activity.title = card.symbol
        activity.keywords = NSSet(array: [card.symbol, card.companyName, "Stocks", "Markets"]) as! Set<String>
        activity.userInfo = ["symbol": card.symbol, "companyName": card.companyName]
        activity.contentAttributeSet = attributeSet
        
        activity.requiredUserInfoKeys = NSSet(array: ["symbol", "companyName"]) as? Set<String>
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        nsUserActivityArray.append(activity)
        activity.becomeCurrent()
        
        print("NSUserActivity created")
    }
    
    class func addToSpotlight(_ card: Card, domainIdentifier: String) {
        
        let attributeSet: CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeMP3 as String)
        attributeSet.title = card.symbol
        attributeSet.contentDescription = card.companyName
        attributeSet.artist = "Shorts: \(card.shortCount)"
        attributeSet.album = "Longs: \(card.longCount)"
        attributeSet.keywords = [card.symbol, card.companyName ?? "", "Stocks", "Markets"]
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: card.symbol, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("\(card.symbol) successfully indexed")
            }
        }
        
    }
    
    class func removeFromSpotlight(_ domainIdentifier: String) {
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [domainIdentifier]) { (error: Error?) -> Void in
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully removed")
            }
        }
    }
    
    class func promptAddToWatchlist(_ card: Card, registerChoice: Bool, completion: @escaping (Constants.UserChoices) -> Void)  {
        
        guard Functions.isConnectedToNetwork() else {
            Functions.showNotificationBanner(title: "Can't Add To Watchlist!", subtitle: "Make sure your device is connected\nto the internet", style: .warning)
            return
        }
        
        
        DispatchQueue.main.async {
            
            SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.customImag(imageFile: "add_watchlist"), dismissTime: nil, buttonTitle: "SHORT", buttonColor: UIColor.red , otherButtonTitle: "LONG", otherButtonColor: Constants.SSColors.green) { (isOtherButton) -> Void in
                
                guard let topVC = UIApplication.topViewController(), Functions.isUserLoggedIn(presenting: topVC) else { return }
                
                if !isOtherButton {
                    
                    if registerChoice {
                        registerUserChoice(card, with: .LONG)
                    }
                    
                    registerAddToWatchlist(card, with: .LONG)
                    
                    completion(.LONG)
                    
                } else if isOtherButton {
                    
                    if registerChoice {
                        registerUserChoice(card, with: .SHORT)
                    }
                    
                    registerAddToWatchlist(card, with: .SHORT)
                    
                    completion(.SHORT)
                }
            }
        }
    }
    
    class func showNotificationBanner(title: String?, subtitle: String?, style: BannerStyle) {
        class CustomBannerColors: BannerColorsProtocol {
            
            internal func color(for style: BannerStyle) -> UIColor {
                switch style {
                case .danger:
                    return Constants.SSColors.red
                case .info:
                    return Constants.SSColors.grey
                case .none:
                    return UIColor.clear
                case .success:
                    return Constants.SSColors.green
                case .warning:
                    return Constants.SSColors.gold
                }
            }
            
        }
        let banner = NotificationBanner(title: title, subtitle: subtitle, style: style, colors: CustomBannerColors())
        banner.show()
    }
    
    class func showPopTipOnceForKey(_ key: String, userDefaults: UserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: PopTipDirection = .down, color: UIColor = .darkGray) -> PopTip? {
        if (!userDefaults.bool(forKey: key)) {
            userDefaults.set(true, forKey: key)
            userDefaults.synchronize()
            showPopTip(popTipText: text, inView: view, fromFrame: frame, direction:  direction, color: color)
        }
        
        return nil
    }
    
    class func showPopTip(popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: PopTipDirection, color: UIColor, duration: TimeInterval = 3) -> PopTip? {
        
        let popTip = PopTip()
        popTip.font = Constants.SSFonts.makeFont(size:16)
        popTip.textColor = .white
        popTip.bubbleColor = color
        popTip.offset = 10
        popTip.edgeMargin = 5
        popTip.actionAnimation = PopTipActionAnimation.bounce(8)
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.show(text: text, direction: direction, maxWidth: 300, in: view, from: frame, duration: duration)
        
        return popTip
    }
    
    class func dismissAllPopTips(_ allPopTips: [PopTip?]) {
        
        if !allPopTips.isEmpty {
            
            for tip in allPopTips {
                tip?.hide()
            }
        }
    }
    
    class func displayAlert (_ title: String, message: String, Action1: UIAlertAction?, Action2: UIAlertAction?) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        if Action1 != nil {
            alert.addAction(Action1!)
        }
        
        if Action2 != nil {
            alert.addAction(Action2!)
        }
        
        return alert
    }
    
    class func markFeedbackGiven() {
        Constants.userDefaults.set(true, forKey: "FEEDBACK_GIVEN")
        Constants.userDefaults.synchronize()
        
        // log rating event
        Answers.logRating(nil,
                          contentName: "StockSwipe Rated",
                          contentType: "Rate",
                          contentId: nil,
                          customAttributes: ["User": PFUser.current()?.username ?? "N/A", "Country Code": Constants.countryCode, "App Version": Constants.AppVersion])
    }
    
    class func sendPush(_ pushType: Constants.PushType, parameters: [String:String]) {
        PFCloud.callFunction(inBackground: pushType.rawValue, withParameters: parameters) { (results, error) -> Void in
        }
    }
    
    class func getCenterOfView(_ view: UIView) -> CGPoint {
        let bounds:CGRect = view.bounds
        let centerOfView:CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        return centerOfView
    }
    
    class func presentActivityVC(_ textToShare: String?, imageToShare: UIImage?, url: URL?, sender: AnyObject, vc: UIViewController, completion:@escaping (_ activity: String?, _ success:Bool, _ items:[AnyObject]?, _ error:NSError?) -> Void) {
        
        var objectsToShare = [AnyObject]()
        
        if textToShare != nil {
            objectsToShare.append(textToShare! as AnyObject)
        }
        
        if imageToShare != nil {
            objectsToShare.append(imageToShare!)
        }
        
        if url != nil {
            objectsToShare.append(url! as AnyObject)
        }
        
        guard objectsToShare.count != 0 else {
            Functions.showNotificationBanner(title: "Error!", subtitle: "Something went wrong", style: .danger)
            return completion(nil, false, nil, nil)
        }
        
        let excludedActivityTypesArray = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.airDrop,
            ]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedActivityTypesArray
        
        activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        activityVC.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        vc.present(activityVC, animated: true, completion: nil)
        
        activityVC.completionWithItemsHandler = { (activity, success, items, error) in
            print("Activity: \(activity) Success: \(success) Items: \(items) Error: \(error)")
            completion(activity.map { $0.rawValue }, success, items as [AnyObject]?, error as NSError?)
        }
    }
    
    class func presentSafariBrowser(with url: URL!, readerMode: Bool = true) {
        guard Functions.isConnectedToNetwork() else {
            Functions.showNotificationBanner(title: "Can't Open Url!", subtitle: "Make sure your device is connected\nto the internet", style: .warning)
            return
        }
        
        // override reader mode for medium stories (for some reason opens a blank white page)
        let readerMode: Bool = url.absoluteString.contains("medium") ? false : readerMode
        let svc = SFSafariViewController(url: url, entersReaderIfAvailable: readerMode)
        svc.modalTransitionStyle = .coverVertical
        svc.modalPresentationStyle = .overFullScreen
        if #available(iOS 10.0, *) {
            svc.preferredControlTintColor = Constants.SSColors.green
        } else {
            svc.view.tintColor = Constants.SSColors.green
        }
        
        UIApplication.topViewController()?.present(svc, animated: true, completion: nil)
    }
    
    // Random number between low and high range
    //    class func randomInRange (low: Int, high: Int) -> Int {
    //
    //        var RandomNumber = Int(arc4random_uniform(UInt32(high)))
    //        RandomNumber = max(RandomNumber, low)
    //        RandomNumber = min(RandomNumber, high - low)
    //
    //        return RandomNumber
    //    }
}
