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
    
    private var activities = [Activity]()
    private var isQueryingForTradeIdeas = false
    private var tradeIdeasLastRefreshDate: Date!
    private var totalActivityCount = 0
    
    private let reachability = Reachability()
    
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
        
        self.countActivities()
        self.handleReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        self.reachability?.stopNotifier()
    }
    
    func countActivities() {
        
        let stockObjectArray: [PFObject]? = self.stockObject != nil ? [self.stockObject!] : nil
        let activityTypes = self.stockObject != nil ? [Constants.ActivityType.Mention.rawValue] : [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue]
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: stockObjectArray, activityType: activityTypes, completion: { (result) in
            
            do {
                
                self.totalActivityCount = try result()
                
            } catch {
                // TODO: handle error
            }
        })
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
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: stockObjectArray, activityType: activityTypes, skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
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
                        self.tableView.reloadData()

                    case .older:

                        // append more trade ideas
                        self.activities += activityObjects

                        // insert cell in tableview
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: activityObjects, queryType: queryType))
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)

                    case .update:

                        // insert more trade ideas
                       self.activities.insert(contentsOf: activityObjects, at: 0)
                        
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: activityObjects, queryType: queryType))
                       self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                    }

                    // end refresh and add time stamp
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }

                    self.updateRefreshDate()
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
        
        self.tradeIdeasLastRefreshDate = Date()
        let title: String = "Last Update: " + (self.tradeIdeasLastRefreshDate as NSDate).formattedAsTimeAgo()
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
        return totalActivityCount
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
        
        if isLoadingCell(for: indexPath) {
            cell.clear()
        } else {
            cell.activity = activityAtIndex
            cell.delegate = self
        }
        
        return cell
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

// MARK: - UITableViewDataSourcePrefetching

extension TradeIdeasTableViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetchRowsAt \(indexPaths)")
        if indexPaths.contains(where: isLoadingCell) {
            self.getActivities(queryType: .older)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("cancelPrefetchingForRowsAt \(indexPaths)")
    }
}

private extension TradeIdeasTableViewController {
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.activities.count
    }
    
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    private func calculateIndexPathsToReload(from newActivities: [Activity], queryType: QueryHelper.QueryType) -> [IndexPath] {
        
        switch queryType {
        case .older:
            let startIndex = activities.count - newActivities.count
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
        case .update, .new:
            let startIndex = 0
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
        }
    }
}

// MARK: - IdeaPostDelegate

extension TradeIdeasTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        guard tradeIdeaTyp != .reply else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        self.activities.insert(activity, at: 0)
        self.totalActivityCount += 1
        self.tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    internal func ideaDeleted(with activity: Activity) {
        
        if let activity = self.activities.find ({ $0.objectId == activity.objectId }), let index = self.activities.firstIndex(of: activity) {
            let indexPath = IndexPath(row: index, section: 0)
            self.activities.removeObject(activity)
            self.totalActivityCount -= 1
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        if activities.count == 0 {
            self.tableView.reloadData()
        }
    }
    
    internal func ideaUpdated(with activity: Activity) {
        if let activity = self.activities.find ({ $0.objectId == activity.objectId }), let index = self.activities.firstIndex(of: activity) {
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
