//
//  FAQTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2016-01-08.
//  Copyright © 2016 Ace Green. All rights reserved.
//

import UIKit
import Parse

class FAQTableViewController: UITableViewController, CellType {
    
    enum CellIdentifier: String {
        case ExpandingCell = "ExpandingCell"
    }
    
    let estimatedHeight: CGFloat = 150
    let topInset: CGFloat = 20
    
    var questionObjects = [PFObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.contentInset.top = topInset
        tableView.estimatedRowHeight = estimatedHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        let faqQuery = PFQuery(className: "FAQ")
        faqQuery.order(byAscending: "index")
        
        faqQuery.findObjectsInBackground { (questions, error) -> Void in
            
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.questionObjects.count
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if let selectedIndex = tableView.indexPathForSelectedRow , selectedIndex == indexPath {
            
            if let cell = tableView.cellForRow(at: indexPath) as? ExpandingCell {
                tableView.beginUpdates()
                tableView.deselectRow(at: indexPath, animated: true)
                cell.changeCellStatus(false)
                tableView.endUpdates()
            }
            
            return nil
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ExpandingCell
        cell.changeCellStatus(true)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ExpandingCell {
            cell.changeCellStatus(false)
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ExpandingCell
        
        let questionAtIndex = self.questionObjects[indexPath.row]
        
        cell.title = questionAtIndex.object(forKey: "question") as? String
        cell.detail = questionAtIndex.object(forKey: "answer") as? String

        return cell
    }
}
