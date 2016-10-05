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
    
    enum QueryType {
        case newOrOld
        case update
    }
    
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
    
    let queue = DispatchQueue(label: "Query Queue")
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getReplyTradeIdeas(queryType: .update)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getReplyTradeIdeas(queryType: .newOrOld)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReplyTradeIdeas(queryType: QueryType) {
        
        guard let tradeIdea = self.tradeIdea else { return }
        
        var queryOrder: QueryHelper.QueryOrder
        var mostRecentTradeIdeaCreationDate: Date?
        
        switch queryType {
        case .newOrOld:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
        case .update:
            queryOrder = .ascending
            mostRecentTradeIdeaCreationDate = self.replyTradeIdeas[0].createdAt
        }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "reply_to", object: tradeIdea.parseObject, skip: self.replyTradeIdeas.count, limit: nil, order: queryOrder, creationDate: mostRecentTradeIdeaCreationDate) { (result) in
            
            do {
                
                let tradeIdeaObjects = try result()
                
                guard tradeIdeaObjects.count > 0 else {
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadEmptyDataSet()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }
                    self.updateRefreshDate()
                    
                    return
                }
                
                tradeIdeaObjects.map({ tradeIdeaObject in
                
                    self.queue.sync {
                        
                        TradeIdea(parseObject: tradeIdeaObject, completion: { (tradeIdea) in
                            
                            if let tradeIdea = tradeIdea {
                                
                                DispatchQueue.main.async {
                                    
                                    switch queryType {
                                    case .newOrOld:
                                        
                                        // append more trade ideas
                                        self.replyTradeIdeas.append(tradeIdea)
                                        
                                        // insert cell in tableview
                                        let indexPath = IndexPath(row: self.replyTradeIdeas.count - 1, section: 1)
                                        self.tableView.insertRows(at: [indexPath], with: .none)
                                    case .update:
                                        
                                        // append more trade ideas
                                        self.replyTradeIdeas.insert(tradeIdea, at: 0)
                                        
                                        // insert cell in tableview
                                        let indexPath = IndexPath(row: 0, section: 1)
                                        self.tableView.insertRows(at: [indexPath], with: .none)
                                    }
                                }
                            }
                        })
                    }
                })
                
                // end refresh and add time stamp
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                self.updateRefreshDate()
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
            }
        }
    }

    func updateRefreshDate() {
        
        let title: String = "Last Update: " + (Date() as NSDate).formattedAsTimeAgo()
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.white
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
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: IdeaCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(with: self.tradeIdea, timeFormat: .long)
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
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
            self.getReplyTradeIdeas(queryType: .newOrOld)
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
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        print("idea posted")
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
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
}
