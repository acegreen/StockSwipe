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
import LaunchKit
import ChimpKit

protocol PushNotificationDelegate {
    func didReceivePushNotification(_ userInfo: [AnyHashable: Any])
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, iRateDelegate {
    
    var window: UIWindow?
    var pushDelegate: PushNotificationDelegate?
    
    override class func initialize() {
        setupSARate()
    }
    
    class func setupSARate() {
        
        //configure
        SARate.sharedInstance().minAppStoreRaiting = 4
        SARate.sharedInstance().eventsUntilPrompt = 25
        SARate.sharedInstance().daysUntilPrompt = 7
        SARate.sharedInstance().remindPeriod = 0
        
        SARate.sharedInstance().email = Constants.appEmail
        SARate.sharedInstance().emailSubject = "StockSwipe Feedback/Bug"
        SARate.sharedInstance().emailText = "Hello StockSwipe Team, </br> </br> </br> </br> </br> - - - - - - - - - - - - - - - - - - - - - </br>" + Constants.emailDiagnosticInfo
        
        SARate.sharedInstance().previewMode = false
        SARate.sharedInstance().verboseLogging = false
        SARate.sharedInstance().promptAtLaunch = false
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Enable Parse LocalDatastore
        //Parse.enableLocalDatastore()
        
        // Initialize Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = Constants.APIKeys.Parse.key()
            $0.clientKey = ""
            $0.server = "http://45.55.137.153:1337/parse"
        }
        Parse.initialize(with: configuration)
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpened(launchOptions: launchOptions)
        
        // Initialize Parse (Twitter login)
        PFTwitterUtils.initialize(withConsumerKey: Constants.APIKeys.TwitterKit.key(),
                                                 consumerSecret: Constants.APIKeys.TwitterKit.consumerKey()!)
        
        // Initialize Twitter
        Twitter.sharedInstance().start(withConsumerKey: Constants.APIKeys.TwitterKit.key(), consumerSecret: Constants.APIKeys.TwitterKit.consumerKey()!)
        
        // Initialize Facebook
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions)
        PFFacebookUtils.facebookLoginManager().loginBehavior = .systemAccount
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Intialize Fabric
        Fabric.with([Crashlytics.self()])
        
        // Initialize LaunchKit
        LaunchKit.launch(withToken: Constants.APIKeys.LaunchKit.key())
        //LaunchKit.sharedInstance().debugAlwaysPresentAppReleaseNotes = true
        
        // Intialize ChimpKit
        ChimpKit.shared().apiKey = Constants.APIKeys.ChimpKit.key()
        ChimpKit.shared().shouldUseBackgroundThread = true
        
        // Register for Google App Indexing
        //GSDAppIndexing.sharedInstance().registerApp(iTunesID)
        
        // check device
        Functions.checkDevice()
        
        // setup user defaults
        Settings.registerGeneralDefaults()
        Settings.registerStocksDefaults()
        Settings.registerNotificationDefaults()
        
        Constants.swipeAddToWatchlist = PFUser.current()?.object(forKey: "swipe_addToWatchlist") as? Bool ?? Constants.userDefaults.bool(forKey: "SWIPE_ADD_TO_WATCHLIST")
        
        // Setup General Appearance
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().tintColor = Constants.stockSwipeGreenColor
        self.window?.backgroundColor = UIColor.white
        
        // Adding paging indicator
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = Constants.stockSwipeGreenColor
        pageControl.backgroundColor = UIColor.white
        
        // Track user
        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.responds(to: #selector(getter: UIApplication.backgroundRefreshStatus))
            let oldPushHandlerOnly = !self.responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        //        let sanitizedURL: NSURL = GSDDeepLink.handleDeepLink(url)
        
        switch url.scheme {
            
        case "stockswipe"?:
            
            guard url.host == "chart", let window = self.window else { return true }
            
            guard let symbolDict = url.parseQueryString(url.query!, firstSeperator: "&", secondSeperator: "=") else { return false }
            
            guard let symbol = symbolDict["symbol"] as? String else { return
                //TO-DO: Alert user that symbol was not found
                false
            }
            
            QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [symbol], completion: { (result) in
                
                do {
                    
                    guard let stockObject = try result().first else { return }
                    
                    let chartDetailTabBarController  = Constants.chartDetailStoryboard.instantiateViewController(withIdentifier: "ChartDetailTabBarController") as! ChartDetailTabBarController
                    let mainTabBarController: MainTabBarController = window.rootViewController as! MainTabBarController
                    
                    if mainTabBarController.presentationController != nil {
                        
                        mainTabBarController.dismiss(animated: false, completion: nil)
                        
                    }
                    
                    let chart = Chart(parseObject: stockObject)
                    
                    chartDetailTabBarController.chart = chart
                        
                    mainTabBarController.present(chartDetailTabBarController, animated: true, completion: nil)
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
                
            })
            
            return true
            
        case "fb863699560384982"?:
            
            return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
            
        default:
            
            return false
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
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
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [symbol], completion: { (result) in
            
            do {
                
                guard let stockObject = try result().first else { return }
                
                let chartDetailTabBarController  = Constants.chartDetailStoryboard.instantiateViewController(withIdentifier: "ChartDetailTabBarController") as! ChartDetailTabBarController
                let mainTabBarController: MainTabBarController = window.rootViewController as! MainTabBarController
                
                if mainTabBarController.presentationController != nil {
                    
                    mainTabBarController.dismiss(animated: false, completion: nil)
                    
                }
                
                let chart = Chart(parseObject: stockObject)
                
                chartDetailTabBarController.chart = chart
                
                mainTabBarController.present(chartDetailTabBarController, animated: true, completion: nil)
                
            } catch {
                
                if let error = error as? Constants.Errors {
                    
                    DispatchQueue.main.async {
                        SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                    }
                }
            }
            
        })
        
        return true
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if let currentInstallation = PFInstallation.current() {
            currentInstallation.setDeviceTokenFrom(deviceToken)
            currentInstallation.saveInBackground()
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        let error = error as NSError
        if error.code == 3010 {
            
            print("Push notifications are not supported in the iOS Simulator.")
            
        } else {
            
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        self.pushDelegate?.didReceivePushNotification(userInfo)
        
        //PFPush.handlePush(userInfo)
        
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Register for Push Notitications
        if application.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        } else {
            application.registerForRemoteNotifications()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // Track Facebook events
        FBSDKAppEvents.activateApp()
        
        // Clear Parse Push badges
        if application.isRegisteredForRemoteNotifications, let currentInstallation = PFInstallation.current() {
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "MDCSwipeToChoose.SwiftLikedOrNope" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as URL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "StockSwipe", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("StockSwipe.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
    }
    
    func iRateDidDetectAppUpdate() {
        
        print("iRateDidDetectAppUpdate")
        
        SARate.sharedInstance().eventCount = 0
        Constants.userDefaults.set(false, forKey: "FEEDBACK_GIVEN")
        Constants.userDefaults.synchronize()
        
    }
}
