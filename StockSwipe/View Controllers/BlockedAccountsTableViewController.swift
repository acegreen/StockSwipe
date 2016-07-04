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

class BlockedAccountsTableViewController: UITableViewController {
    
    var blocked_users = [PFUser]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120

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


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
        cell.configureCell(blocked_users[indexPath.row])

        return cell
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

extension BlockedAccountsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle = NSAttributedString(string: "No blocked accounts", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])

        return attributedTitle
    }
}
