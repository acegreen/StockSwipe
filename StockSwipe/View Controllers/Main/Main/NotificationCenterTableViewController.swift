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
    
    var notifications = [PFObject]()
    var isQueryingForActivities = false
    var notificationsLastRefreshDate: Date?
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        getNotifications(queryType: .update)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotifications(queryType: .new)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getNotifications(queryType: QueryHelper.QueryType) {
        
        guard let currentUser = PFUser.current() else { return }
        
        isQueryingForActivities = true
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?
        
        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
            skip = self.notifications.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = notificationsLastRefreshDate
        }
        
        QueryHelper.sharedInstance.queryActivityForUser(user: currentUser, skip: skip, limit: QueryHelper.tradeIdeaQueryLimit, order: queryOrder, creationDate: mostRecentRefreshDate) { (result) in
        
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
                        self.notificationsLastRefreshDate = Date()
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    
                    switch queryType {
                    case .new:
                        
                        self.notifications = activityObjects
                        
                        // reload table
                        self.tableView.reloadData()
                        
                    case .older:
                        
                        // append more trade ideas
                        let currentCount = self.notifications.count
                        self.notifications += activityObjects
                        
                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in activityObjects.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                        
                    case .update:
                        
                        self.tableView.beginUpdates()
                        for activityObnject in activityObjects {
                            self.notifications.insert(activityObnject, at: 0)
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                    }
                }
                
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                
                self.updateRefreshDate()
                self.notificationsLastRefreshDate = Date()
                
            } catch {
                
                //TODO: Show sweet alert with Error.message()
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
            NSAttributedString.Key.foregroundColor : UIColor.white
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
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
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
        case .Follow:
            
            guard let userObjectAtIndexPath = activityAtIndexPath.object(forKey: "fromUser") as? PFUser else { return }
            let user = User(userObject: userObjectAtIndexPath)
            
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: user)

            
        case .Mention, .TradeIdeaNew, .TradeIdeaLike, .TradeIdeaReply, .TradeIdeaReshare:
            guard let tradeIdeaAtIndexPath = activityAtIndexPath.object(forKey: "tradeIdea") as? PFObject else { return }
            
            let tradeIdea = TradeIdea(parseObject: tradeIdeaAtIndexPath)
            self.performSegueWithIdentifier(.TradeIdeaDetailSegueIdentifier, sender: tradeIdea)
            
        case .Block, .StockLong, .StockShort:
            break
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.getNotifications(queryType: .older)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        guard sender != nil else { return }
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.tradeIdea = sender as? TradeIdea
            
        case .ProfileSegueIdentifier:
            let profileViewController = segue.destination as! ProfileContainerController
            profileViewController.user = sender as? User
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
    
//    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!{
//        return UIImage(assetIdentifier: .comingSoonImage)
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        attributedTitle = NSAttributedString(string: "Notifications", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: "You be logged out. Please login to see your notifications", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        return attributedDescription
        
    }
}
