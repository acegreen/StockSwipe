//
//  MoreTableViewController.swift
//
//
//  Created by Ace Green on 2015-06-26.
//
//

import UIKit
import MessageUI
import Crashlytics
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
        
    @IBAction func dismissSettings(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.grayColor()
            view.textLabel!.font = Constants.stockSwipeFont
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .NotificationsSegueIdentifier:
            break
        case .BlockedAccountsSegueIdentifier:
            break
        }
    }
}
