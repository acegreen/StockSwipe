//
//  SearchTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/13/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class SearchTableViewController: UITableViewController {
    
    var recentSearches = [PFObject]()
    var searchArray = [PFObject]()
    
    var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = false
        controller.definesPresentationContext = true
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.searchBarStyle = .Minimal
        controller.searchBar.tintColor = Constants.stockSwipeGreenColor
        controller.searchBar.sizeToFit()
        return controller
    }()
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        
        self.searchController.active = false
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegate
        self.searchController.delegate = self

        // Configure table
        self.tableView.tableHeaderView = searchController.searchBar
        searchController.searchResultsUpdater = self
        
        // Load recent searches
        getUserRecentSearches()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Make search bar becomefirstresponder
        //self.searchController.searchBar.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchController.active {
        case true:
            return searchArray.count
        case false:
            return recentSearches.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SearchCell", forIndexPath: indexPath)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(SearchTableViewController.longPress(_:)))
        cell.addGestureRecognizer(longPressRecognizer)
        
        switch searchController.active {
        case true:
            
            let parseObject = searchArray[indexPath.row]
            cell.textLabel?.text = parseObject.objectForKey("Symbol") as? String
            return cell
        case false:
            let parseObject = recentSearches[indexPath.row]
            cell.textLabel?.text = parseObject.objectForKey("Symbol") as? String
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if searchController.active {
            searchController.active = false
            presentChartDetail(self.searchArray[indexPath.row])
            
        } else {
            presentChartDetail(self.recentSearches[indexPath.row])
        }
    }
    
    func search(searchText: String?) {
        let query = PFQuery(className: "Stocks")
        query.cancel()
        if let searchText = searchText where !searchText.isEmpty {
            query.whereKey("Symbol", containsString: searchText.uppercaseString)
        }
        query.orderByDescending("longCount")
        query.addDescendingOrder("shortCount")
        query.limit = 10
        
        query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            
            if let results = results {
                self.searchArray = results
            }
            self.tableView.reloadData()
        }
    }
    
    func getUserRecentSearches() {
        guard let currentUser = PFUser.currentUser() else { return }

        if let currentUserRecentSearches = currentUser["recentSearches"] as? [PFObject] {
            
            PFObject.fetchAllIfNeededInBackground(currentUserRecentSearches) { (currentUserRecentSearches, error) in
                
                if let currentUserRecentSearches = currentUserRecentSearches as? [PFObject] {
                    self.recentSearches = currentUserRecentSearches
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func updateUserRecentSearch(object: PFObject) {
        guard let currentUser = PFUser.currentUser() else { return }
        
        if let existingObject = recentSearches.find( { $0.objectId == object.objectId } ) {
            recentSearches.moveItem(fromIndex: recentSearches.indexOf(existingObject)!, toIndex: 0)
        } else {
            if self.recentSearches.count < 10 {
                recentSearches.insert(object, atIndex: 0)
            } else {
                recentSearches.removeLast()
                recentSearches.insert(object, atIndex: 0)
            }
        }
        self.tableView.reloadData()
        currentUser["recentSearches"] = recentSearches
        currentUser.saveEventually()
    }
    
    func presentChartDetail(stockObject: PFObject) {
        
        self.dismissViewControllerAnimated(true) {
            
            self.updateUserRecentSearch(stockObject)
            
            let chartDetailTabBarController  = Constants.storyboard.instantiateViewControllerWithIdentifier("ChartDetailTabBarController") as! ChartDetailTabBarController
            
            let symbol = stockObject["Symbol"] as? String
            let companyName = stockObject["Company"] as? String
            let shortCount = stockObject.objectForKey("shortCount") as? Int
            let longCount = stockObject.objectForKey("longCount") as? Int
            
            let chart = Chart(symbol: symbol, companyName: companyName, image: nil, shortCount: shortCount, longCount: longCount, parseObject: stockObject)
            
            chartDetailTabBarController.chart = chart
            UIApplication.topViewController()?.presentViewController(chartDetailTabBarController, animated: true, completion: nil)
        }
    }
    
    func longPress(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            print("UIGestureRecognizerState Began")
            
            guard Functions.isConnectedToNetwork() else {
                
                SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
                return
            }
            
            var stockObjectAtIndex: PFObject!
            
            if let cell = sender.view as? UITableViewCell {
                let cellIndex = self.tableView.indexPathForCell(cell)!
                switch searchController.active {
                case true:
                    stockObjectAtIndex = searchArray[cellIndex.row]
                    
                case false:
                    stockObjectAtIndex = recentSearches[cellIndex.row]
                }
            }
            
            let symbol = stockObjectAtIndex["Symbol"] as? String
            let companyName = stockObjectAtIndex["Company"] as? String
            let shortCount = stockObjectAtIndex.objectForKey("shortCount") as? Int
            let longCount = stockObjectAtIndex.objectForKey("longCount") as? Int
            
            let chart = Chart(symbol: symbol, companyName: companyName, image: nil, shortCount: shortCount, longCount: longCount, parseObject: stockObjectAtIndex)
            
            QueryHelper.sharedInstance.queryChartImage(chart.symbol, completion: { (result) in
                
                do {
                    
                    let chartImage = try result()
                    
                    chart.image = chartImage
                    
                    
                } catch {
                    
                    print(error)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.CustomImag(imageFile: "add_watchlist"), dismissTime: nil, buttonTitle:"SHORT", buttonColor:UIColor.redColor() , otherButtonTitle: "LONG", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                        
                        guard Functions.isUserLoggedIn(self) else { return }
                        
                        if !isOtherButton {
                            
                            Functions.registerUserChoice(chart, with: .LONG)
                            
                        } else if isOtherButton {
                            
                            Functions.registerUserChoice(chart, with: .SHORT)
                        }
                    }
                    
                })
                
                // Index to Spotlight
                Functions.addToSpotlight(chart, domainIdentifier: "com.stockswipe.stocksQueried")
            })
        }
    }
}

extension SearchTableViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        search(searchController.searchBar.text)
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
}