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

class TradeIdeaDetailTableViewController: UITableViewController, CellType, SegueHandlerType {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
        case ReplyIdeaCell = "ReplyIdeaCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
    }
    
    var delegate: IdeaPostDelegate!
    
    var tradeIdea: TradeIdea!
    var replyTradeIdeas = [TradeIdea]()
    var isQueryingForReplyTradeIdeas = false
    var replyTradeIdeasLastRefreshDate: Date!
    
    let queue = DispatchQueue(label: "Query Queue")
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getReplyTradeIdeas(queryType: .update)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.replyTradeIdeas.count  == 0 {
            getReplyTradeIdeas(queryType: .new)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReplyTradeIdeas(queryType: QueryHelper.QueryType) {
        
        guard !isQueryingForReplyTradeIdeas else { return }
        guard let tradeIdea = self.tradeIdea else { return }
        
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
            
            skip = self.replyTradeIdeas.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = replyTradeIdeasLastRefreshDate
        }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "reply_to", object: tradeIdea.parseObject, skip: skip, limit: nil, order: queryOrder, creationDate: mostRecentRefreshDate) { (result) in
            
            do {
                
                let replyTradeIdeaObjects = try result()
                
                guard replyTradeIdeaObjects.count > 0 else {
                    
                    self.isQueryingForReplyTradeIdeas = false
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadEmptyDataSet()
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
                
                let replyTradeIdeas = TradeIdea.makeTradeIdeas(from: replyTradeIdeaObjects)
                
                DispatchQueue.main.async {
                    
                    switch queryType {
                    case .new:
                        
                        self.replyTradeIdeas = replyTradeIdeas
                        
                        // reload table
                        self.tableView.reloadData()
                        
                    case .older:
                        
                        // append more trade ideas
                        let currentCount = self.replyTradeIdeas.count
                        self.replyTradeIdeas += replyTradeIdeas
                        
                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in replyTradeIdeas.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 1)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                        
                    case .update:
                        
                        // append more trade ideas
                        self.tableView.beginUpdates()
                        for replyTradeIdea in replyTradeIdeas {
                            self.replyTradeIdeas.insert(replyTradeIdea, at: 0)
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        
        return replyTradeIdeas.count
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
            cell.configureCell(with: self.tradeIdea, timeFormat: .long)
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ReplyIdeaCell", for: indexPath) as! IdeaCell
            guard let replyTradeIdeaAtIndex = self.replyTradeIdeas.get(indexPath.row) else { return cell }
            cell.configureCell(with: replyTradeIdeaAtIndex, timeFormat: .short)
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
            destinationViewController.tradeIdea = cell.tradeIdea
        }
    }
}

extension TradeIdeaDetailTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        print("idea posted")
        
        self.delegate?.ideaPosted(with: tradeIdea, tradeIdeaTyp: tradeIdeaTyp)
    }
    
    internal func ideaDeleted(with parseObject: PFObject) {
        
        if parseObject == self.tradeIdea.parseObject {
            self.tradeIdea = nil
            self.navigationController?.popViewController(animated: true)
            
        } else if let tradeIdea = self.replyTradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            let indexPath = IndexPath(row: self.replyTradeIdeas.index(of: tradeIdea)!, section: 0)
            self.replyTradeIdeas.removeObject(tradeIdea)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        self.delegate?.ideaDeleted(with: parseObject)
    }
    
    internal func ideaUpdated(with tradeIdea: TradeIdea) {
        
        if let currentTradeIdea = self.replyTradeIdeas.find ({ $0.parseObject.objectId == tradeIdea.parseObject.objectId }), let index = self.replyTradeIdeas.index(of: currentTradeIdea) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        self.delegate?.ideaUpdated(with: tradeIdea)
    }
}