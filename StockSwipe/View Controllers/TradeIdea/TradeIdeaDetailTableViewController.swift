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
    var replyActivities = [Activity]()
    var isQueryingForReplyTradeIdeas = false
    var replyTradeIdeasLastRefreshDate: Date!
    
    let queue = DispatchQueue(label: "Query Queue")
    
    let reachability = Reachability()
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getReplyTradeIdeas(queryType: .update)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.handleReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
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
                        let currentCount = self.replyActivities.count
                        self.replyActivities += replyActivitiesObjects

                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in replyActivitiesObjects.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 1)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()

                    case .update:

                        // append more trade ideas
                        self.tableView.beginUpdates()
                        for replyTradeIdea in replyActivitiesObjects {
                            self.replyActivities.insert(replyTradeIdea, at: 0)
                            let indexPath = IndexPath(row: 0, section: 1)
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
        
        return replyActivities.count
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
            cell.configureCell(with: self.activity, timeFormat: .long)
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ReplyIdeaCell", for: indexPath) as? IdeaCell
            guard let replyActivityAtIndex = self.replyActivities.get(indexPath.row) else { return cell }
            cell.configureCell(with: replyActivityAtIndex, timeFormat: .short)
            cell.delegate = self
        }
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.getReplyTradeIdeas(queryType: .older)
        }
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

extension TradeIdeaDetailTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .reply && activity.originalTradeIdea?.objectId == self.activity.tradeIdea?.objectId {
            let indexPath = IndexPath(row: 0, section: 1)
            self.replyActivities.insert(activity, at: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }

        self.delegate?.ideaPosted(with: activity, tradeIdeaTyp: tradeIdeaTyp)
    }
    
    internal func ideaDeleted(with activity: Activity) {
        
        if activity.objectId == self.activity.objectId {
            self.navigationController?.popViewController(animated: true)
        } else if let activity = self.replyActivities.find ({ $0.objectId == activity.objectId }), let index = self.replyActivities.index(of: activity) {
            let indexPath = IndexPath(row: 0, section: 1)
            self.replyActivities.removeObject(activity)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if replyActivities.count == 0 {
            self.tableView.reloadData()
        }
        
        self.delegate?.ideaDeleted(with: activity)
    }
    
    internal func ideaUpdated(with activity: Activity) {
        
        if let currentActivity = self.replyActivities.find ({ $0.objectId == activity.objectId }), let index = self.replyActivities.index(of: currentActivity) {
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
