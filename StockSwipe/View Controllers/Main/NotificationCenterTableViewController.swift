//
//  NotificationCenterTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import SwiftyJSON
import Parse

class NotificationCenterTableViewController: UITableViewController, CellType, SegueHandlerType {
    
    enum QueryType {
        case newOrOld
        case update
    }
    
    enum CellIdentifier: String {
        case NotificationCell = "NotificationCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
    }
    
    var notifications = [PFObject]()
    var isQueryingForActivities = true
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        getNotifications(queryType: .update)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getNotifications(queryType: .newOrOld)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        // Set badge to nil when user goes to view
        self.tabBarController?.tabBar.items?[3].badgeValue = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getNotifications(queryType: QueryType) {
        
        guard let currentUser = PFUser.current() else { return }
        
        isQueryingForActivities = true
        
        var queryOrder: QueryHelper.QueryOrder
        switch queryType {
        case .newOrOld:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
        case .update:
            queryOrder = .ascending
        }
        
        QueryHelper.sharedInstance.queryActivityForUser(user: currentUser, skip: self.notifications.count, limit: 25, order: queryOrder) { (result) in
        
            self.isQueryingForActivities = false
            
            // Set badge to nil when user goes to view
            self.tabBarController?.tabBar.items?[3].badgeValue = nil
            
            do {
                
                let activityObjects = try result()
                
                guard activityObjects.count > 0 else {
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadEmptyDataSet()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                        self.updateRefreshDate()
                    }
                    
                    return
                }
                
                activityObjects.map({ activity in
                    
                    DispatchQueue.main.async {
                        
                        switch queryType {
                        case .newOrOld:
                            
                            // append more trade ideas
                            self.notifications.append(activity)
                            
                            // insert cell in tableview
                            let indexPath = IndexPath(row: self.notifications.count - 1, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                            
                        case .update:
                            
                            // append more trade ideas
                            self.notifications.insert(activity, at: 0)
                            
                            // insert cell in tableview
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                    }
                })
                
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                self.updateRefreshDate()
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: " + (Date() as NSDate).formattedAsTimeAgo()
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.white
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as NotificationCell
        cell.configureCell(notifications[indexPath.row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let activityAtIndexPath = notifications[indexPath.row]
        guard let activityType = Constants.ActivityType(rawValue: activityAtIndexPath.object(forKey: "activityType") as! String) else { return }
        
        switch activityType {
        case .Follow, .Mention:
            guard activityAtIndexPath.object(forKey: "fromUser") != nil else { return }
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: tableView.cellForRow(at: indexPath))
        case .TradeIdeaNew, .TradeIdeaLike, .TradeIdeaReply, .TradeIdeaReshare:
            guard let tradeIdeaAtIndexPath = activityAtIndexPath.object(forKey: "tradeIdea") as? PFObject else { return }
            self.performSegueWithIdentifier(.TradeIdeaDetailSegueIdentifier, sender: tableView.cellForRow(at: indexPath))
        case .Block, .StockLong, .StockShort:
            break
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.getNotifications(queryType: .newOrOld)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        guard let cell = sender as? NotificationCell else { return }
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.tradeIdea = TradeIdea(parseObject: cell.activity.object(forKey: "tradeIdea") as! PFObject)
            
        case .ProfileSegueIdentifier:
            
            let profileViewController = segue.destination as! ProfileContainerController
            profileViewController.user = User(userObject: cell.activity.object(forKey: "fromUser") as! PFUser)
            
            // Just a workaround.. There should be a cleaner way to sort this out
            profileViewController.navigationItem.rightBarButtonItem = nil
        }
    }
}

// MARK: - DZNEmptyDataSet Delegates

extension NotificationCenterTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if !isQueryingForActivities && notifications.count == 0 {
            return true
        }
        return false
    }
    
//    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
//        
//        return UIImage(assetIdentifier: .comingSoonImage)
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "Nothing New", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
}
