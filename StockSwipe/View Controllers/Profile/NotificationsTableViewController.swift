//
//  NotificationsTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/6/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class NotificationsTableViewController: UITableViewController {
    
    @IBOutlet var followerNotificationSwitch: UISwitch!
    @IBOutlet var mentionNotificationSwitch: UISwitch!
    @IBOutlet var TradeIdeaPostedNotificationSwitch: UISwitch!
    @IBOutlet var repliesNotificationSwitch: UISwitch!
    @IBOutlet var likesNotificationSwitch: UISwitch!
    @IBOutlet var reshareNotificationSwitch: UISwitch!
    
    @IBAction func followerNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["follower_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "FOLLOWER_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func mentionNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["mention_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "MENTION_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func TradeIdeaPostedNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["newTradeIdea_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "NEWTRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func repliesNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["replyTradeIdea_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "REPLYTRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func likesNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["likeTradeIdea_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "LIKETRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func reshareNotificationSwitch(_ sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.warning)
            sender.isOn = !sender.isOn
            return
        }
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["reshareTradeIdea_notification"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.set(sender.isOn, forKey: "RESHARETRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setSwitches()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setSwitches() {
        
        guard let currentUser = PFUser.current(), Functions.isConnectedToNetwork() else {
            return
        }
        
        followerNotificationSwitch.isOn = currentUser.object(forKey: "follower_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "FOLLOWER_NOTIFICATION")
        mentionNotificationSwitch.isOn = currentUser.object(forKey: "mention_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "MENTION_NOTIFICATION")
        TradeIdeaPostedNotificationSwitch.isOn = currentUser.object(forKey: "newTradeIdea_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "NEWTRADEIDEA_NOTIFICATION")
        repliesNotificationSwitch.isOn = currentUser.object(forKey: "replyTradeIdea_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "REPLYTRADEIDEA_NOTIFICATION")
        likesNotificationSwitch.isOn = currentUser.object(forKey: "likeTradeIdea_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "LIKETRADEIDEA_NOTIFICATION")
        reshareNotificationSwitch.isOn = currentUser.object(forKey: "reshareTradeIdea_notification") as? Bool ?? Constants.userDefaults.bool(forKey: "RESHARETRADEIDEA_NOTIFICATION")
    }
}
