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
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        self.getReplyTradeIdeas()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200.0
        
        self.getReplyTradeIdeas()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReplyTradeIdeas() {
        
        guard let tradeIdea = self.tradeIdea else { return }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("reply_to", object: tradeIdea.parseObject, skip: 0, limit: nil) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                self.replyTradeIdeas = []
                for tradeIdeaObject: PFObject in tradeIdeasObjects {
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: tradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.replyTradeIdeas.append(tradeIdea)
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let indexSet = NSIndexSet(index: 1)
                    self.tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let indexSet = NSIndexSet(index: 1)
                    self.tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        }

    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \(NSDate().formattedAsTimeAgo())"
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        }
        
        return replyTradeIdeas.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: IdeaCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(tradeIdea, timeFormat: .Long)
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.ReplyIdeaCell.rawValue, forIndexPath: indexPath) as! IdeaCell
            cell.configureCell(replyTradeIdeas[indexPath.row], timeFormat: .Short)
            cell.delegate = self
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            
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
            self.navigationController?.popViewControllerAnimated(true)
        } else if let tradeIdea = self.replyTradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            let indexPath = NSIndexPath(forRow: self.replyTradeIdeas.indexOf(tradeIdea)!, inSection: 0)
            self.replyTradeIdeas.removeObject(tradeIdea)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        self.delegate?.ideaDeleted(with: parseObject)
    }
}
