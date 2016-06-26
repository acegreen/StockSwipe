//
//  NewsTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
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
    
    var tradeIdea: TradeIdea!
    
    var tradeIdeas = [TradeIdea]()
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        self.getReplyTradeIdeas()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100.0
        
        self.getReplyTradeIdeas()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReplyTradeIdeas() {
        
        guard let tradeIdea = self.tradeIdea else { return }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("reply_to", object: tradeIdea.parseObject, skip: 0) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                self.tradeIdeas = []
                for tradeIdeaObject: PFObject in tradeIdeasObjects {
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.tradeIdeas.append(tradeIdea)
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let indexSet = NSIndexSet(index: 1)
                    self.tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    self.updaterefreshDate()
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.refreshControl?.refreshing == true {
                    self.refreshControl?.endRefreshing()
                }
            }
        }

    }
    
    func updaterefreshDate() {
        
        let refreshDateFormatter = NSDateFormatter()
        refreshDateFormatter.dateStyle = .LongStyle
        refreshDateFormatter.timeStyle = .ShortStyle
        
        let title: String = "Last Update: \(refreshDateFormatter.stringFromDate(NSDate()))"
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
        
        return tradeIdeas.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: IdeaCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureIdeaCell(tradeIdea)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.ReplyIdeaCell.rawValue, forIndexPath: indexPath) as! IdeaCell
            cell.configureIdeaCell(tradeIdeas[indexPath.row])
        }
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            
            let cell = sender as! IdeaCell
            destinationViewController.tradeIdea = cell.tradeIdea
        }
    }
}
