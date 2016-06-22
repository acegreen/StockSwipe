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

class TradeIdeasTableViewController: UITableViewController, ChartDetailDelegate, CellType, IdeaPostDelegate {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
    }
    
    enum SegueIdentifier: String {
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
        case PostSegueIdentifier = "PostSegueIdentifier"
    }
    
    var symbol: String!
    var companyName: String?
    var stockObject: PFObject?
    
    var tradeIdeas = [TradeIdea]()
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        self.getTradeIdeas(skip: 0)
    }
    
    @IBOutlet var tradeIdeaPostButton: UIBarButtonItem!
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parentTabBarController = self.tabBarController as! ChartDetailTabBarController
        symbol = parentTabBarController.symbol
        companyName = parentTabBarController.companyName
        stockObject = parentTabBarController.chart.parseObject
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        self.getTradeIdeas(skip: 0)
        
        // Hide post button if symbol is not available
        if self.stockObject == nil {
            tradeIdeaPostButton.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTradeIdeas(skip skip: Int) {
        
        guard let stockObject = self.stockObject else { return }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("stock", object: stockObject, skip: skip) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                self.tradeIdeas = []
                for tradeIdeaObject: PFObject in tradeIdeasObjects {
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.tradeIdeas.append(tradeIdea)
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    
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
    
    func loadMoreTradeIdeas(skip skip: Int) {
        
        guard let stockObject = self.stockObject else { return }
        
        if self.refreshControl?.refreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("stock", object: stockObject, skip: skip) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    for tradeIdeaObject: PFObject in tradeIdeasObjects {
                        
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                        
                        //add datasource object here for tableview
                        self.tradeIdeas.append(tradeIdea)
                        
                        //now insert cell in tableview
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.tradeIdeas.count - 1, inSection: 0)], withRowAnimation: .None)
                    }
                    
                    if self.footerActivityIndicator?.isAnimating() == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                    
                    self.updaterefreshDate()
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating() == true {
                    self.footerActivityIndicator.stopAnimating()
                }
            }
        }
    }
    
    func ideaPosted(with tradeIdea: TradeIdea) {
        
        self.tradeIdeas.insert(tradeIdea, atIndex: 0)
        self.tableView.reloadData()
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tradeIdeas.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.IdeaCell.rawValue, forIndexPath: indexPath) as! IdeaCell
        cell.configureIdeaCell(tradeIdeas[indexPath.row])
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.loadMoreTradeIdeas(skip: tradeIdeas.count)
        }
    }
}

extension TradeIdeasTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, SegueHandlerType {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! ProfileContainerController
            
            // Just a workaround.. There should be a cleaner way to sort this out 
            destinationViewController.navigationItem.rightBarButtonItem = nil
            
            let cell = sender as! IdeaCell
            destinationViewController.user = cell.user
            
        case .PostSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.symbol = self.symbol
            ideaPostViewController.delegate =  self
            break
        }
    }
    
//    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
//        
//        if identifier
//    }
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(assetIdentifier: .ideaBulbBigImage)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No Ideas?", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString!
        attributedDescription = NSAttributedString(string: "Be the first to post an idea for \(self.symbol)", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
