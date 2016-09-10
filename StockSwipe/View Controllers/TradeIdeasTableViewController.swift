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

class TradeIdeasTableViewController: UITableViewController, ChartDetailDelegate, CellType, SegueHandlerType {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case PostIdeaSegueIdentifier = "PostIdeaSegueIdentifier"
    }
    
    var symbol: String!
    var companyName: String!
    var stockObject: PFObject?
    
    var tradeIdeaObjects = [PFObject]()
    var tradeIdeaQueryLimit = 25
    var isQueryingForTradeIdeas = true
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        self.getTradeIdeas()
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
        
        Functions.setupConfigParameter("TRADEIDEAQUERYLIMIT") { (parameterValue) -> Void in
            self.tradeIdeaQueryLimit = parameterValue as? Int ?? 25
            self.getTradeIdeas()
        }
        
        // Hide post button if symbol is not available
        if self.stockObject == nil {
            tradeIdeaPostButton.enabled = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTradeIdeas() {
        
        guard let stockObject = self.stockObject else { return }
        
        isQueryingForTradeIdeas = true
        QueryHelper.sharedInstance.queryActivityFor(nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [stockObject], activityType: [Constants.ActivityType.Mention.rawValue], skip: 0, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
            
            self.isQueryingForTradeIdeas = false
            
            do {
                
                let activityObjects = try result()
                self.tradeIdeaObjects = activityObjects.lazy.map { $0["tradeIdea"] as! PFObject }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        })
    }
    
    func loadMoreTradeIdeas(skip skip: Int) {
        
        guard let stockObject = self.stockObject else { return }
        
        if self.refreshControl?.refreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryActivityFor(nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [stockObject], activityType: [Constants.ActivityType.Mention.rawValue], skip: skip, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                
                self.tradeIdeaObjects += activityObjects.lazy.map { $0["tradeIdea"] as! PFObject }
                
                var indexPaths = [NSIndexPath]()
                for i in 0..<activityObjects.count {
                    indexPaths.append(NSIndexPath(forRow: self.tableView.numberOfRowsInSection(0) + i, inSection: 0))
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //now insert cell in tableview
                    self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                    
                    if self.footerActivityIndicator?.isAnimating() == true {
                        self.footerActivityIndicator.stopAnimating()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating() == true {
                    self.footerActivityIndicator.stopAnimating()
                    self.updateRefreshDate()
                }
            }
        })
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
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tradeIdeaObjects.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
        cell.configureCell(tradeIdeaObjects[indexPath.row], timeFormat: .Short)
        cell.delegate = self
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.loadMoreTradeIdeas(skip: tradeIdeaObjects.count)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.tradeIdea = cell.tradeIdea
            
        case .PostIdeaSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.stockObject = self.stockObject
            ideaPostViewController.tradeIdeaType = .New
            ideaPostViewController.delegate =  self
        }
    }
}

extension TradeIdeasTableViewController: IdeaPostDelegate {
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .New {
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tradeIdeaObjects.insert(tradeIdea.parseObject, atIndex: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == parseObject.objectId }) {
            
            if let reshareOf = tradeIdea.objectForKey("reshare_of") as? PFObject, let reshareTradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == reshareOf.objectId })  {
                
                let indexPath = NSIndexPath(forRow: self.tradeIdeaObjects.indexOf(reshareTradeIdea)!, inSection: 0)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            
            let indexPath = NSIndexPath(forRow: self.tradeIdeaObjects.indexOf(tradeIdea)!, inSection: 0)
            self.tradeIdeaObjects.removeObject(tradeIdea)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        if tradeIdeaObjects.count == 0 {
            self.tableView.reloadEmptyDataSet()
        }
    }
}

// DZNEmptyDataSet delegate functions

extension TradeIdeasTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        if !isQueryingForTradeIdeas && tradeIdeaObjects.count == 0 {
            return true
        }
        return false
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(assetIdentifier: .noIdeaBulbImage)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No Ideas", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
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
