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
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        getActivities()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getActivities()
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
    
    func getActivities() {
        
        guard let currentUser = PFUser.current() else { return }
        
        isQueryingForActivities = true
        
        QueryHelper.sharedInstance.queryActivityForUser(currentUser) { (result) in
        
            self.isQueryingForActivities = false
            
            // Set badge to nil when user goes to view
            self.tabBarController?.tabBar.items?[3].badgeValue = nil
            
            do {
                
                let activityObjects = try result()
                self.activities = []
                
                self.activities += activityObjects
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        }
    }
    
    func loadMoreActivities(skip: Int) {
        
        guard let currentUser = PFUser.current() else { return }
        
        if self.refreshControl?.isRefreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryActivityForUser(currentUser) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    for activityObject: PFObject in activityObjects {
                        
                        //add datasource object here for tableview
                        self.activities.append(activityObject)
                        
                        //now insert cell in tableview
                        self.tableView.insertRows(at: [IndexPath(row: self.activities.count - 1, section: 0)], with: .none)
                    }
                    
                    if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating == true {
                    self.footerActivityIndicator.stopAnimating()
                    self.updateRefreshDate()
                }
            }
        }
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \((Date() as NSDate).formattedAsTimeAgo())"
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
        
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as NotificationCell
        cell.configureCell(activities[(indexPath as NSIndexPath).row])
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let activityAtIndexPath = activities[(indexPath as NSIndexPath).row]
        guard let activityType = Constants.ActivityType(rawValue: activityAtIndexPath.object(forKey: "activityType") as! String) else { return }
        
        switch activityType {
        case .Follow, .Mention:
            guard activityAtIndexPath.object(forKey: "fromUser") != nil else { return }
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: tableView.cellForRow(at: indexPath))
        case .TradeIdeaNew, .TradeIdeaLike, .TradeIdeaReply, .TradeIdeaReshare:
            guard activityAtIndexPath.object(forKey: "tradeIdea") != nil else { return }
            self.performSegueWithIdentifier(.TradeIdeaDetailSegueIdentifier, sender: tableView.cellForRow(at: indexPath))
        case .Block, .StockLong, .StockShort:
            break
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            //self.loadMoreTradeIdeas(skip: tradeIdeas.count)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        guard let cell = sender as? NotificationCell else { return }
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            
            if let tradeIdeaObject = cell.activity.object(forKey: "tradeIdea") as? PFObject {
                
                TradeIdea(parseObject: tradeIdeaObject, completion: { (tradeIdea) in
                    destinationViewController.tradeIdea = tradeIdea
                })
            }
            
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
        if !isQueryingForActivities && activities.count == 0 {
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
