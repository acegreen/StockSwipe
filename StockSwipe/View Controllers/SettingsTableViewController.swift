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
        
    @IBAction func dismissSettings(_ sender: UIBarButtonItem)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.gray
            view.textLabel!.font = Constants.stockSwipeFont
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
}
