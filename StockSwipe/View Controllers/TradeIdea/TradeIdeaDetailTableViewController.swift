//
//  NewsTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import SwiftyJSON
import Parse
import Reachability

class TradeIdeaDetailTableViewController: UITableViewController, CellType, SegueHandlerType {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
        case ReplyIdeaCell = "ReplyIdeaCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
    }
    
    var delegate: IdeaPostDelegate!
    
    var activity: Activity!
    private var replyActivities = [Activity]()
    private var isQueryingForReplyTradeIdeas = false
    private var replyTradeIdeasLastRefreshDate: Date!
    private var totalReplyActivityCount = 0
    
    private let reachability = try? Reachability()
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getReplyTradeIdeas(queryType: .update)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.countReplyActivities()
        self.handleReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    func countReplyActivities() {
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        let activityTypes = [Constants.ActivityType.TradeIdeaReply.rawValue]
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: tradeIdea, tradeIdea: nil, stocks: nil, activityType: activityTypes, completion: { (result) in
            
            do {
                
                self.totalReplyActivityCount = try result()
                
            } catch {
                // TODO: handle error
            }
        })
    }
    
    func getReplyTradeIdeas(queryType: QueryHelper.QueryType) {
        
        guard !isQueryingForReplyTradeIdeas else { return }        
        isQueryingForReplyTradeIdeas = true
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?

        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
            skip = self.replyActivities.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = replyTradeIdeasLastRefreshDate
        }
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        let activityTypes = [Constants.ActivityType.TradeIdeaReply.rawValue]
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdeas: [tradeIdea], tradeIdeas: nil, stocks: nil, activityType: activityTypes, skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
            do {
                
                guard let replyActivitiesObjects = try result() as? [Activity] else { return }
                
                guard replyActivitiesObjects.count > 0 else {

                    self.isQueryingForReplyTradeIdeas = false

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }

                    self.updateRefreshDate()
                    self.replyTradeIdeasLastRefreshDate = Date()

                    return
                }

                DispatchQueue.main.async {

                    switch queryType {
                    case .new:
                        
                        self.replyActivities = replyActivitiesObjects
                        self.tableView.reloadData()
                        
                    case .older:
                        
                        // append more trade ideas
                        self.replyActivities += replyActivitiesObjects
                        
                        // insert cell in tableview
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: replyActivitiesObjects, queryType: queryType))
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                        
                    case .update:
                        
                        // insert more trade ideas
                        self.replyActivities.insert(contentsOf: replyActivitiesObjects, at: 0)
                        
                        let indexPathsToReload = self.visibleIndexPathsToReload(intersecting: self.calculateIndexPathsToReload(from: replyActivitiesObjects, queryType: queryType))
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                    }

                    // end refresh and add time stamp
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }

                    self.updateRefreshDate()
                    self.replyTradeIdeasLastRefreshDate = Date()
                }

                self.isQueryingForReplyTradeIdeas = false
                
            } catch {
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                
                self.isQueryingForReplyTradeIdeas = false
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        
        return totalReplyActivityCount
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 320
        }
        
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: IdeaCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.activity = self.activity
            cell.timeFormat = .long
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ReplyIdeaCell", for: indexPath) as? IdeaCell
            guard let replyActivityAtIndex = self.replyActivities.get(indexPath.row) else { return cell }
            
            if isLoadingCell(for: indexPath) {
                cell.clear()
            } else {
                cell.activity = replyActivityAtIndex
                cell.delegate = self
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.activity = cell.activity
            destinationViewController.delegate = self
        }
    }
}

private extension TradeIdeaDetailTableViewController {
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.replyActivities.count
    }
    
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {
        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows ?? []
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
    
    private func calculateIndexPathsToReload(from newActivities: [Activity], queryType: QueryHelper.QueryType) -> [IndexPath] {
        
        switch queryType {
        case .older:
            let startIndex = replyActivities.count - newActivities.count
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
        case .update, .new:
            let startIndex = 0
            let endIndex = startIndex + newActivities.count
            return (startIndex..<endIndex).map { IndexPath(row: $0, section: 1) }
        }
    }
}

extension TradeIdeaDetailTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .reply && activity.originalTradeIdea?.objectId == self.activity.tradeIdea?.objectId {
            let indexPath = IndexPath(row: 0, section: 1)
            self.replyActivities.insert(activity, at: 0)
            self.totalReplyActivityCount += 1
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }

        self.delegate?.ideaPosted(with: activity, tradeIdeaTyp: tradeIdeaTyp)
    }
    
    internal func ideaDeleted(with activity: Activity) {
        
        if activity.objectId == self.activity.objectId {
            self.navigationController?.popViewController(animated: true)
        } else if let activity = self.replyActivities.find ({ $0.objectId == activity.objectId }) {
            let indexPath = IndexPath(row: 0, section: 1)
            self.replyActivities.removeObject(activity)
            self.totalReplyActivityCount -= 1
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if replyActivities.count == 0 {
            self.tableView.reloadData()
        }
        
        self.delegate?.ideaDeleted(with: activity)
    }
    
    internal func ideaUpdated(with activity: Activity) {
        
        if let currentActivity = self.replyActivities.find ({ $0.objectId == activity.objectId }) {
            let indexPath = IndexPath(row: 0, section: 1)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        self.delegate?.ideaUpdated(with: activity)
    }
}

extension TradeIdeaDetailTableViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            if self.replyActivities.count  == 0 {
                self.getReplyTradeIdeas(queryType: .new)
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
