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
    
    enum CellIdentifier: String {
        case NotificationCell = "NotificationCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
    }
    
    var activities = [PFObject]()
    var isQueryingForActivities = true
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        getActivities()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200.0
        
        self.getActivities()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    
        // Set badge to nil when user goes to view
        self.tabBarController?.tabBar.items?[3].badgeValue = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getActivities() {
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        isQueryingForActivities = true
        
        QueryHelper.sharedInstance.queryActivityForUser(currentUser) { (result) in
        
            self.isQueryingForActivities = false
            
            // Set badge to nil when user goes to view
            self.tabBarController?.tabBar.items?[3].badgeValue = nil
            
            do {
                
                let activityObjects = try result()
                self.activities = []
                
                self.activities += activityObjects
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        }
    }
    
    func loadMoreActivities(skip skip: Int) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        if self.refreshControl?.refreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryActivityForUser(currentUser) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    for activityObject: PFObject in activityObjects {
                        
                        //add datasource object here for tableview
                        self.activities.append(activityObject)
                        
                        //now insert cell in tableview
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.activities.count - 1, inSection: 0)], withRowAnimation: .None)
                    }
                    
                    if self.footerActivityIndicator?.isAnimating() == true {
                        self.footerActivityIndicator.stopAnimating()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating() == true {
                    self.footerActivityIndicator.stopAnimating()
                    self.updateRefreshDate()
                }
            }
        }
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \(NSDate().formattedAsTimeAgo())"
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return activities.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as NotificationCell
        cell.configureCell(activities[indexPath.row])
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let activityAtIndexPath = activities[indexPath.row]
        guard let activityType = Constants.ActivityType(rawValue: activityAtIndexPath.objectForKey("activityType") as! String) else { return }
        
        switch activityType {
        case .Follow, .Mention:
            guard activityAtIndexPath.objectForKey("fromUser") != nil else { return }
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: tableView.cellForRowAtIndexPath(indexPath))
        case .TradeIdeaNew, .TradeIdeaLike, .TradeIdeaReply, .TradeIdeaReshare:
            guard activityAtIndexPath.objectForKey("tradeIdea") != nil else { return }
            self.performSegueWithIdentifier(.TradeIdeaDetailSegueIdentifier, sender: tableView.cellForRowAtIndexPath(indexPath))
        case .Block, .StockLong, .StockShort:
            break
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            //self.loadMoreTradeIdeas(skip: tradeIdeas.count)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            
            guard let cell = sender as? NotificationCell else { return }
            
            if let tradeIdeaObject = cell.activity.objectForKey("tradeIdea") as? PFObject {
                
                let tradeIdea = TradeIdea(user: tradeIdeaObject.objectForKey("user") as! PFUser, description: tradeIdeaObject.objectForKey("description") as! String, likeCount: (tradeIdeaObject.objectForKey("likeCount") as? Int) ?? 0, reshareCount: (tradeIdeaObject.objectForKey("reshareCount") as? Int) ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                
                destinationViewController.tradeIdea = tradeIdea
            }
            
        case .ProfileSegueIdentifier:
            
            let profileViewController = segue.destinationViewController as! ProfileContainerController
            
            guard let cell = sender as? NotificationCell else { return }
            
            profileViewController.user = User(userObject: cell.activity.objectForKey("fromUser") as! PFUser)
            
            // Just a workaround.. There should be a cleaner way to sort this out
            profileViewController.navigationItem.rightBarButtonItem = nil
        }
    }
}

// MARK: - DZNEmptyDataSet Delegates

extension NotificationCenterTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        if !isQueryingForActivities && activities.count == 0 {
            return true
        }
        return false
    }
    
//    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
//        
//        return UIImage(assetIdentifier: .comingSoonImage)
//    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "Nothing New", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
}
