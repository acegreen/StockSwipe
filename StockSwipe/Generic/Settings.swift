//
//  Settings.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-12-24.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation

public class Settings {
    
    static let userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    public class func registerGeneralDefaults() {
        let generalPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("GeneralPreferences", withExtension: "plist")!
        let generalPrefs: NSDictionary = NSDictionary(contentsOfURL: generalPrefsFile)!
        userDefaults.registerDefaults(generalPrefs as! [String : AnyObject])
        userDefaults.setBool(true, forKey: "GENERAL_DEFAULTS_INSTALLED")
        
        print("GeneralPreferences installed")
        userDefaults.synchronize()
    }
    
    public class func registerStocksDefaults() {
        
        switch Constants.countryCode {
        
        case "CA":
            
            let stockExchangePrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockExchangePreferences_CA", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOfURL: stockExchangePrefsFile)!
            userDefaults.registerDefaults(stockExchangePrefs as! [String : AnyObject])
            userDefaults.setBool(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_CA installed")
            
        default:
            
            let stockExchangePrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockExchangePreferences_US", withExtension: "plist")!
            let stockExchangePrefs: NSDictionary = NSDictionary(contentsOfURL: stockExchangePrefsFile)!
            userDefaults.registerDefaults(stockExchangePrefs as! [String : AnyObject])
            userDefaults.setBool(true, forKey: "STOCK_EXCHANGE_DEFAULTS_INSTALLED")
            
            print("StockExchangePreferences_US installed")
            
        }
        
        let stockSectorPrefsFile: NSURL = NSBundle.mainBundle().URLForResource("StockSectorPreferences", withExtension: "plist")!
        let stockSectorPrefs: NSDictionary = NSDictionary(contentsOfURL: stockSectorPrefsFile)!
        userDefaults.registerDefaults(stockSectorPrefs as! [String : AnyObject])
        userDefaults.setBool(true, forKey: "STOCK_SECTOR_DEFAULTS_INSTALLED")
        
        print("StockSectorPreferences installed")
        
        print(Constants.countryCode)
        
        userDefaults.synchronize()
    }
}
