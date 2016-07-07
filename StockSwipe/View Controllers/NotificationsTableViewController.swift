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
    
    @IBOutlet var TradeIdeaPostedNotificationSwitch: UISwitch!
    @IBOutlet var followerNotificationSwitch: UISwitch!
    @IBOutlet var repliesNotificationSwitch: UISwitch!
    @IBOutlet var likesNotificationSwitch: UISwitch!
    @IBOutlet var reshareNotificationSwitch: UISwitch!
    
    @IBAction func TradeIdeaPostedNotificationSwitch(sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.Warning)
            sender.on = !sender.on
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        currentUser["newTradeIdea_notification"] = sender.on
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.setBool(sender.on, forKey: "NEWTRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func followerNotificationSwitch(sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.Warning)
            sender.on = !sender.on
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        currentUser["follower_notification"] = sender.on
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.setBool(sender.on, forKey: "FOLLOWER_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func repliesNotificationSwitch(sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.Warning)
            sender.on = !sender.on
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        currentUser["replyTradeIdea_notification"] = sender.on
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.setBool(sender.on, forKey: "REPLYTRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func likesNotificationSwitch(sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.Warning)
            sender.on = !sender.on
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        currentUser["likeTradeIdea_notification"] = sender.on
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.setBool(sender.on, forKey: "LIKETRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    @IBAction func reshareNotificationSwitch(sender: UISwitch) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Change This!", subTitle: "We need an internet connection to set this", style: AlertStyle.Warning)
            sender.on = !sender.on
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        currentUser["reshareTradeIdea_notification"] = sender.on
        
        currentUser.saveEventually { (success, error) in
            if success {
                Constants.userDefaults.setBool(sender.on, forKey: "RESHARETRADEIDEA_NOTIFICATION")
            } else {
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setSwitches()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setSwitches() {
        
        guard PFUser.currentUser() != nil else {
            
            return
        }
        
        followerNotificationSwitch.on = Constants.userDefaults.boolForKey("FOLLOWER_NOTIFICATION")
        TradeIdeaPostedNotificationSwitch.on = Constants.userDefaults.boolForKey("NEWTRADEIDEA_NOTIFICATION")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
