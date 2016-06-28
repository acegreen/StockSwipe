//
//  AppDelegate.swift
//  StockSwipe
//
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices
import Parse
import ParseTwitterUtils
import ParseFacebookUtilsV4
import Fabric
import TwitterKit
import Crashlytics
import Appsee
import LaunchKit
import ChimpKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, iRateDelegate {
    
    var window: UIWindow?
    
    override class func initialize() {
        
        setupSARate()
        
    }
    
    class func setupSARate() {
        
        //configure
        SARate.sharedInstance().minAppStoreRaiting = 4
        SARate.sharedInstance().eventsUntilPrompt = 10
        SARate.sharedInstance().daysUntilPrompt = 7
        SARate.sharedInstance().remindPeriod = 0
        
        SARate.sharedInstance().email = Constants.appEmail
        SARate.sharedInstance().emailSubject = "StockSwipe Feedback/Bug"
        SARate.sharedInstance().emailText = "Hello StockSwipe Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + Constants.emailDiagnosticInfo
        
        SARate.sharedInstance().previewMode = false
        SARate.sharedInstance().verboseLogging = false
        SARate.sharedInstance().promptAtLaunch = false
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Enable Parse LocalDatastore
        //Parse.enableLocalDatastore()
        
        // Initialize Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = Constants.APIKeys.Parse.key()
            $0.clientKey = ""
            $0.server = "http://45.55.137.153:1337/parse"
        }
        Parse.initializeWithConfiguration(configuration)
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        // Initialize Parse Twitter
        PFTwitterUtils.initializeWithConsumerKey(Constants.APIKeys.TwitterKit.key(),
                                                 consumerSecret: Constants.APIKeys.TwitterKit.consumerKey()!)
        
        // Initialize Facebook
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        PFFacebookUtils.facebookLoginManager().loginBehavior = .SystemAccount
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Intialize Twitter (Fabric)
        Fabric.with([Twitter.self(), Crashlytics.self(), Appsee.self()])
        
        // Initialize LaunchKit
        LaunchKit.launchWithToken(Constants.APIKeys.LaunchKit.key())
        //LaunchKit.sharedInstance().debugAlwaysPresentAppReleaseNotes = true
        
        // Initialize Rollout
        #if DEBUG
            Rollout.setupWithKey(Constants.APIKeys.Rollout.key(), developmentDevice: true)
        #else
            Rollout.setupWithKey(Constants.APIKeys.Rollout.key(), developmentDevice: false)
        #endif
        
        // Intialize ChimpKit
        ChimpKit.sharedKit().apiKey = Constants.APIKeys.ChimpKit.key()
        ChimpKit.sharedKit().shouldUseBackgroundThread = true
        
        // Register for Google App Indexing
        //GSDAppIndexing.sharedInstance().registerApp(iTunesID)
        
        // check device
        Functions.checkDevice()
        
        // setup user defaults
        Settings.registerGeneralDefaults()
        Settings.registerStocksDefaults()
        
        // Setup General Appearance
        UITabBar.appearance().barTintColor = UIColor.whiteColor()
        UITabBar.appearance().tintColor = Constants.stockSwipeGreenColor
        self.window?.backgroundColor = UIColor.whiteColor()
        
        // Adding paging indicator
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = Constants.stockSwipeGreenColor
        pageControl.backgroundColor = UIColor.whiteColor()
        
        // Track user
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector(Selector("backgroundRefreshStatus"))
            let oldPushHandlerOnly = !self.respondsToSelector(#selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        
        // increment event count
        SARate.sharedInstance().eventCount += 1
        print("eventCount", SARate.sharedInstance().eventCount)
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        //        let sanitizedURL: NSURL = GSDDeepLink.handleDeepLink(url)
        
        switch url.scheme {
            
        case "stockswipe":
            
            guard url.host == "chart", let window = self.window else { return true }
            
            guard let symbolDict = url.parseQueryString(url.query!, firstSeperator: "&", secondSeperator: "=") else { return false }
            
            guard let symbol = symbolDict["symbol"] as? String else { return
                //TO-DO: Alert user that symbol was not found
                false
            }
            
            QueryHelper.sharedInstance.queryStockObjectsFor([symbol], completion: { (result) in
                
                do {
                    
                    guard let stockObject = try result().first else { return }
                    let companyName = stockObject["Company"] as! String
                    let shorts = stockObject["Shorted_By"]
                    let longs = stockObject["Longed_By"]
                    
                    let chartDetailTabBarController  = Constants.storyboard.instantiateViewControllerWithIdentifier("ChartDetailTabBarController") as! ChartDetailTabBarController
                    let mainTabBarController: MainTabBarController = window.rootViewController as! MainTabBarController
                    
                    if mainTabBarController.presentationController != nil {
                        
                        mainTabBarController.dismissViewControllerAnimated(false, completion: nil)
                        
                    }
                    
                    let chart = Chart(symbol: symbolDict["symbol"] as! String, companyName: companyName, image: nil, shorts: shorts?.count, longs: longs?.count, parseObject: stockObject)
                    
                    chartDetailTabBarController.chart = chart
                        
                    mainTabBarController.presentViewController(chartDetailTabBarController, animated: true, completion: nil)
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                        })
                    }
                }
                
            })
            
            return true
            
        case "fb863699560384982":
            
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
            
        default:
            
            return false
        }
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        guard let window = self.window else { return true }
        
        var symbol: String!
        
        if userActivity.activityType == CSSearchableItemActionType {
            
            print(userActivity.userInfo)
            
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                symbol = uniqueIdentifier
            }
            
        } else if let userInfo = userActivity.userInfo {
            
            symbol = userInfo["symbol"] as? String
        }
        
        QueryHelper.sharedInstance.queryStockObjectsFor([symbol], completion: { (result) in
            
            do {
                
                guard let stockObject = try result().first else { return }
                let companyName = stockObject["Company"] as! String
                let shorts = stockObject["Shorted_By"]
                let longs = stockObject["Longed_By"]
                
                let chartDetailTabBarController  = Constants.storyboard.instantiateViewControllerWithIdentifier("ChartDetailTabBarController") as! ChartDetailTabBarController
                let mainTabBarController: MainTabBarController = window.rootViewController as! MainTabBarController
                
                if mainTabBarController.presentationController != nil {
                    
                    mainTabBarController.dismissViewControllerAnimated(false, completion: nil)
                    
                }
                
                let chart = Chart(symbol: symbol, companyName: companyName, image: nil, shorts: shorts?.count, longs: longs?.count, parseObject: stockObject)
                
                chartDetailTabBarController.chart = chart
                
                mainTabBarController.presentViewController(chartDetailTabBarController, animated: true, completion: nil)
                
            } catch {
                
                if let error = error as? Constants.Errors {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                    })
                }
            }
            
        })
        
        return true
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let currentInstallation: PFInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        
        if error.code == 3010 {
            
            print("Push notifications are not supported in the iOS Simulator.")
            
        } else {
            
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        // Handle received remote notification
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        
        
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        
        // Register for Push Notitications
        if application.respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            
            application.registerForRemoteNotifications()
        }
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Track Facebook events
        FBSDKAppEvents.activateApp()
        
        // Clear Parse Push badges
        if application.isRegisteredForRemoteNotifications() {
            let currentInstallation = PFInstallation.currentInstallation()
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "MDCSwipeToChoose.SwiftLikedOrNope" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("StockSwipe", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("StockSwipe.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as? NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    func iRateDidOpenAppStore() {
        
        print("iRateDidOpenAppStore")
        
        Functions.markFeedbackGiven()
        
        // log rating event
        Answers.logRating(nil,
                          contentName: "StockSwipe rated",
                          contentType: "rate",
                          contentId: nil,
                          customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "Country Code": Constants.countryCode, "App Version": Constants.AppVersion])
    }
    
    func iRateDidDetectAppUpdate() {
        
        print("iRateDidDetectAppUpdate")
        
        SARate.sharedInstance().eventCount = 0
        Settings.userDefaults.setBool(false, forKey: "FEEDBACK_GIVEN")
        Settings.userDefaults.synchronize()
        
    }
}