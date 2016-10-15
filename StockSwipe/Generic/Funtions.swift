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
import SafariServices
import SwiftyJSON
import AMPopTip
import NVActivityIndicatorView

class Functions {
    
    class func isConnectedToNetwork() -> Bool {
        if Constants.reachability?.currentReachabilityStatus == .notReachable {
            return false
        } else {
            return true
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
                        SweetAlert().showAlert("Blocked", subTitle: "", style: AlertStyle.success)
                    }
                }
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: user, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: user, toUser: currentUser, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
            } else {
                DispatchQueue.main.async {
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                }
            }
        }
    }
    
    class func checkDevice() {
        
        switch UIDevice.current.userInterfaceIdiom {
            
        case .pad:
            
            if SDiOSVersion.deviceVersion() == .iPadPro12Dot9Inch || SDiOSVersion.deviceVersion() == .iPadPro9Dot7Inch {
                
                chartWidth = 1200
                chartHeight = (chartWidth * 0.60) + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
            } else {
                
                chartWidth = 900
                chartHeight = (chartWidth * 0.60) + (Constants.chartImageTopPadding + Constants.informationViewHeight)
            }
            
            frontCardOffsetFromCenter = 20
            
            horizontalPadding = 50.0
            verticalPadding = -10.0
            
            numberOfCellsHorizontally = 2
            numberOfCellsVertically = 2
            
        default:
            
            switch SDiOSVersion.deviceSize() {
                
            case .Screen5Dot5inch:
                
                chartWidth = 390
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 3
                frontCardOffsetFromCenter = -10
                
                verticalPadding = -25.0
                
            case .Screen4Dot7inch:
                
                chartWidth = 350
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 3
                
                frontCardOffsetFromCenter = -10
                
                verticalPadding = -20.0
                
            case .Screen4inch:
                
                chartWidth = 300
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0
                
                verticalPadding = -10.0
                
            case .Screen3Dot5inch:
                
                chartWidth = 280
                chartHeight = chartWidth
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0
                
                verticalPadding = 0.0
                
            default:
                
                chartWidth = 300
                chartHeight = chartWidth
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0
                
                verticalPadding = 0.0
            }
            
            horizontalPadding = 10.0
            
            numberOfCellsHorizontally = 1
        }
    }
    
    class func setImageURL(_ symbol: String) -> URL? {
        
        let URL: Foundation.URL?
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            URL = Foundation.URL(string: "http://45.55.137.153/images/symbol_" + symbol + "_interval_D.png")
            
        } else {
            
            URL = Foundation.URL(string: "http://45.55.137.153/images/symbol_" + symbol + "_interval_D_phone.png")
        }
        
        return URL
    }
    
    class func setChartURL(_ symbol: String) -> URL {
        
        let formattedSymbol = symbol.URLEncodedString()!
        
        let URL: Foundation.URL!
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            URL = Foundation.URL(string: "http://45.55.137.153/?symbol=\(formattedSymbol)&interval=D")
            
        } else {
            
            URL = Foundation.URL(string: "http://45.55.137.153/mobile_white.html?symbol=\(formattedSymbol)&interval=D")
        }
        
        return URL
    }
    
    class func getImage(_ imageURL: URL?, completion: @escaping (UIImage?) -> Void) {
        
        guard let imageURL = imageURL else { return completion(nil) }
        
        QueryHelper.sharedInstance.queryWith(queryString: imageURL.absoluteString, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                completion(UIImage(data: avatarData))
                
            } catch {
                // TODO: Handle error
            }
        })
    }
    
    class func getStockObjectAndChart(_ symbol: String, completion: @escaping (_ result: () throws -> (object: PFObject, chart: Chart)) -> Void) {
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [symbol]) { (result) in
            
            do {
                
                let stockObject = try result().first!
                
                QueryHelper.sharedInstance.queryChartImage(symbol: symbol, completion: { (result) in
                    
                    do {
                        
                        let chart = Chart(parseObject: stockObject)
                        completion({ (object: stockObject, chart: chart)})
                        
                    } catch {
                        
                        completion({throw error})
                        
                    }
                    
                })
                
            } catch {
                
                completion({throw error})
                
            }
        }
    }
    
    class func registerUserChoice(_ chart: Chart, with choice: Constants.UserChoices) {
        
        guard let currentUser = PFUser.current() else { return }
        guard let parseObject = chart.parseObject else {
            SweetAlert().showAlert("Stock Unknown", subTitle: "We couldn't find this symbol in our database", style: AlertStyle.warning)
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [parseObject], activityType: [Constants.ActivityType.StockLong.rawValue, Constants.ActivityType.StockShort.rawValue], skip: nil, limit: nil, includeKeys: nil) { (result) in
            
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
                            
                            if chart.shortCount > 1 {
                                chart.shortCount -= 1
                            }
                            chart.longCount += 1
                            
                        case .SHORT:
                            
                            firstActivityObject["activityType"] = Constants.ActivityType.StockShort.rawValue
                            
                            if chart.longCount > 1 {
                                chart.longCount -= 1
                            }
                            chart.shortCount += 1
                            
                        default:
                            break
                        }
                        firstActivityObject.saveEventually()
                    }
                    
                } else if activityObjects.isEmpty {
                    
                    let activityObject = PFObject(className: "Activity")
                    activityObject["fromUser"] = currentUser
                    activityObject["stock"] = parseObject
                    
                    switch choice {
                        
                    case .LONG:
                        
                        activityObject["activityType"] = Constants.ActivityType.StockLong.rawValue
                        chart.longCount += 1
                        
                    case .SHORT:
                        
                        activityObject["activityType"] = Constants.ActivityType.StockShort.rawValue
                        chart.shortCount += 1
                        
                    default:
                        break
                    }
                    
                    activityObject.saveEventually()
                }
                
                // Update Spotlight
                self.addToSpotlight(chart, domainIdentifier: "com.stockswipe.stocksQueried")
                
            } catch {
                
            }
            
            print("\(choice)", chart)
        }
    }
    
    class func saveIntoCoreData(_ chart: Chart, userChoice: Constants.UserChoices) {

        let chartFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Charts")
        chartFetchRequest.predicate = NSPredicate(format: "symbol == %@", chart.symbol)
        chartFetchRequest.fetchLimit = 1
        chartFetchRequest.returnsObjectsAsFaults = false
        
        do {
            
            let fetchedObjectArray:[ChartModel] = try Constants.context.fetch(chartFetchRequest) as! [ChartModel]
            
            if fetchedObjectArray.count == 0 {
                
                print("no object exists in core data")
                
                let newChart = ChartModel(entity: Constants.entity!, insertInto: Constants.context)
                newChart.symbol = chart.symbol
                newChart.companyName = chart.companyName
                newChart.image = UIImagePNGRepresentation(chart.image)
                newChart.shorts = Int32(chart.shortCount)
                newChart.longs = Int32(chart.longCount)
                newChart.userChoice = userChoice.rawValue
                newChart.dateChoosen = Date()
                
            } else if fetchedObjectArray.count > 0 {
                
                print("atleast one core data object exists")
                
                let fetchedObject:NSManagedObject = fetchedObjectArray.first!
                
                fetchedObject.setValue(chart.symbol, forKey: "symbol")
                fetchedObject.setValue(UIImagePNGRepresentation(chart.image), forKey: "image")
                fetchedObject.setValue(chart.shortCount, forKey: "shorts")
                fetchedObject.setValue(chart.longCount, forKey: "longs")
                fetchedObject.setValue(userChoice.rawValue, forKey: "userChoice")
                fetchedObject.setValue(Date(), forKey: "dateChoosen")
            }
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        do {
            
            try Constants.context.save()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
    }
    
    class func getChartsFromCoreData() -> [ChartModel]? {
        
        let chartFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Charts")
        chartFetchRequest.entity = Constants.entity
        
        let sort = NSSortDescriptor(key: "dateChoosen", ascending: false)
        let sortDescriptors = [sort]
        
        chartFetchRequest.sortDescriptors = sortDescriptors
        
        do {
            
            let results = try Constants.context.fetch(chartFetchRequest)
            
            //println(results)
            return results as? [ChartModel]
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    class func makeTradeIdeas(from tradeIdeaObjects: [PFObject], sorted: Bool, completion: @escaping ([TradeIdea]) -> Void) {
        
        //let queue = DispatchQueue(label: "Trade Idea Query Queue")
        
        var tradeIdeas = [TradeIdea]()
        for tradeIdeaObject in tradeIdeaObjects {
            
            //queue.async {
                
                TradeIdea(parseObject: tradeIdeaObject, completion: { (tradeIdea) in
                    
                    if let tradeIdea = tradeIdea {
                        
                        tradeIdeas.append(tradeIdea)
                        
                        if tradeIdeas.count == tradeIdeaObjects.count {
                            if sorted {
                                tradeIdeas.sort { $0.createdAt > $1.createdAt }
                            }
                            
                            completion(tradeIdeas)
                        }
                    }
                })
            //}
        }
    }
    
    class func makeUser(from userObjects: [PFUser], completion: @escaping ([User]) -> Void) {
        
        //let queue = DispatchQueue(label: "Users Query Queue")
        
        var users = [User]()
        for userObject in userObjects {
            
            //queue.async {
                
                User(userObject: userObject, completion: { (user) in
                    
                    if let user = user {
                        
                        users.append(user)
                        
                        if users.count == userObjects.count {
                            completion(users)
                        }
                    }
                })
            //}
        }
    }
    
    class func makeTickers(from symbolQuote: Data, completion: @escaping ([Ticker]) -> Void) {
        
        var tickers = [Ticker]()
        
        let carsouelJson = JSON(data: symbolQuote)
        let carsouelJsonResults = carsouelJson["query"]["results"]
        guard let quoteJsonResultsQuote = carsouelJsonResults["quote"].array else { return }
        
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
        
        completion(tickers)
    }
    
    class func setupConfigParameter(_ parameter:String, completion: @escaping (_ parameterValue: Any?) -> Void) {
        
        PFConfig.getInBackground { (config, error) in
            let configParameter = config?[parameter]
            completion(configParameter)
        }
    }
    
    @available(iOS 9.0, *)
    class func createNSUserActivity(_ chart: Chart, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.contentDescription = chart.companyName
        attributeSet.artist = "Shorts: \(chart.shortCount)"
        attributeSet.album = "Longs: \(chart.longCount)"
        attributeSet.relatedUniqueIdentifier = chart.symbol
        
        let activity = NSUserActivity(activityType: domainIdentifier)
        activity.title = chart.symbol
        activity.keywords = NSSet(array: [chart.symbol, chart.companyName, chart.searchDescription, "Stocks", "Markets"]) as! Set<String>
        activity.userInfo = ["symbol": chart.symbol, "companyName": chart.companyName]
        activity.contentAttributeSet = attributeSet
        
        activity.requiredUserInfoKeys = NSSet(array: ["symbol", "companyName"]) as! Set<String>
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        nsUserActivityArray.append(activity)
        activity.becomeCurrent()
        
        print("NSUserActivity created")
    }
    
    class func addToSpotlight(_ chart: Chart, domainIdentifier: String) {
        
        let attributeSet: CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeMP3 as String)
        attributeSet.title = chart.symbol
        attributeSet.contentDescription = chart.companyName
        attributeSet.artist = "Shorts: \(chart.shortCount)"
        attributeSet.album = "Longs: \(chart.longCount)"
        attributeSet.keywords = [chart.symbol, chart.companyName, "Stocks", "Markets"]
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: chart.symbol, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("\(chart.symbol) successfully indexed")
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
    
    class func addToWatchlist(_ chart: Chart, registerChoice: Bool, completion: @escaping (Constants.UserChoices) -> Void)  {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        QueryHelper.sharedInstance.queryChartImage(symbol: chart.symbol, completion: { (result) in
            
            do {
                
                let chartImage = try result()
                
                chart.image = chartImage
                
                
            } catch {
                
                print(error)
            }
            
            DispatchQueue.main.async {
                
                SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.customImag(imageFile: "add_watchlist"), dismissTime: nil, buttonTitle:"SHORT", buttonColor:UIColor.red , otherButtonTitle: "LONG", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    guard let topVC = UIApplication.topViewController(), Functions.isUserLoggedIn(presenting: topVC) else { return }
                    
                    if !isOtherButton {
                        
                        if registerChoice {
                            Functions.registerUserChoice(chart, with: .LONG)
                        }
                        
                        saveIntoCoreData(chart, userChoice: .LONG)
                        
                        completion(.LONG)
                        
                    } else if isOtherButton {
                        
                        if registerChoice {
                            Functions.registerUserChoice(chart, with: .SHORT)
                        }
                        
                        saveIntoCoreData(chart, userChoice: .SHORT)
                        
                        completion(.SHORT)
                    }
                }
            }
        })
    }
    
    class func showPopTipOnceForKey(_ key: String, userDefaults: UserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .down, color: UIColor = .darkGray) -> AMPopTip? {
        if (!userDefaults.bool(forKey: key)) {
            userDefaults.set(true, forKey: key)
            userDefaults.synchronize()
            showPopTip(popTipText: text, inView: view, fromFrame: frame, direction:  direction, color: color)
        }
        
        return nil
    }
    
    class func showPopTip(popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection, color: UIColor, duration: TimeInterval = 3) -> AMPopTip? {
        
        let popTip = AMPopTip()
        popTip.font = UIFont(name: "HelveticaNeue", size: 16)!
        popTip.textColor = .white
        popTip.popoverColor = color
        popTip.offset = 10
        popTip.edgeMargin = 5
        popTip.actionAnimation = AMPopTipActionAnimation.bounce
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.showText(text, direction: direction, maxWidth: 300, in: view, fromFrame: frame, duration: duration)
        
        return popTip
    }
    
    class func dismissAllPopTips(_ allPopTips: [AMPopTip?]) {
        
        if !allPopTips.isEmpty {
            
            for tip in allPopTips {
                tip?.hide()
            }
        }
    }
    
    class func displayAlert (_ title: String, message: String, Action1: UIAlertAction?, Action2: UIAlertAction?) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        if Action1 != nil {
            alert.addAction(Action1!)
        }
        
        if Action2 != nil {
            alert.addAction(Action2!)
        }
        
        return alert
    }
    
    class func activityIndicator(_ view: UIView, halo: inout NVActivityIndicatorView!, state: Bool) {
        
        if state {
            
            // Create loading animation
            let frame = CGRect(x: view.bounds.midX - view.bounds.height / 4 , y: view.bounds.midY - view.bounds.height / 4, width: view.bounds.height / 2, height: view.bounds.height / 2)
            halo = NVActivityIndicatorView(frame: frame, type: .ballScaleMultiple, color: UIColor.lightGray)
            view.addSubview(halo)
            halo.startAnimating()
            
        } else {
            
            if halo !=  nil {
                halo.stopAnimating()
            }
        }
    }
    
    class func markFeedbackGiven() {
        Constants.userDefaults.set(true, forKey: "FEEDBACK_GIVEN")
        Constants.userDefaults.synchronize()
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
            
            SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.error)
            
            return completion(nil, false, nil, nil)
        }
        
        let excludedActivityTypesArray = [
            UIActivityType.postToWeibo,
            UIActivityType.assignToContact,
            UIActivityType.airDrop,
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
    
    class func presentSafariBrowser(_ withURL: URL!) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Open Url!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        let svc = SFSafariViewController(url: withURL, entersReaderIfAvailable: true)
        svc.modalTransitionStyle = .coverVertical
        svc.modalPresentationStyle = .overFullScreen
        if #available(iOS 10.0, *) {
            svc.preferredControlTintColor = Constants.stockSwipeGreenColor
        } else {
            svc.view.tintColor = Constants.stockSwipeGreenColor
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
    
    class func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * (M_PI/180.0)
    }
    
    class func formatTime(_ date: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
        
    }
}
