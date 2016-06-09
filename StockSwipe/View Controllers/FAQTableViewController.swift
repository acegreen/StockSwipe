//
//  FAQTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2016-01-08.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import Parse

class FAQTableViewController: UITableViewController {
    
    let expandingCellId = "expandingCell"
    let estimatedHeight: CGFloat = 150
    let topInset: CGFloat = 20
    
    var questionObjects = [PFObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.contentInset.top = topInset
        tableView.estimatedRowHeight = estimatedHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let faqQuery = PFQuery(className: "FAQ")
        faqQuery.orderByAscending("index")
        
        faqQuery.findObjectsInBackgroundWithBlock { (questions, error) -> Void in
            
            guard error == nil else { return }
            guard questions != nil else { return }
            
            self.questionObjects = questions!
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - TableView Functions

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.questionObjects.count
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if let selectedIndex = tableView.indexPathForSelectedRow where selectedIndex == indexPath {
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ExpandingCell {
                tableView.beginUpdates()
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                cell.changeCellStatus(false)
                tableView.endUpdates()
            }
            
            return nil
        }
        
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! ExpandingCell
        cell.changeCellStatus(true)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ExpandingCell {
            cell.changeCellStatus(false)
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("FAQCell", forIndexPath: indexPath) as! ExpandingCell
        
        let questionAtIndex = self.questionObjects[indexPath.row]
        
        cell.title = questionAtIndex.objectForKey("question") as? String
        cell.detail = questionAtIndex.objectForKey("answer") as? String

        return cell
    }
}
