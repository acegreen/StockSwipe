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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return NSLocalizedString("Exchanges", comment: "")
            
        case 1:
            return NSLocalizedString("Sectors", comment: "")
            
        default:
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.gray
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        
        if Constants.userDefaults.bool(forKey: "\(cell.textLabel!.text!)".uppercased()) == true {
            
            cell.accessoryType = .checkmark
            
        } else {
            
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            
            if cell.accessoryType == .checkmark {
                
                cell.accessoryType = .none
                
                saveUserDefaults(false, cell: cell)
                
            } else {
                
                cell.accessoryType = .checkmark
                
                saveUserDefaults(true, cell: cell)
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            
            if cell.accessoryType == .checkmark {
                
                cell.accessoryType = .none
                
                saveUserDefaults(false, cell: cell)
                
            } else {
                
                cell.accessoryType = .checkmark
                
                saveUserDefaults(true, cell: cell)
                
            }
        }
    }
    
    func saveUserDefaults(_ value: Bool, cell: UITableViewCell) {
        
        Constants.userDefaults.set(value, forKey: "\(cell.textLabel!.text!)".uppercased())
        print("value for \(cell.textLabel!.text!)", Constants.userDefaults.bool(forKey: "\(cell.textLabel!.text)") as Bool)
        
    }
}
