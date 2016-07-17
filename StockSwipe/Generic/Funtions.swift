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
import AMPopTip
import NVActivityIndicatorView

public class Functions {
    
    //func isConnectedToNetwork() -> Bool {
    //
    //    var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    //    zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
    //    zeroAddress.sin_family = sa_family_t(AF_INET)
    //
    //    let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
    //        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
    //    }
    //
    //    var flags: SCNetworkReachabilityFlags = 0
    //    if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
    //        return false
    //    }
    //
    //    let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
    //    let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    //
    //    return isReachable && !needsConnection
    //
    //}
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags.ConnectionAutomatic
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func isUserLoggedIn(viewController: UIViewController) -> Bool {
        
        guard PFUser.currentUser() == nil else { return true }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            SweetAlert().showAlert("Login Required!", subTitle: "Please login to continue", style: AlertStyle.Warning, dismissTime: nil, buttonTitle: "Ok", buttonColor: UIColor.colorFromRGB(0xD0D0D0)) { (isOtherButton) -> Void in
                
                if isOtherButton {
                    
                    let logInViewcontroller = LoginViewController.sharedInstance
                    logInViewcontroller.logIn(viewController)
                }
            }
        })
        
        return false
    }
    
    class func blockUser(user: PFUser, postAlert: Bool) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        if currentUser.objectForKey("blocked_users") != nil {
            
            currentUser.addUniqueObject(user, forKey: "blocked_users")
            
        } else {
            
            currentUser.setObject([user], forKey: "blocked_users")
        }
        
        currentUser.saveEventually { (success, error) in
            
            if success {
                
                if postAlert == true {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        SweetAlert().showAlert("Blocked", subTitle: "", style: AlertStyle.Success)
                    })
                }
                
                QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: user, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.Follow.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
                QueryHelper.sharedInstance.queryActivityFor(user, toUser: currentUser, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.Follow.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                })
            }
        }
    }
    
    class func checkDevice() {
        
        switch UIDevice.currentDevice().userInterfaceIdiom {
            
        case .Pad:
            
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
    
    class func setImageURL(symbol: String) -> NSURL? {
        
        let URL: NSURL?
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            URL = NSURL(string: "http://45.55.137.153/images/symbol_" + symbol + "_interval_D.png")
            
        } else {
            
            URL = NSURL(string: "http://45.55.137.153/images/symbol_" + symbol + "_interval_D_phone.png")
        }
        
        return URL
    }
    
    class func setChartURL(symbol: String) -> NSURL {
        
        let formattedSymbol = symbol.URLEncodedString()!
        
        let URL: NSURL!
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            URL = NSURL(string: "http://45.55.137.153/?symbol=\(formattedSymbol)&interval=D")
            
        } else {
            
            URL = NSURL(string: "http://45.55.137.153/mobile_white.html?symbol=\(formattedSymbol)&interval=D")
        }
        
        return URL
    }
    
    class func getStockObjectAndChart(symbol: String, completion: (result: () throws -> (object: PFObject, chart: Chart)) -> Void) {
        
        QueryHelper.sharedInstance.queryStockObjectsFor([symbol]) { (result) in
            
            do {
                
                let stockObject = try result().first!
                
                QueryHelper.sharedInstance.queryChartImage(symbol, completion: { (result) in
                    
                    do {
                        
                        let chartImage = try result()
                        let companyName = stockObject["Company"] as? String
                        let shortCount = stockObject.objectForKey("shortCount") as? Int
                        let longCount = stockObject.objectForKey("longCount") as? Int
                        
                        let chart = Chart(symbol: symbol, companyName: companyName, image: chartImage, shortCount: shortCount, longCount: longCount, parseObject: stockObject)
                        completion(result: { (object: stockObject, chart: chart)})
                        
                    } catch {
                        
                        completion(result: {throw error})
                        
                    }
                    
                })
                
            } catch {
                
                completion(result: {throw error})
                
            }
        }
    }
    
    class func registerUserChoice(chart: Chart, with choice: Constants.UserChoices) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        guard let parseObject = chart.parseObject else {
            SweetAlert().showAlert("Stock Unknown", subTitle: "We couldn't find this symbol in our database", style: AlertStyle.Warning)
            return
        }
        
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
        
        print("\(choice)", chart)
        
        activityObject.saveEventually()
        saveIntoCoreData(chart, userChoice: choice)
    }
    
    class func saveIntoCoreData(chart: Chart, userChoice: Constants.UserChoices) {
        
        let checkRequest: NSFetchRequest = NSFetchRequest(entityName: "Charts")
        checkRequest.predicate = NSPredicate(format: "symbol == %@", chart.symbol)
        checkRequest.fetchLimit = 1
        checkRequest.returnsObjectsAsFaults = false
        
        do {
            
            let fetchedObjectArray:[ChartModel] = try Constants.context.executeFetchRequest(checkRequest) as! [ChartModel]
            
            if fetchedObjectArray.count == 0 {
                
                print("no object exists in core data")
                
                let newChart = ChartModel(entity: Constants.entity!, insertIntoManagedObjectContext: Constants.context)
                newChart.symbol = chart.symbol
                newChart.companyName = chart.companyName
                
                if chart.image != nil {
                    newChart.image = UIImagePNGRepresentation(chart.image)
                }
            
                newChart.shorts = Int32(chart.shortCount)
                newChart.longs = Int32(chart.longCount)
                newChart.userChoice = userChoice.rawValue
                newChart.dateChoosen = NSDate()
                
            } else if fetchedObjectArray.count > 0 {
                
                print("atleast one core data object exists")
                
                let fetchedObject:NSManagedObject = fetchedObjectArray.first!
                
                fetchedObject.setValue(chart.symbol, forKey: "symbol")
                
                if chart.image != nil {
                    fetchedObject.setValue(UIImagePNGRepresentation(chart.image), forKey: "image")
                }
                
                fetchedObject.setValue(chart.shortCount, forKey: "shorts")
                fetchedObject.setValue(chart.longCount, forKey: "longs")
                fetchedObject.setValue(userChoice.rawValue, forKey: "userChoice")
                fetchedObject.setValue(NSDate(), forKey: "dateChoosen")
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
    
    class func getChartsFromCoreData() -> NSArray? {
        
        let fetchRequest = NSFetchRequest(entityName: "Charts")
        fetchRequest.entity = Constants.entity
        
        let sort = NSSortDescriptor(key: "dateChoosen", ascending: false)
        let sortDescriptors = [sort]
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            
            let results = try Constants.context.executeFetchRequest(fetchRequest)
            
            //println(results)
            return results
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    class func setupConfigParameter(parameter:String, completion: (parameterValue: AnyObject?) -> Void) {
        
        PFConfig.getConfigInBackgroundWithBlock {
            (config: PFConfig?, error: NSError?) -> Void in

            let configParameter = config?[parameter]
            completion(parameterValue: configParameter)
        }
    }
    
    @available(iOS 9.0, *)
    class func createNSUserActivity(chart: Chart, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.contentDescription = chart.searchDescription
        //    attributeSet.thumbnailData = image
        attributeSet.relatedUniqueIdentifier = chart.symbol
        
        let activity = NSUserActivity(activityType: domainIdentifier)
        activity.title = chart.symbol
        activity.keywords = NSSet(array: [chart.symbol, chart.companyName, chart.searchDescription, "Stocks", "Markets"]) as! Set<String>
        activity.userInfo = ["symbol": chart.symbol, "companyName": chart.companyName, "searchDescription": chart.searchDescription]
        activity.contentAttributeSet = attributeSet
        
        activity.requiredUserInfoKeys = NSSet(array: ["symbol", "companyName", "searchDescription"]) as! Set<String>
        activity.eligibleForSearch = true
        activity.eligibleForPublicIndexing = true
        nsUserActivityArray.append(activity)
        activity.becomeCurrent()
        
        print("NSUserActivity created")
    }
    
    @available(iOS 9.0, *)
    class func addToSpotlight(chart: Chart, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.title = chart.symbol
        attributeSet.contentDescription = chart.searchDescription
        attributeSet.thumbnailData = nil
        attributeSet.keywords = [chart.symbol, chart.companyName, chart.searchDescription, "Stocks", "Markets"]
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: chart.symbol, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([searchableItem]) { (error) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed!")
            }
        }
        
    }
    
    @available(iOS 9.0, *)
    class func deleteFromSpotlight(uniqueIdentifier: String) {
        
        CSSearchableIndex.defaultSearchableIndex().deleteSearchableItemsWithIdentifiers([uniqueIdentifier]) { (error: NSError?) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully removed!")
            }
        }
    }
    
    class func addToWatchlist(chart: Chart) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            return
        }
        
        QueryHelper.sharedInstance.queryChartImage(chart.symbol, completion: { (result) in
            
            do {
                
                let chartImage = try result()
                
                chart.image = chartImage
                
                
            } catch {
                
                print(error)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.CustomImag(imageFile: "add_watchlist"), dismissTime: nil, buttonTitle:"SHORT", buttonColor:UIColor.redColor() , otherButtonTitle: "LONG", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    guard let topVC = UIApplication.topViewController() where Functions.isUserLoggedIn(topVC) else { return }
                    
                    if !isOtherButton {
                        
                        Functions.registerUserChoice(chart, with: .LONG)
                        
                    } else if isOtherButton {
                        
                        Functions.registerUserChoice(chart, with: .SHORT)
                    }
                }
                
            })
        })
    }
    
    class func showPopTipOnceForKey(key: String, userDefaults: NSUserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .Down, color: UIColor = .darkGrayColor()) -> AMPopTip? {
        if (!userDefaults.boolForKey(key)) {
            userDefaults.setBool(true, forKey: key)
            userDefaults.synchronize()
            showPopTip(popTipText: text, inView: view, fromFrame: frame, direction:  direction, color: color)
        }
        
        return nil
    }
    
    class func showPopTip(popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection, color: UIColor) -> AMPopTip? {
        
        AMPopTip.appearance().font = UIFont(name: "HelveticaNeue", size: 16)
        AMPopTip.appearance().textColor = .whiteColor()
        AMPopTip.appearance().popoverColor = color
        AMPopTip.appearance().offset = 10
        AMPopTip.appearance().edgeMargin = 5
        let popTip = AMPopTip()
        popTip.showText(text, direction: direction, maxWidth: 300, inView: view, fromFrame: frame, duration: 3)
        popTip.actionAnimation = AMPopTipActionAnimation.Bounce
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        
        return popTip
    }
    
    class func displayAlert (title: String, message: String, Action1:UIAlertAction?, Action2:UIAlertAction?) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        if Action1 != nil {
            
            alert.addAction(Action1!)
        }
        
        if Action2 != nil {
            
            alert.addAction(Action2!)
        }
        
        return alert
    }
    
    class func activityIndicator(view: UIView, inout halo: NVActivityIndicatorView!, state: Bool) {
        
        if state {
            
            // Create loading animation
            let frame = CGRect(x: CGRectGetMidX(view.bounds) - view.bounds.height / 4 , y: CGRectGetMidY(view.bounds) - view.bounds.height / 4, width: view.bounds.height / 2, height: view.bounds.height / 2)
            halo = NVActivityIndicatorView(frame: frame, type: .BallScaleMultiple, color: UIColor.lightGrayColor())
            halo.hidesWhenStopped = true
            view.addSubview(halo)
            halo.startAnimation()
            
        } else {
            
            if halo !=  nil {
                halo.stopAnimation()
            }
        }
    }
    
    class func markFeedbackGiven() {
        
        Constants.userDefaults.setBool(true, forKey: "FEEDBACK_GIVEN")
        Constants.userDefaults.synchronize()
        
    }
    
    class func sendPush(pushType: Constants.PushType, parameters: [String:String]) {
        PFCloud.callFunctionInBackground(pushType.rawValue, withParameters: parameters) { (results, error) -> Void in
        }
    }
    
    class func getCenterOfView(view: UIView) -> CGPoint {
        
        let bounds:CGRect = view.bounds
        let centerOfView:CGPoint = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        return centerOfView
        
    }
    
    class func presentActivityVC(textToShare: String?, imageToShare: UIImage?, url: NSURL?, sender: AnyObject, vc: UIViewController, completion:(activity: String?, success:Bool, items:[AnyObject]?, error:NSError?) -> Void) {
        
        var objectsToShare = [AnyObject]()
        
        if textToShare != nil {
            
            objectsToShare.append(textToShare!)
        }
        
        if imageToShare != nil {
            
            objectsToShare.append(imageToShare!)
        }
        
        if url != nil {
            
            objectsToShare.append(url!)
        }
        
        guard objectsToShare.count != 0 else {
            
            SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.Error)
            
            return completion(activity: nil, success: false, items: nil, error: nil)
        }
        
        let excludedActivityTypesArray: NSArray = [
            UIActivityTypePostToWeibo,
            UIActivityTypeAssignToContact,
            UIActivityTypeAirDrop,
        ]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedActivityTypesArray as? [String]
        
        activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up
        activityVC.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        vc.presentViewController(activityVC, animated: true, completion: nil)
        
        activityVC.completionWithItemsHandler = { (activity, success, items, error) in
            print("Activity: \(activity) Success: \(success) Items: \(items) Error: \(error)")
            
            completion(activity: activity, success: success, items: items, error: error)
        }
    }
    
    class func presentSafariBrowser(withURL: NSURL!) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Open Url!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            return
        }
        
        let svc = SFSafariViewController(URL: withURL, entersReaderIfAvailable: true)
        svc.modalTransitionStyle = .CoverVertical
        svc.modalPresentationStyle = .OverFullScreen
        svc.view.tintColor = Constants.stockSwipeGreenColor
        
        UIApplication.topViewController()?.presentViewController(svc, animated: true, completion: nil)
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
    
    class func degreesToRadians(degrees: Double) -> Double {
        return degrees * (M_PI/180.0)
    }
    
    class func formatTime(date: NSDate) -> String {
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter.stringFromDate(date)
        
    }
    
    class func dismissAllPopTips(allPopTips: [AMPopTip?]) {
        
        if !allPopTips.isEmpty {
            
            for tip in allPopTips {
                
                tip?.hide()
                
            }
        }
    }
}