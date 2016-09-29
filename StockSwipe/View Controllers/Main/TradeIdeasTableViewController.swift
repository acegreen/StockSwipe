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
    var tradeIdeas = [TradeIdea]()
    
    var tradeIdeaQueryLimit = 25
    var isQueryingForTradeIdeas = true
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
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
            tradeIdeaPostButton.isEnabled = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getTradeIdeas() {
        
        guard let stockObject = self.stockObject else { return }
        
        isQueryingForTradeIdeas = true
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [stockObject], activityType: [Constants.ActivityType.Mention.rawValue], skip: 0, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
            
            self.isQueryingForTradeIdeas = false
            
            do {
                
                let activityObjects = try result()
                self.tradeIdeaObjects = activityObjects.lazy.map { $0["tradeIdea"] as! PFObject }
                
                self.tradeIdeas = activityObjects.map({
                    TradeIdea(parseObject: $0, completion: { (tradeidea) in
                        
                        if self.tradeIdeas.count == self.tradeIdeaObjects.count {
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                
                                self.tableView.reloadData()
                                
                                if self.refreshControl?.isRefreshing == true {
                                    self.refreshControl?.endRefreshing()
                                    self.updateRefreshDate()
                                }
                            })
                        }
                        
                    })
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        })
    }
    
    func loadMoreTradeIdeas(skip: Int) {
        
        guard let stockObject = self.stockObject else { return }
        
        if self.refreshControl?.isRefreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: [stockObject], activityType: [Constants.ActivityType.Mention.rawValue], skip: skip, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                
                self.tradeIdeaObjects += activityObjects.lazy.map { $0["tradeIdea"] as! PFObject }
                
                var indexPaths = [IndexPath]()
                for i in 0..<activityObjects.count {
                    indexPaths.append(IndexPath(row: self.tableView.numberOfRows(inSection: 0) + i, section: 0))
                }
                
                self.tradeIdeas += activityObjects.map({
                    TradeIdea(parseObject: $0, completion: { (tradeidea) in
                        
                        if self.tradeIdeas.count == self.tradeIdeaObjects.count {
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                
                                //now insert cell in tableview
                                self.tableView.insertRows(at: indexPaths, with: .none)
                                
                                if self.footerActivityIndicator?.isAnimating == true {
                                    self.footerActivityIndicator.stopAnimating()
                                    self.updateRefreshDate()
                                }
                            })
                        }
                    })
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating == true {
                    self.footerActivityIndicator.stopAnimating()
                    self.updateRefreshDate()
                }
            }
        })
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \((Date() as NSDate).formattedAsTimeAgo())"
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
        return tradeIdeaObjects.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
        cell.configureCell(with: tradeIdeas[indexPath.row], timeFormat: .short)
        cell.delegate = self
        
        return cell
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.loadMoreTradeIdeas(skip: tradeIdeaObjects.count)
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
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .new {
            let indexPath = IndexPath(row: 0, section: 0)
            self.tradeIdeaObjects.insert(tradeIdea.parseObject, at: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == parseObject.objectId }) {
            
            if let reshareOf = tradeIdea.object(forKey: "reshare_of") as? PFObject, let reshareTradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == reshareOf.objectId })  {
                
                let indexPath = IndexPath(row: self.tradeIdeaObjects.index(of: reshareTradeIdea)!, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            let indexPath = IndexPath(row: self.tradeIdeaObjects.index(of: tradeIdea)!, section: 0)
            self.tradeIdeaObjects.removeObject(tradeIdea)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if tradeIdeaObjects.count == 0 {
            self.tableView.reloadEmptyDataSet()
        }
    }
}

// DZNEmptyDataSet delegate functions

extension TradeIdeasTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if !isQueryingForTradeIdeas && tradeIdeaObjects.count == 0 {
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
        attributedDescription = NSAttributedString(string: "Be the first to post an idea for \(self.symbol)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
