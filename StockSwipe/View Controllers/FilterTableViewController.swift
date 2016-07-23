//
//  FilterTableViewController.swift
//  
//
//  Created by Ace Green on 2015-06-26.
//
//

import UIKit

class FilterTableViewController: UITableViewController, CellType {

    enum CellIdentifier: String {
        case FiltersCell = "FiltersCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        switch section {
        case 0:
            return Constants.Symbol.Exchange.allExchanges.count
            
        case 1:
            return Constants.Symbol.Sector.allSectors.count
            
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return NSLocalizedString("Exchanges", comment: "")
            
        case 1:
            return NSLocalizedString("Sectors", comment: "")
            
        default:
            return nil
        }
        
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.grayColor()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as FiltersCell
        
        switch indexPath.section {
        case 0:
            let exchange = Constants.Symbol.Exchange.allExchanges[indexPath.row]
            cell.filtersCellLeftLabel.text = exchange.key()
        case 1:
            let sector = Constants.Symbol.Sector.allSectors[indexPath.row]
            cell.filtersCellLeftLabel.text = sector.key()
        default:
            break
        }
        
        if Constants.userDefaults.boolForKey("\(cell.textLabel!.text!)".uppercaseString) == true {
            
            cell.accessoryType = .Checkmark
            
        } else {
            
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            
            if cell.accessoryType == .Checkmark {
                
                cell.accessoryType = .None
                
                saveUserDefaults(false, cell: cell)
                
            } else {
                
                cell.accessoryType = .Checkmark
                
                saveUserDefaults(true, cell: cell)
                
            }
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            
            if cell.accessoryType == .Checkmark {
                
                cell.accessoryType = .None
                
                saveUserDefaults(false, cell: cell)
                
            } else {
                
                cell.accessoryType = .Checkmark
                
                saveUserDefaults(true, cell: cell)
                
            }
        }
    }
    
    func saveUserDefaults(value: Bool, cell: UITableViewCell) {
        
        Constants.userDefaults.setBool(value, forKey: "\(cell.textLabel!.text!)".uppercaseString)
        print("value for \(cell.textLabel!.text!)", Constants.userDefaults.boolForKey("\(cell.textLabel!.text)") as Bool)
        
    }
}
