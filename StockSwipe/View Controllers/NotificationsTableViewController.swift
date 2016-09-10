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
        
        guard PFUser.current() != nil else {
            
            return
        }
        
        followerNotificationSwitch.isOn = Constants.userDefaults.bool(forKey: "FOLLOWER_NOTIFICATION")
        TradeIdeaPostedNotificationSwitch.isOn = Constants.userDefaults.bool(forKey: "NEWTRADEIDEA_NOTIFICATION")
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
