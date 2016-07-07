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
import AMPopTip
import Parse
import SafariServices

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
            verticalPadding = 50.0
            
            numberOfCellsHorizontally = 2
            numberOfCellsVertically = 2
            
        default:
            
            switch SDiOSVersion.deviceSize() {
                
            case .Screen5Dot5inch:
                
                chartWidth = 390
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 3
                frontCardOffsetFromCenter = -10
                
            case .Screen4Dot7inch:
                
                chartWidth = 350
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 3
                
                frontCardOffsetFromCenter = -10
                
            case .Screen4inch:
                
                chartWidth = 300
                chartHeight = chartWidth + (Constants.chartImageTopPadding + Constants.informationViewHeight)
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0
                
            case .Screen3Dot5inch:
                
                chartWidth = 280
                chartHeight = chartWidth
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0
                
            default:
                
                chartWidth = 300
                chartHeight = chartWidth
                
                numberOfCellsVertically = 2
                frontCardOffsetFromCenter = 0

                
            }
            
            horizontalPadding = 10.0
            verticalPadding = 25.0
            
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
                        let shorts: AnyObject? = stockObject["Shorted_By"]
                        let longs: AnyObject? = stockObject["Longed_By"]
                        
                        let chart = Chart(symbol: symbol, companyName: companyName, image: chartImage, shorts: shorts?.count, longs: longs?.count, parseObject: stockObject)
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
        
        guard (PFUser.currentUser() != nil) else { return }
        
        var removeFromKey: String!
        var addToKey: String!
        
        switch choice {
            
        case .LONG:
            
            removeFromKey = Constants.UserChoices.SHORT.key()
            addToKey = Constants.UserChoices.LONG.key()
        case .SHORT:
            
            removeFromKey = Constants.UserChoices.LONG.key()
            addToKey = Constants.UserChoices.SHORT.key()
        default:
            break
        }
        
        if let object = chart.parseObject {
            
            object.removeObject(PFUser.currentUser()!, forKey: removeFromKey)
            
            if object.objectForKey(addToKey) != nil {
                
                object.addUniqueObject(PFUser.currentUser()!, forKey: addToKey)
                
            } else {
                
                object.setObject([PFUser.currentUser()!], forKey: addToKey)
            }
            
            object.saveEventually({ (success, error) -> Void in
                
                switch choice {
                    
                case .LONG:
                    
                    chart.longs = (chart.longs ?? 0) + 1

                case .SHORT:
                    
                    chart.shorts = (chart.shorts ?? 0) + 1
                    
                default:
                    break
                }
                
                print("\(choice)", chart)
                
                saveIntoCoreData(chart, userChoice: choice)
                
            })
        }
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
            
                newChart.shorts = Int32(chart.shorts ?? 0)
                newChart.longs = Int32(chart.longs ?? 0)
                newChart.userChoice = userChoice.key()
                newChart.dateChoosen = NSDate()
                
            } else if fetchedObjectArray.count > 0 {
                
                print("atleast one core data object exists")
                
                let fetchedObject:NSManagedObject = fetchedObjectArray.first!
                
                fetchedObject.setValue(chart.symbol, forKey: "symbol")
                
                if chart.image != nil {
                    fetchedObject.setValue(UIImagePNGRepresentation(chart.image), forKey: "image")
                }
                
                fetchedObject.setValue(chart.shorts, forKey: "shorts")
                fetchedObject.setValue(chart.longs, forKey: "longs")
                fetchedObject.setValue(userChoice.key(), forKey: "userChoice")
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
    class func createNSUserActivity(chart: Chart, uniqueIdentifier: String, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.contentDescription = chart.searchDescription
        //    attributeSet.thumbnailData = image
        //    attributeSet.relatedUniqueIdentifier = title
        
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
    class func addToSpotlight(chart: Chart, uniqueIdentifier: String, domainIdentifier: String) {
        
        let attributeSet:CSSearchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeImage as String)
        attributeSet.title = chart.symbol
        attributeSet.contentDescription = chart.searchDescription
        attributeSet.thumbnailData = nil
        attributeSet.keywords = [chart.symbol, chart.companyName, chart.searchDescription, "Stocks", "Markets"]
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: uniqueIdentifier, domainIdentifier: domainIdentifier, attributeSet: attributeSet)
        
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
    
    class func markFeedbackGiven() {
        
        Constants.userDefaults.setBool(true, forKey: "FEEDBACK_GIVEN")
        Constants.userDefaults.synchronize()
        
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