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
    
    private var notifications = [Activity]()
    private var isQueryingForActivities = false
    private var notificationsLastRefreshDate: Date?
    private var totalNotificationActivityCount = 0
    
    private let reachability = try? Reachability()
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        getNotifications(queryType: .update)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.countActivities()
        self.handleReachability()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WatchlistCollectionViewController.userLoggedIn), name: Notification.Name("UserLoggedIn"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.notifications.count != 0 && self.tabBarItem.badgeValue != nil {
            self.getNotifications(queryType: .update)
        }
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
    
    func countActivities() {
        
        guard let currentUser = PFUser.current() else { return }

        QueryHelper.sharedInstance.countActivityForUser(user: currentUser) { (result) in
            
            do {
                
                self.totalNotificationActivityCount = try result()
                
            } catch {
                // TODO: handle error
            }
        }
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
        
        QueryHelper.sharedInstance.queryActivityForUser(user: currentUser, skip: skip, limit: QueryHelper.queryLimit, order: queryOrder,  creationDate: mostRecentRefreshDate, includeKeys: ["tradeIdea", "fromUser", "toUser"]) { (result) in
        
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
                        self.notifications += activityObjects
                        
                        // insert cell in tableview
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: self.notifications, queryType: queryType))
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                        
                    case .update:
                        
                        self.notifications.insert(contentsOf: activityObjects, at: 0)
                        
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: self.notifications, queryType: queryType))
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
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
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalNotificationActivityCount
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as NotificationCell
        if isLoadingCell(for: indexPath) {
            cell.clear()
        } else {
            cell.activity = notifications[indexPath.row]
        }
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

private extension NotificationCenterTableViewController {
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.notifications.count
    }
    
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    private func calculateIndexPathsToReload(from newActivities: [Activity], queryType: QueryHelper.QueryType) -> [IndexPath] {
        
        switch queryType {
        case .older:
            let startIndex = notifications.count - newActivities.count
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
        case .update, .new:
            let startIndex = 0
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
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
