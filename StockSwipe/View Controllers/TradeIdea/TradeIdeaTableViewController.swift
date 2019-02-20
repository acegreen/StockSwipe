//
//  TradeIdeasTableViewController.swift
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

class TradeIdeasTableViewController: UITableViewController, CellType, SegueHandlerType {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case PostIdeaSegueIdentifier = "PostIdeaSegueIdentifier"
    }
    
    var stockObject: PFObject?
    
    var activities = [Activity]()
    var isQueryingForTradeIdeas = false
    var tradeIdeasLastRefreshDate: Date!
    
    let queue = DispatchQueue(label: "Query Queue")
    
    let reachability = Reachability()
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getActivities(queryType: .update)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title
//        if companyName != nil {
//            self.navigationItem.title = companyName
//        } else {
//            self.navigationItem.title = symbol
//        }
        
        self.handleReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        self.reachability?.stopNotifier()
    }
    
    func getActivities(queryType: QueryHelper.QueryType) {
        
        guard !isQueryingForTradeIdeas else { return }
        
        isQueryingForTradeIdeas = true
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?
        
        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
            skip = self.activities.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = tradeIdeasLastRefreshDate
        }
        
        let stockObjectArray: [PFObject]? = self.stockObject != nil ? [self.stockObject!] : nil
        let activityTypes = self.stockObject != nil ? [Constants.ActivityType.Mention.rawValue] : [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue]
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: stockObjectArray, activityType: activityTypes, skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }
                
                guard activityObjects.count > 0 else {

                    self.isQueryingForTradeIdeas = false

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }

                    self.updateRefreshDate()
                    self.tradeIdeasLastRefreshDate = Date()

                    return
                }

                DispatchQueue.main.async {

                    switch queryType {
                    case .new:

                        self.activities = activityObjects

                        // reload table
                        self.tableView.reloadData()

                    case .older:

                        // append more trade ideas
                        let currentCount = self.activities.count
                        self.activities += activityObjects

                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in activityObjects.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()

                    case .update:

                        // append more trade ideas
                        self.tableView.beginUpdates()
                        for activity in activityObjects {
                            self.activities.insert(activity, at: 0)
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                    }

                    // end refresh and add time stamp
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }

                    self.updateRefreshDate()
                    self.tradeIdeasLastRefreshDate = Date()
                }

                self.isQueryingForTradeIdeas = false
                
            } catch {
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                
                self.isQueryingForTradeIdeas = false
            }
        })
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
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
        
        guard let activityAtIndex = self.activities.get(indexPath.row) else { return cell }
        cell.configureCell(with: activityAtIndex, timeFormat: .short)
        cell.delegate = self
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.getActivities(queryType: .older)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.activity = cell.activity
            
        case .PostIdeaSegueIdentifier:
            
            let destinationViewController = segue.destination as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.stockObject = self.stockObject
            ideaPostViewController.tradeIdeaType = .new
            ideaPostViewController.delegate =  self
        }
    }
}

extension TradeIdeasTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        guard tradeIdeaTyp != .reply else { return }
        
        let indexPath = IndexPath(row: 0, section: 0)
        self.activities.insert(activity, at: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    internal func ideaDeleted(with activity: Activity) {
        
        if let activity = self.activities.find ({ $0.objectId == activity.objectId }), let index = self.activities.index(of: activity) {
            
            let indexPath = IndexPath(row: index, section: 0)
            self.activities.removeObject(activity)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        if activities.count == 0 {
            self.tableView.reloadData()
        }
    }
    
    internal func ideaUpdated(with activity: Activity) {
        
        if let activity = self.activities.find ({ $0.objectId == activity.objectId }), let index = self.activities.index(of: activity) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

// DZNEmptyDataSet delegate functions

extension TradeIdeasTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if !isQueryingForTradeIdeas && activities.count == 0 {
            return true
        }
        return false
    }
    
    //    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
    //        return UIImage(assetIdentifier: .noIdeaBulbImage)
    //    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "Ideas", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let symbol = self.stockObject?.object(forKey: "Symbol")
        let symbolText = symbol != nil ? "for \(symbol!)" : ""
        let attributedDescription: NSAttributedString!
        attributedDescription = NSAttributedString(string: "Be the first to post an idea " + symbolText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        return attributedDescription
        
    }
}

extension TradeIdeasTableViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            if self.activities.count  == 0 {
                self.getActivities(queryType: .new)
            }
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
