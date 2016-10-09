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
    
    var tradeIdeas = [TradeIdea]()
    var isQueryingForTradeIdeas = false
    var tradeIdeasLastRefreshDate: Date!
    
    let queue = DispatchQueue(label: "Query Queue")
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getTradeIdeas(queryType: .update)
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
        
        // Hide post button if symbol is not available
        if self.stockObject == nil {
            tradeIdeaPostButton.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if self.tradeIdeas.count  == 0 {
            getTradeIdeas(queryType: .new)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTradeIdeas(queryType: QueryHelper.QueryType) {
        
        guard !isQueryingForTradeIdeas else { return }
        guard let stockObject = self.stockObject else { return }
        
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
            
            skip = self.tradeIdeas.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = tradeIdeasLastRefreshDate
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [stockObject], activityType: [Constants.ActivityType.Mention.rawValue], skip: skip, limit: QueryHelper.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                
                var tradeIdeaObjects = [PFObject]()
                for activityObject in activityObjects {
                    if let tradeIdeaObject = activityObject["tradeIdea"] as? PFObject {
                        tradeIdeaObjects.append(tradeIdeaObject)
                    }
                }
                
                guard tradeIdeaObjects.count > 0 else {
                    
                    self.isQueryingForTradeIdeas = false
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadEmptyDataSet()
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
                
                Functions.makeTradeIdeas(from: tradeIdeaObjects, sorted: true, completion: { (tradeIdeas) in
                    
                    DispatchQueue.main.async {
                        
                        switch queryType {
                        case .new:
                            
                            self.tradeIdeas = tradeIdeas
                            
                            // reload table
                            self.tableView.reloadData()
                            
                        case .older:
                            
                            // append more trade ideas
                            let currentCount = self.tradeIdeas.count
                            self.tradeIdeas += tradeIdeas
                            
                            // insert cell in tableview
                            self.tableView.beginUpdates()
                            for (i,_) in tradeIdeas.enumerated() {
                                let indexPath = IndexPath(row: currentCount + i, section: 0)
                                self.tableView.insertRows(at: [indexPath], with: .none)
                            }
                            self.tableView.endUpdates()
                            
                        case .update:
                            
                            // append more trade ideas
                            self.tableView.beginUpdates()
                            for tradeIdea in tradeIdeas {
                                self.tradeIdeas.insert(tradeIdea, at: 0)
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
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
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
            NSForegroundColorAttributeName : UIColor.white
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tradeIdeas.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
        
        guard let tradeIdeaAtIndex = self.tradeIdeas.get(indexPath.row) else { return cell }
        cell.configureCell(with: tradeIdeaAtIndex, timeFormat: .short)
        cell.delegate = self
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.getTradeIdeas(queryType: .older)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.tradeIdea = cell.tradeIdea
            
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
    
    internal func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
            
        let indexPath = IndexPath(row: 0, section: 0)
        self.tradeIdeas.insert(tradeIdea, at: 0)
        self.tableView.insertRows(at: [indexPath], with: .automatic)
        
        self.tableView.reloadEmptyDataSet()
    }
    
    internal func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            
            if let reshareOf = tradeIdea.nestedTradeIdea, let reshareTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == reshareOf.parseObject.objectId })  {
                
                let indexPath = IndexPath(row: self.tradeIdeas.index(of: reshareTradeIdea)!, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            let indexPath = IndexPath(row: self.tradeIdeas.index(of: tradeIdea)!, section: 0)
            self.tradeIdeas.removeObject(tradeIdea)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if tradeIdeas.count == 0 {
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    internal func ideaUpdated(with tradeIdea: TradeIdea) {
        if let currentTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == tradeIdea.parseObject.objectId }), let index = self.tradeIdeas.index(of: currentTradeIdea) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

// DZNEmptyDataSet delegate functions

extension TradeIdeasTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if !isQueryingForTradeIdeas && tradeIdeas.count == 0 {
            return true
        }
        return false
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(assetIdentifier: .noIdeaBulbImage)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No Ideas", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: NSAttributedString!
        attributedDescription = NSAttributedString(string: "Be the first to post an idea for " + self.symbol, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
