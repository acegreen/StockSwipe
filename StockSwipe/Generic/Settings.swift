//
//  Settings.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-12-24.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation

public class Settings {
    
    public class func registerGeneralDefaults() {
        let generalPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("GeneralPreferences", withExtension: "plist")!
        let generalPrefs: NSDictionary = NSDictionary(contentsOfURL: generalPrefsFile)!
        Constants.userDefaults.registerDefaults(generalPrefs as! [String : AnyObject])
        Constants.userDefaults.setBool(true, forKey: "GENERAL_DEFAULTS_INSTALLED")
        
        print("GeneralPreferences installed")
        Constants.userDefaults.synchronize()
    }
    
    public class func registerStocksDefaults() {
        
        switch Constants.countryCode {
        
        case "CA":
            
            let stockExchangePrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockExchangePreferences_CA", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOfURL: stockExchangePrefsFile)!
            Constants.userDefaults.registerDefaults(stockExchangePrefs as! [String : AnyObject])
            Constants.userDefaults.setBool(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_CA installed")
            
        default:
            
            let stockExchangePrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockExchangePreferences_US", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOfURL: stockExchangePrefsFile)!
            Constants.userDefaults.registerDefaults(stockExchangePrefs as! [String : AnyObject])
            Constants.userDefaults.setBool(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_US installed")
            
        }
        
        let stockSectorPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockSectorPreferences", withExtension: "plist")!
        let stockSectorPrefs: NSDictionary = NSDictionary(contentsOfURL: stockSectorPrefsFile)!
        Constants.userDefaults.registerDefaults(stockSectorPrefs as! [String : AnyObject])
        Constants.userDefaults.setBool(true, forKey: "STOCK_SECTOR_DEFAULTS_INSTALLED")
        
        print("StockSectorPreferences installed")
        
        print(Constants.countryCode)
        
        Constants.userDefaults.synchronize()
    }
    
    public class func registerNotificationDefaults() {
        let notificationPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("NotificationPreferences", withExtension: "plist")!
        let notificationPrefs: NSDictionary = NSDictionary(contentsOfURL: notificationPrefsFile)!
        Constants.userDefaults.registerDefaults(notificationPrefs as! [String : AnyObject])
        Constants.userDefaults.setBool(true, forKey: "NOTIFICATION_DEFAULTS_INSTALLED")
        
        print("NotificationPreferences installed")
        Constants.userDefaults.synchronize()
    }
}
