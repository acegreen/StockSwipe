//
//  Settings.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-12-24.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation

open class Settings {
    
    open class func registerGeneralDefaults() {
        let generalPrefsFile: URL = Bundle.main.url(forResource: "GeneralPreferences", withExtension: "plist")!
        let generalPrefs: NSDictionary = NSDictionary(contentsOf: generalPrefsFile)!
        Constants.userDefaults.register(defaults: generalPrefs as! [String : AnyObject])
        Constants.userDefaults.set(true, forKey: "GENERAL_DEFAULTS_INSTALLED")
        
        print("GeneralPreferences installed")
        Constants.userDefaults.synchronize()
    }
    
    open class func registerStocksDefaults() {
        
        switch Constants.countryCode {
        
        case "CA":
            
            let stockExchangePrefsFile: URL = Bundle.main.url(forResource: "StockExchangePreferences_CA", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOf: stockExchangePrefsFile)!
            Constants.userDefaults.register(defaults: stockExchangePrefs as! [String : AnyObject])
            Constants.userDefaults.set(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_CA installed")
            
        default:
            
            let stockExchangePrefsFile: URL = Bundle.main.url(forResource: "StockExchangePreferences_US", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOf: stockExchangePrefsFile)!
            Constants.userDefaults.register(defaults: stockExchangePrefs as! [String : AnyObject])
            Constants.userDefaults.set(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_US installed")
            
        }
        
        let stockSectorPrefsFile: URL = Bundle.main.url(forResource: "StockSectorPreferences", withExtension: "plist")!
        let stockSectorPrefs: NSDictionary = NSDictionary(contentsOf: stockSectorPrefsFile)!
        Constants.userDefaults.register(defaults: stockSectorPrefs as! [String : AnyObject])
        Constants.userDefaults.set(true, forKey: "STOCK_SECTOR_DEFAULTS_INSTALLED")
        
        print("StockSectorPreferences installed")
        
        print(Constants.countryCode)
        
        Constants.userDefaults.synchronize()
    }
    
    open class func registerNotificationDefaults() {
        let notificationPrefsFile: URL = Bundle.main.url(forResource: "NotificationPreferences", withExtension: "plist")!
        let notificationPrefs: NSDictionary = NSDictionary(contentsOf: notificationPrefsFile)!
        Constants.userDefaults.register(defaults: notificationPrefs as! [String : AnyObject])
        Constants.userDefaults.set(true, forKey: "NOTIFICATION_DEFAULTS_INSTALLED")
        
        print("NotificationPreferences installed")
        Constants.userDefaults.synchronize()
    }
}
