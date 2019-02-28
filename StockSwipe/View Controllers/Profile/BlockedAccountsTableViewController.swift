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
    
    var blockedUsers = [User]()

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
        guard let currentUser = PFUser.current() else { return }
        guard let blockedUsersObjects = currentUser["blocked_users"] as? [User] else { return }
        blockedUsers = blockedUsersObjects
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return blockedUsers.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
        cell.user = blockedUsers[indexPath.row]

        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            let destinationViewController = segue.destination as! ProfileContainerController
        
            guard let cell = sender as? UserCell else { return }
            destinationViewController.user = cell.user
        }
    }
}

extension BlockedAccountsTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
 
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle = NSAttributedString(string: "Blocked Accounts", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])

        return attributedTitle
    }
}
