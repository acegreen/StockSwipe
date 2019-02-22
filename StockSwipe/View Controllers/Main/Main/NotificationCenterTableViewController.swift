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
import Reachability

class NotificationCenterTableViewController: UITableViewController, CellType, SegueHandlerType {
    
    enum CellIdentifier: String {
        case NotificationCell = "NotificationCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
    }
    
    var notifications = [Activity]()
    var isQueryingForActivities = false
    var notificationsLastRefreshDate: Date?
    
    private let reachability = Reachability()
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        getNotifications(queryType: .update)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.handleReachability()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WatchlistCollectionViewController.userLoggedIn), name: Notification.Name("UserLoggedIn"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    deinit {
        self.reachability?.stopNotifier()
    }
    
    @objc func userLoggedIn(_ notification: Notification) {
        self.getNotifications(queryType: .new)
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
        
        QueryHelper.sharedInstance.queryActivityForUser(user: currentUser, skip: skip, limit: QueryHelper.queryLimit, order: queryOrder, creationDate: mostRecentRefreshDate) { (result) in
        
            self.isQueryingForActivities = false
            
            // Set badge to nil when user goes to view
            self.tabBarController?.tabBar.items?[3].badgeValue = nil
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }
                
                guard activityObjects.count > 0 else {
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
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
        guard let activityType = Constants.ActivityType(rawValue: activityAtIndexPath.activityType) else { return }
        
        switch activityType {
        case .Follow:
            
            let userAtIndexPath = activityAtIndexPath.fromUser
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: userAtIndexPath)
            
        case .Mention, .TradeIdeaNew, .TradeIdeaLike, .TradeIdeaReply, .TradeIdeaReshare:
            
            guard let tradeIdeaAtIndex = activityAtIndexPath.tradeIdea else { return }
            let activityType = [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue]
            QueryHelper.sharedInstance.queryActivityFor(fromUser: activityAtIndexPath.toUser, toUser: nil, originalTradeIdeas: nil, tradeIdeas: [tradeIdeaAtIndex], stocks: nil, activityType: activityType, skip: nil, limit: 1, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], selectKeys: nil, order: .descending, completion: { (result) in
                
                do {
                    
                    guard let activityObject = try result().first as? Activity else { return }
                    DispatchQueue.main.async {
                        self.performSegueWithIdentifier(.TradeIdeaDetailSegueIdentifier, sender: activityObject)
                    }
                } catch {
                    // TODO: handle error
                }
            })
            
        case .Block, .StockLong, .StockShort, .AddToWatchlistLong, .AddToWatchlistShort:
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
            destinationViewController.activity = sender as? Activity
            
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

extension NotificationCenterTableViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            self.getNotifications(queryType: .new)
        }
        
        self.reachability?.whenUnreachable = { _ in
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}
