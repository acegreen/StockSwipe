//
//  BlockedAccountsTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import DZNEmptyDataSet

class BlockedAccountsTableViewController: UITableViewController, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
    }
    
    var blocked_users = [PFUser]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        tableView.tableFooterView = UIView()

        setupAccounts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupAccounts() {
        guard let currentUser = PFUser.currentUser() else { return }
        guard (currentUser["blocked_users"] as? [PFUser]) != nil else { return }
        
        blocked_users = currentUser["blocked_users"] as! [PFUser]
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return blocked_users.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
        
        
        
        cell.configureCell(blocked_users[indexPath.row])

        return cell
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! ProfileContainerController
        
            guard let cell = sender as? UserCell else { return }
            destinationViewController.user = cell.user
            
            // Just a workaround.. There should be a cleaner way to sort this out
            destinationViewController.navigationItem.rightBarButtonItem = nil
        }
    }
}

extension BlockedAccountsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
 
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle = NSAttributedString(string: "No blocked accounts", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])

        return attributedTitle
    }
}
