//
//  WatchlistCollectionViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-30.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import QuartzCore
import CoreData
import Parse
import DZNEmptyDataSet
import Reachability

protocol ChartCollectionCellDataSource {
    var symbol: String { get }
    var image: UIImage? { get }
    var longs: Int { get }
    var shorts: Int { get }
    var userChoice: String { get }
}

protocol ChartCollectionCellDelegate {
    
    func onSwitchToggleOn(_ on: Bool)
    
    var switchColor: UIColor { get }
    var textColor: UIColor { get }
    var font: UIFont { get }
}

class WatchlistCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var activityObjects = [PFObject]()
    private var cards = [Card?]()
    
    private var cellWidth: CGFloat!
    private var cellHeight: CGFloat!
    
    private var transition: CardTransition?
    
    let reachability = Reachability()
    
    @IBOutlet var navigationBar: UINavigationBar!
    
    @IBOutlet var TrashButton: UIBarButtonItem!
    
    @IBOutlet var searchButton: UIBarButtonItem!
    
    @IBOutlet var SelectAllButton: UIBarButtonItem!
    
    @IBOutlet var CollectionView: UICollectionView!
    
    @IBOutlet var CollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet var EditButton: UIBarButtonItem!
    @IBAction func EditButtonPressed(_ sender: AnyObject) {
        
        if self.EditButton.image == UIImage(named: "edit_pen") {
            setEditing(true, animated: false)
            self.EditButton.image = UIImage(named: "edit_checkmark")
            
        } else {
            
            setEditing(false, animated: false)
            if self.CollectionView.indexPathsForSelectedItems!.count != 0 {
                
                self.TrashButton.isEnabled = false
                
                for indexPath in self.CollectionView.indexPathsForSelectedItems! {                    
                    self.CollectionView.deselectItem(at: (indexPath), animated: false)
                }
                
                // reload view
                self.CollectionView.reloadData()
            }
            
            self.EditButton.image = UIImage(named: "edit_pen")
        }
    }
    
    @IBAction func TrashButtonPressed(_ sender: AnyObject) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Delete!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        guard let selectedCards = (self.CollectionView.indexPathsForSelectedItems?.map{cards[($0 as NSIndexPath).row]}), let cards = selectedCards as? [Card] else { return }
        
        // Delete user from Parse (for the object were the user has Longed/Shorted)
        performDeletionOfObjects(cards)
    }
    
    @IBAction func SelectAllButtonPressed(_ sender: AnyObject) {
        
        if self.SelectAllButton.title == "Select All" {
            
            self.SelectAllButton.title = "Deselect All"
            
            print("Select All button pressed")
            
            for row in 0 ..< self.CollectionView.numberOfItems(inSection: 0) {
                let indexPathForRow: IndexPath = IndexPath(row: row, section: 0)
                self.CollectionView.selectItem(at: indexPathForRow, animated: true, scrollPosition: UICollectionView.ScrollPosition())
            }
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems!.count != 0 {
                self.TrashButton.isEnabled = true
            }
            
        } else {
            
            self.SelectAllButton.title = "Select All"
            
            print("Deselect All button pressed")
            
            for indexPath in self.CollectionView.indexPathsForSelectedItems! {
                self.CollectionView.deselectItem(at: (indexPath), animated: false)
            }
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems!.count == 0 {
                self.TrashButton.isEnabled = false
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if editing == true {
            
            // Make it possible to select & deselect multiple cells
            self.CollectionView.allowsMultipleSelection = true
            self.SelectAllButton.isEnabled = true
            
            // reload view
            self.CollectionView.reloadData()
            
        } else {
            
            // Make it possible to select & deselect multiple cells
            self.CollectionView.allowsMultipleSelection = false
            self.SelectAllButton.title = "Select All"
            self.SelectAllButton.isEnabled = false
            self.TrashButton.isEnabled = false
            
            // reload view
            self.CollectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CollectionView.delaysContentTouches = false
        
        // setup CollectionViewLayout
        CollectionViewFlowLayout.minimumInteritemSpacing = 10
        CollectionViewFlowLayout.minimumLineSpacing = 10
        CollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            cellWidth = (self.view.bounds.width - 30) / numberOfCellsHorizontally
            cellHeight = (cellWidth * 0.60)
            
        } else {
            cellWidth = cardWidth / numberOfCellsHorizontally
            cellHeight = cellWidth
        }
        
        CollectionViewFlowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        self.handleReachability()
        
        // register to listen to when AddToWatchlist happens
        NotificationCenter.default.addObserver(self, selector: #selector(WatchlistCollectionViewController.addCardToWatchlist), name: Notification.Name("AddToWatchlist"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        self.reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func addCardToWatchlist(_ notification: Notification) {
        
        if let card = notification.userInfo?["card"] as? Card, let index = cards.index(of: card) {
            self.removeItemsFromDataSource(at: index)
        }
        
        guard let currentUser = PFUser.current(), let card = notification.userInfo?["card"] as? Card else { return }
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: [card.parseObject], activityType: [Constants.ActivityType.AddToWatchlistLong.rawValue, Constants.ActivityType.AddToWatchlistShort.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                guard let firstActivity = try result().first else { return }
                self.activityObjects.insert(firstActivity, at: 0)
                self.cards.insert(card, at: 0)
                
                DispatchQueue.main.async {
                    if self.cards.count != 0 {
                        self.EditButton.isEnabled = true
                    }
                    self.CollectionView.reloadData()
                }
                
            } catch {
                //TODO: handle error
            }
        })
    }
    
    // MARK: - Collection View Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activityObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: WatchlistCardCollectionViewCell = CollectionView.dequeueReusableCell(withReuseIdentifier: "WatchlistCardCollectionCellIdentifier", for: indexPath) as! WatchlistCardCollectionViewCell
        
        if let cardAtIndex = cards.get(indexPath.row), let card = cardAtIndex {
            cell.configure(with: card)
        } else {
            cell.clear()
            self.fetch(forItemAtIndex: indexPath.row)
        }
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! WatchlistCardCollectionViewCell
        
        if self.isEditing {
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems!.count != 0 {
                self.TrashButton.isEnabled = true
            }
            
        } else {
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("Can't Access Card!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
                return
            }
            
            guard let firstSelectedIndexPath = self.CollectionView.indexPathsForSelectedItems?.first else { return }
            guard let selectedCard = cards[firstSelectedIndexPath.row] else { return }
            self.CollectionView.deselectItem(at: indexPath, animated: false)
            
            performCustomSegue(cell: cell, card: selectedCard)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if self.isEditing  {
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems?.count == 0  {
                self.TrashButton.isEnabled = false
            }
        }
    }
    
    func reloadViewData() {
        guard let currentUser = PFUser.current() else { return }
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.AddToWatchlistLong.rawValue, Constants.ActivityType.AddToWatchlistShort.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                self.activityObjects.removeAll()
                self.cards.removeAll()
                self.activityObjects += try result()
                self.cards = Array(repeating: nil, count: self.activityObjects.count)
                
                DispatchQueue.main.async {
                    self.CollectionView.reloadData()
                    if self.cards.count != 0 {
                        self.EditButton.isEnabled = true
                    }
                }
                
            } catch {
                //TODO: handle error
            }
        })
    }
    
    func performDeletionOfObjects(_ selectedCards: [Card]) {
        
        //Delete Objects From Parse and DataSource(and collectionView)
        
        guard Functions.isUserLoggedIn(presenting: self) else { return }
        guard let currentUser = PFUser.current() else { return }
        
        let symbolStringArray: [String] = extractSymbolNames(selectedCards)
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: symbolStringArray) { (result) in
            
            do {
                
                let stockObjects = try result()
                print("Successfully retrieved \(stockObjects.count) object")
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: stockObjects, activityType: [Constants.ActivityType.StockLong.rawValue, Constants.ActivityType.StockShort.rawValue, Constants.ActivityType.AddToWatchlistLong.rawValue, Constants.ActivityType.AddToWatchlistShort.rawValue], skip: 0, limit: 0, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObjects = try result()
                        
                        PFObject.deleteAll(inBackground: activityObjects, block: { (success, error) in
                            
                            if success {
                                
                                for stockObject: PFObject in stockObjects {
                                    
                                    let symbol = stockObject["Symbol"] as! String
                                    
                                    if let selectedCard = selectedCards.find({ $0.symbol == symbol }), let userChoice = selectedCard.userChoice {
                                        
                                        switch userChoice {
                                        case .LONG:
                                            stockObject.incrementKey("longCount", byAmount: -1)
                                        case .SHORT:
                                            stockObject.incrementKey("shortCount", byAmount: -1)
                                        default:
                                            break
                                        }
                                        
                                        stockObject.saveEventually()
                                    }
                                }
                                
                                // Remove from datasource and collectionView
                                self.CollectionView.performBatchUpdates({ () -> Void in
                                    
                                    // Delete from Data Source & CollectionView
                                    self.deleteItemsFromDataSource(selectedCards)
                                    
                                }, completion: { (finished: Bool) -> Void in
                                    
                                    if finished == true {
                                        
                                        // reload view
                                        self.CollectionView.reloadData()
                                        
                                        if self.CollectionView.indexPathsForSelectedItems!.count == 0  {
                                            self.TrashButton.isEnabled = false
                                        }
                                        
                                        if self.cards.count == 0 {
                                            self.EditButtonPressed(self)
                                            self.EditButton.isEnabled = false
                                            self.CollectionView.reloadData()
                                        }
                                    }
                                    
                                    self.EditButtonPressed(self)
                                })
                            }
                        })
                    } catch {
                        //TODO: handle error
                    }
                })
            } catch {
                //TODO: handle error
            }
        }
    }
    
    func removeItemsFromDataSource(at index: Int) {
        self.activityObjects.remove(at: index)
        self.cards.remove(at: index)
    }
    
    func deleteItemsFromDataSource(_ selectedCards: [Card]) {
        
        // Delete from DataSource
        selectedCards.forEach { card in
            guard let index = self.cards.index(of: card) else { return }
            self.removeItemsFromDataSource(at: index)
        }
        
        // Delete from CollectionView
        if let selectedIndexPaths = self.CollectionView.indexPathsForSelectedItems , selectedIndexPaths.count != 0 {
            self.CollectionView.deleteItems(at: selectedIndexPaths)
        }
    }
    
    func extractSymbolNames (_ coreDataObjects: [Card]) -> [String] {
        
        if coreDataObjects.isEmpty {
            return []
        } else {
            return coreDataObjects.map { $0.symbol }
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension WatchlistCollectionViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("prefetchRowsAt \(indexPaths)")
        indexPaths.forEach { self.fetch(forItemAtIndex: $0.row) }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("cancelPrefetchingForRowsAt \(indexPaths)")
    }
    
    func fetch(forItemAtIndex index: Int) {
        
        guard let currentUser = PFUser.current() else { return }
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.AddToWatchlistLong.rawValue, Constants.ActivityType.AddToWatchlistShort.rawValue], skip: index, limit: 1, includeKeys: ["stock"], completion: { (result) in
            
            do {
                
                guard let activityObject = try result().first else { return }
                
                if let stockObject = activityObject["stock"] as? PFObject, let activityType = activityObject["activityType"] as? String {
                    Functions.fetchEODData(for: stockObject["Symbol"] as! String, completion: { result in
                        
                        do {
                            let result = try result()
                            
                            let card = Card(parseObject: stockObject, eodHistoricalData: result.eodHistoricalResult, eodFundamentalsData: result.eodFundamentalsResult)
                            
                            let activityType = Constants.ActivityType(rawValue: activityType)
                            
                            switch activityType {
                            case .AddToWatchlistLong?:
                                card.userChoice = .LONG
                            case .AddToWatchlistShort?:
                                card.userChoice = .SHORT
                            default: break
                            }
                            self.cards[index] = card
                            
                            DispatchQueue.main.async {
                                let indexPath = IndexPath(row: index, section: 0)
                                self.CollectionView.reloadItems(at: [indexPath])
                            }
                        } catch {
                            //TODO: handle error
                        }
                    })
                }
                
            } catch {
                //TODO: handle error
            }
        })
    }
}

extension WatchlistCollectionViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // DZNEmptyDataSet delegate functions
    
//    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!{
//        return UIImage(assetIdentifier: .ideaGuyImage)
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: "Watchlist", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: "You can add cards by taping the Add To Watchlist button or long pressing a cloud symbol", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        return attributedDescription
        
    }
    
    // MARK: - Segue
    
    func performCustomSegue(cell: WatchlistCardCollectionViewCell, card: Card) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Access Card!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
    
        // Get current frame on screen
        let currentCellFrame = cell.layer.presentation()!.frame
        
        // Convert current frame to screen's coordinates
        let cardPresentationFrameOnScreen = cell.superview!.convert(currentCellFrame, to: nil)
        
        // Get card frame without transform in screen's coordinates  (for the dismissing back later to original location)
        let cardFrameWithoutTransform = { () -> CGRect in
            let center = cell.center
            let size = cell.bounds.size
            let r = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return cell.superview!.convert(r, to: nil)
        }()
        
        let vc = Constants.Storyboards.cardDetailStoryboard.instantiateViewController(withIdentifier: "CardDetailViewController") as! CardDetailViewController
        vc.card = card
        let params = CardTransition.Params(fromCardFrame: cardPresentationFrameOnScreen,
                                           fromCardFrameWithoutTransform: cardFrameWithoutTransform,
                                           fromCell: cell)
        self.transition = CardTransition(params: params)
        vc.transitioningDelegate = self.transition
        
        // If `modalPresentationStyle` is not `.fullScreen`, this should be set to true to make status bar depends on presented vc.
        vc.modalPresentationCapturesStatusBarAppearance = true
        vc.modalPresentationStyle = .custom
        
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: {
            })
        }
    }
}

extension WatchlistCollectionViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            self.reloadViewData()
        }
        
        self.reachability?.whenUnreachable = { _ in
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}
