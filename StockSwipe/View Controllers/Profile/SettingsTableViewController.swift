//
//  MoreTableViewController.swift
//
//
//  Created by Ace Green on 2015-06-26.
//
//

import UIKit
import MessageUI
import Firebase
import Parse

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, SegueHandlerType, CellType {
    
    enum SegueIdentifier: String {
        
        case NotificationsSegueIdentifier = "NotificationsSegueIdentifier"
        case BlockedAccountsSegueIdentifier = "BlockedAccountsSegueIdentifier"
    }
    
    enum CellIdentifier: String {
        case NotificationsCell = "NotificationsCell"
        case BlockedAccountsCell = "BlockedAccountsCell"
    }
    
    @IBAction func dismissSettings(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var swipeWatchListSwitch: UISwitch!
    
    @IBAction func swipeWatchListSwitchAction(_ sender: UISwitch) {
        
        Constants.userDefaults.set(sender.isOn, forKey: "SWIPE_ADD_TO_WATCHLIST")
        Constants.swipeAddToWatchlist = sender.isOn
        
        guard let currentUser = PFUser.current() else { return }
        
        currentUser["swipe_addToWatchlist"] = sender.isOn
        
        currentUser.saveEventually { (success, error) in
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setSwitches()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel!.textColor = UIColor.gray
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .NotificationsSegueIdentifier:
            break
        case .BlockedAccountsSegueIdentifier:
            break
        }
    }
    
    func setSwitches() {
        
        guard let currentUser = PFUser.current(), Functions.isConnectedToNetwork() else {
            return
        }
        
        swipeWatchListSwitch.isOn = currentUser.object(forKey: "swipe_addToWatchlist") as? Bool ?? Constants.userDefaults.bool(forKey: "SWIPE_ADD_TO_WATCHLIST")
    }
}
