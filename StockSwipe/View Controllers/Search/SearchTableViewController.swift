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
    var searchResults = [PFObject]()
    
    var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.hidesNavigationBarDuringPresentation = false
        controller.definesPresentationContext = true
        controller.dimsBackgroundDuringPresentation = false
        controller.searchBar.searchBarStyle = .minimal
        controller.searchBar.tintColor = Constants.SSColors.green
        controller.searchBar.sizeToFit()
        return controller
    }()
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        
        self.searchController.isActive = false
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign delegate
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        // Configure table
        self.tableView.tableHeaderView = searchController.searchBar
        searchController.searchResultsUpdater = self
        
        // Load recent searches
        getUserRecentSearches()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Make search bar becomefirstresponder
        //self.searchController.searchBar.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchController.isActive {
        case true:
            return searchResults.count
        case false:
            return recentSearches.count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch searchController.isActive {
        case true:
            if searchController.searchBar.text?.isEmpty == true {
                return "Top Searches"
            }
        case false:
            if recentSearches.count > 0 {
                return "Recent Searches"
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var objectAtIndex: PFObject?
        switch searchController.isActive {
        case true:
            objectAtIndex = searchResults.get(indexPath.row)
        case false:
            objectAtIndex = recentSearches.get(indexPath.row)
        }
        
        if let objectAtIndex = objectAtIndex, objectAtIndex.isKind(of: PFUser.self) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
            let user = User(userObject: objectAtIndex as! PFUser)
            
            cell.configureCell(with: user)
            
            return cell
            
        } else if let objectAtIndex = objectAtIndex, objectAtIndex.isKind(of: PFObject.self) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
            cell.textLabel?.text = objectAtIndex.object(forKey: "Symbol") as? String
            cell.detailTextLabel?.text = objectAtIndex.object(forKey: "Company") as? String
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(SearchTableViewController.longPress(_:)))
            cell.addGestureRecognizer(longPressRecognizer)
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
            cell.textLabel?.text = "N/A"
            cell.detailTextLabel?.text = "N/A"
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let objectAtIndex: PFObject
        switch searchController.isActive {
        case true:
            searchController.isActive = false
            objectAtIndex = searchResults[indexPath.row]
        case false:
            objectAtIndex = recentSearches[indexPath.row]
        }
        
        self.updateUserRecentSearch(objectAtIndex)
        
        if objectAtIndex.isKind(of: PFUser.self) {
            presentProfile(objectAtIndex as! PFUser)
        } else {
            presentChartDetail(objectAtIndex)
        }
    }
    
    func searchStocksAndUsers(_ searchText: String?) {
        
        guard let search = searchText else { return }
        
        PFCloud.callFunction(inBackground: "searchStocksAndUsersFor", withParameters: ["search": search]) { (results, error) -> Void in
            
            guard error == nil else { return }
            guard let results = results as? [PFObject] else { return }
            self.searchResults = results
            
            self.tableView.reloadData()
        }
    }
    
    func getUserRecentSearches() {
        
        guard let currentUser = PFUser.current() else { return }
        self.recentSearches.removeAll()
        if let currentUserRecentSearches = currentUser["recentSearches"] as? [PFObject] {
            let recentSearchFilteredBySymbols = currentUserRecentSearches.filter { !$0.isKind(of: PFUser.self) }
            let recentSearchFilteredByUsers = currentUserRecentSearches.filter { $0.isKind(of: PFUser.self) }
            
            // This is a hack since there is a bug (might have been fixed in newer parse server) where you can't fetch two things of PFObject
            // eg PFUser & PFObject
            PFObject.fetchAllIfNeeded(inBackground: recentSearchFilteredBySymbols) { (currentUserRecentSearches, error) in
                
                if let currentUserRecentSearches = currentUserRecentSearches as? [PFObject] {
                    self.recentSearches += currentUserRecentSearches
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                
                PFObject.fetchAllIfNeeded(inBackground: recentSearchFilteredByUsers) { (currentUserRecentSearches, error) in
                    
                    if let currentUserRecentSearches = currentUserRecentSearches as? [PFObject] {
                        self.recentSearches += currentUserRecentSearches
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func updateUserRecentSearch(_ object: PFObject) {
        
        guard let currentUser = PFUser.current() else { return }
        
        if let existingObject = recentSearches.find( { $0.objectId == object.objectId } ) {
            recentSearches.moveItem(fromIndex: recentSearches.index(of: existingObject)!, toIndex: 0)
        } else {
            if self.recentSearches.count < 10 {
                recentSearches.insert(object, at: 0)
            } else {
                recentSearches.removeLast()
                recentSearches.insert(object, at: 0)
            }
        }
        
        currentUser["recentSearches"] = recentSearches
        currentUser.saveEventually()
    }
    
    func presentChartDetail(_ stockObject: PFObject) {
        
        self.dismiss(animated: true) {
            
            let cardDetailTabBarController  = Constants.Storyboards.cardDetailStoryboard.instantiateViewController(withIdentifier: "CardDetailTabBarController") as! CardDetailTabBarController
            
            Functions.makeCard(for: stockObject.object(forKey: "Symbol") as! String) { card in
                do {
                    let card = try card()
                    DispatchQueue.main.async {
                        cardDetailTabBarController.card = card
                        UIApplication.topViewController()?.present(cardDetailTabBarController, animated: true, completion: nil)
                    }
                } catch {
                    if let error = error as? QueryHelper.QueryError {
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
            }
        }
    }
    
    func presentProfile(_ user: PFUser) {
        
        self.dismiss(animated: true) {
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
            let user = User(userObject: user)
            profileContainerController.user = user
            
            UIApplication.topViewController()?.show(profileContainerController, sender: self)
        }
    }
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
                return
            }
            
            guard let cell = sender.view as? UITableViewCell, let cellIndex = self.tableView.indexPath(for: cell) else { return }
            
            var stockObjectAtIndex: PFObject!
            switch searchController.isActive {
            case true:
                stockObjectAtIndex = searchResults[cellIndex.row]
                
            case false:
                stockObjectAtIndex = recentSearches[cellIndex.row]
            }
            
            Functions.makeCard(for: stockObjectAtIndex.object(forKey: "Symbol") as! String) { card in
                do {
                    let card = try card()
                    DispatchQueue.main.async {
                        Functions.promptAddToWatchlist(card, registerChoice: true) { (choice) in }
                    }
                } catch {
                    if let error = error as? QueryHelper.QueryError {
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
            }
        }
    }
}

extension SearchTableViewController: UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        searchStocksAndUsers(searchController.searchBar.text)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //searchController.active = false
        //self.tableView.reloadData()
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.showsCancelButton = false
    }
}
