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

class Functions {
    
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
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags.connectionAutomatic
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func isUserLoggedIn(_ viewController: UIViewController) -> Bool {
        
        guard PFUser.current() == nil else { return true }
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            SweetAlert().showAlert("Login Required!", subTitle: "Please login to continue", style: AlertStyle.warning, dismissTime: nil, buttonTitle: "Ok", buttonColor: UIColor.colorFromRGB(0xD0D0D0)) { (isOtherButton) -> Void in
                
                if isOtherButton {
                    
                    let logInViewcontroller = LoginViewController.sharedInstance
                    logInViewcontroller.logIn(viewController)
                    logInViewcontroller.loginDelegate = viewController as? LoginDelegate
                }
            }
        })
        
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
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        SweetAlert().showAlert("Blocked", subTitle: "", style: AlertStyle.success)
                    })
                }
                
                QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: user, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
                QueryHelper.sharedInstance.queryActivityFor(user, toUser: currentUser, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                })
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
        
        QueryHelper.sharedInstance.queryWith(imageURL.absoluteString, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                completion(UIImage(data: avatarData))
                
            } catch {
                // TODO: Handle error
            }
        })
    }
    
    class func getStockObjectAndChart(_ symbol: String, completion: @escaping (_ result: () throws -> (object: PFObject, chart: Chart)) -> Void) {
        
        QueryHelper.sharedInstance.queryStockObjectsFor([symbol]) { (result) in
            
            do {
                
                let stockObject = try result().first!
                
                QueryHelper.sharedInstance.queryChartImage(symbol, completion: { (result) in
                    
                    do {
                        
                        let chart = Chart(parseObject: stockObject)
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
    
    class func registerUserChoice(_ chart: Chart, with choice: Constants.UserChoices) {
        
        guard let currentUser = PFUser.current() else { return }
        guard let parseObject = chart.parseObject else {
            SweetAlert().showAlert("Stock Unknown", subTitle: "We couldn't find this symbol in our database", style: AlertStyle.warning)
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [parseObject], activityType: nil, skip: nil, limit: nil, includeKeys: nil) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                if let firstActivityObject = activityObjects.first {
                    
                    let firstActivityObjectActivityType = firstActivityObject["activityType"] as! String
                    
                    if (firstActivityObjectActivityType == Constants.ActivityType.StockLong.rawValue &&  choice == .LONG) || (firstActivityObjectActivityType == Constants.ActivityType.StockShort.rawValue &&  choice == .SHORT) {
                        
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
                            
                            chart.shortCount += 1
                            if chart.longCount > 1 {
                                chart.longCount -= 1
                            }
                            
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
                
            } catch {
                
            }
            
            print("\(choice)", chart)
            
            saveIntoCoreData(chart, userChoice: choice)
        }
    }
    
    class func saveIntoCoreData(_ chart: Chart, userChoice: Constants.UserChoices) {
        
        let checkRequest: NSFetchRequest = NSFetchRequest(entityName: "Charts")
        checkRequest.predicate = NSPredicate(format: "symbol == %@", chart.symbol)
        checkRequest.fetchLimit = 1
        checkRequest.returnsObjectsAsFaults = false
        
        do {
            
            let fetchedObjectArray:[ChartModel] = try Constants.context.fetch(checkRequest) as! [ChartModel]
            
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
    
    class func getChartsFromCoreData() -> NSArray? {
        
        let fetchRequest = NSFetchRequest(entityName: "Charts")
        fetchRequest.entity = Constants.entity
        
        let sort = NSSortDescriptor(key: "dateChoosen", ascending: false)
        let sortDescriptors = [sort]
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            
            let results = try Constants.context.fetch(fetchRequest)
            
            //println(results)
            return results
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    class func setupConfigParameter(_ parameter:String, completion: @escaping (_ parameterValue: AnyObject?) -> Void) {
        
        PFConfig.getInBackground {
            (config: PFConfig?, error: NSError?) -> Void in
            
            let configParameter = config?[parameter]
            completion(parameterValue: configParameter)
        }
    }
    
    @available(iOS 9.0, *)
    class func createNSUserActivity(_ chart: Chart, domainIdentifier: String) {
        
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
        activity.isEligibleForSearch = true
        activity.isEligibleForPublicIndexing = true
        nsUserActivityArray.append(activity)
        activity.becomeCurrent()
        
        print("NSUserActivity created")
    }
    
    @available(iOS 9.0, *)
    class func addToSpotlight(_ chart: Chart, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.title = chart.symbol
        attributeSet.contentDescription = chart.searchDescription
        attributeSet.thumbnailData = nil
        attributeSet.keywords = [chart.symbol, chart.companyName, chart.searchDescription, "Stocks", "Markets"]
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: chart.symbol, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        
        CSSearchableIndex.default().indexSearchableItems([searchableItem]) { (error) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed!")
            }
        }
        
    }
    
    @available(iOS 9.0, *)
    class func deleteFromSpotlight(_ uniqueIdentifier: String) {
        
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [uniqueIdentifier]) { (error: NSError?) -> Void in
            
            if let error = error {
                print("Deindexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully removed!")
            }
        }
    }
    
    class func addToWatchlist(_ chart: Chart, completion: @escaping (Constants.UserChoices) -> Void)  {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        QueryHelper.sharedInstance.queryChartImage(chart.symbol, completion: { (result) in
            
            do {
                
                let chartImage = try result()
                
                chart.image = chartImage
                
                
            } catch {
                
                print(error)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.customImag(imageFile: "add_watchlist"), dismissTime: nil, buttonTitle:"SHORT", buttonColor:UIColor.red , otherButtonTitle: "LONG", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    guard let topVC = UIApplication.topViewController() , Functions.isUserLoggedIn(topVC) else { return }
                    
                    if !isOtherButton {
                        completion(.LONG)
                    } else if isOtherButton {
                        completion(.SHORT)
                    }
                }
            })
        })
    }
    
    class func showPopTipOnceForKey(_ key: String, userDefaults: UserDefaults, popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection = .down, color: UIColor = .darkGray()) -> AMPopTip? {
        if (!userDefaults.bool(forKey: key)) {
            userDefaults.set(true, forKey: key)
            userDefaults.synchronize()
            showPopTip(popTipText: text, inView: view, fromFrame: frame, direction:  direction, color: color)
        }
        
        return nil
    }
    
    class func showPopTip(popTipText text: String, inView view: UIView, fromFrame frame: CGRect, direction: AMPopTipDirection, color: UIColor) -> AMPopTip? {
        
        AMPopTip.appearance().font = UIFont(name: "HelveticaNeue", size: 16)
        AMPopTip.appearance().textColor = .white()
        AMPopTip.appearance().popoverColor = color
        AMPopTip.appearance().offset = 10
        AMPopTip.appearance().edgeMargin = 5
        let popTip = AMPopTip()
        popTip.showText(text, direction: direction, maxWidth: 300, in: view, fromFrame: frame, duration: 3)
        popTip.actionAnimation = AMPopTipActionAnimation.bounce
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        
        return popTip
    }
    
    class func displayAlert (_ title: String, message: String, Action1:UIAlertAction?, Action2:UIAlertAction?) -> UIAlertController {
        
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
        
        let excludedActivityTypesArray: NSArray = [
            UIActivityType.postToWeibo,
            UIActivityType.assignToContact,
            UIActivityType.airDrop,
            ]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedActivityTypesArray as? [String] as! [UIActivityType]?
        
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
        svc.view.tintColor = Constants.stockSwipeGreenColor
        
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
    
    class func dismissAllPopTips(_ allPopTips: [AMPopTip?]) {
        
        if !allPopTips.isEmpty {
            
            for tip in allPopTips {
                
                tip?.hide()
                
            }
        }
    }
}
