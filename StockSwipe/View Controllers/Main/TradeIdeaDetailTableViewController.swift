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
    
    var tradeIdea: TradeIdea! {
        didSet {
            let indexSet = IndexSet(integer: 0)
            self.tableView.reloadSections(indexSet, with: .automatic)
        }
    }
    
    var replyTradeIdeaObjects = [PFObject]()
    var replyTradeIdeas = [TradeIdea]()
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        self.getReplyTradeIdeas()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getReplyTradeIdeas()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getReplyTradeIdeas() {
        
        guard let tradeIdea = self.tradeIdea else { return }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "reply_to", object: tradeIdea.parseObject, skip: 0, limit: nil) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                self.replyTradeIdeaObjects = tradeIdeasObjects
                
                self.replyTradeIdeas = tradeIdeasObjects.map({
                    TradeIdea(parseObject: $0, completion: { (tradeidea) in
                        
                        if self.replyTradeIdeas.count == tradeIdeasObjects.count {
                            
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
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    let indexSet = IndexSet(integer: 1)
                    self.tableView.reloadSections(indexSet, with: .automatic)
                    
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                DispatchQueue.main.async(execute: { () -> Void in
                    let indexSet = IndexSet(integer: 1)
                    self.tableView.reloadSections(indexSet, with: .automatic)
                    
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        }

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
        return 150
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: IdeaCell!
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(with: self.tradeIdea, timeFormat: .long)
            cell.delegate = self
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.ReplyIdeaCell.rawValue, for: indexPath) as! IdeaCell
            cell.configureCell(with: replyTradeIdeas[indexPath.row], timeFormat: .short)
            cell.delegate = self
        }
        
        return cell
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
        } else if let tradeIdea = self.replyTradeIdeaObjects.find ({ $0.objectId == parseObject.objectId }) {
            let indexPath = IndexPath(row: self.replyTradeIdeaObjects.index(of: tradeIdea)!, section: 0)
            self.replyTradeIdeaObjects.removeObject(tradeIdea)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        self.delegate?.ideaDeleted(with: parseObject)
    }
}
