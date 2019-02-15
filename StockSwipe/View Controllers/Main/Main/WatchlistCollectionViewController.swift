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
    
    var cards = [Card]()
    
    var cellWidth: CGFloat!
    var cellHeight: CGFloat!
    
    private var transition: CardTransition?
    
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
        
        let selectedCoreDataObjects = (self.CollectionView.indexPathsForSelectedItems?.map{cards[($0 as NSIndexPath).row]})!
        
        // Delete user from Parse (for the object were the user has Longed/Shorted)
        performDeletionOfObjects(selectedCoreDataObjects)
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
        
        self.reloadViewData()
        
        // register to listen to when AddToWatchlist happens
        NotificationCenter.default.addObserver(self, selector: #selector(WatchlistCollectionViewController.addCardToWatchlist), name: Notification.Name("AddToWatchlist"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reloadViewData() {
        
        // Get charts from CoreData
        Functions.makeCardsFromCoreData { cards in
            do {
                
                let cards = try cards()
                self.cards = cards
                
                DispatchQueue.main.async {
                    // Enable edit button if array exists
                    if self.cards.count != 0 {
                        self.CollectionView.reloadData()
                        self.EditButton.isEnabled = true
                    } else if self.cards.count == 0 {
                        self.CollectionView.reloadEmptyDataSet()
                    }
                }
                
            } catch {
                // TODO: handle error
            }
        }
    }
    
    @objc func addCardToWatchlist(_ notification: Notification) {
        if let symbol = notification.userInfo?["symbol"] as? String {
            
            Functions.makeCardsFromCoreData(symbols: [symbol]) { cards in
                do {
                    let cards = try cards()
                    self.cards.insert(contentsOf: cards, at: 0)
                    
                    DispatchQueue.main.async {
                        // Enable edit button if array exists
                        if self.cards.count != 0 {
                            self.CollectionView.reloadData()
                            self.EditButton.isEnabled = true
                        } else if self.cards.count == 0 {
                            self.CollectionView.reloadEmptyDataSet()
                        }
                    }
                    
                } catch {
                    // TODO: handle error
                }
            }
        }
    }
    
    // MARK: - Collection View Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: WatchlistCardCollectionViewCell = CollectionView.dequeueReusableCell(withReuseIdentifier: "WatchlistCardCollectionCellIdentifier", for: indexPath) as! WatchlistCardCollectionViewCell
        
        let card = cards[indexPath.row]
        cell.configure(with: card)
        
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
            
            let selectedCard = cards[(self.CollectionView.indexPathsForSelectedItems!.first! as NSIndexPath).row]
            self.CollectionView.deselectItem(at: indexPath, animated: false)
            
            performCustomSegue(cell: cell, card: selectedCard)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        print("cell de-selected")
        
        if self.isEditing  {
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems!.count == 0  {
                self.TrashButton.isEnabled = false
            }
        }
    }
    
    func performDeletionOfObjects(_ selectedCards: [Card]) {
        
        //Delete Objects From Parse, CoreData and DataSource(and collectionView)
        
        guard Functions.isUserLoggedIn(presenting: self) else { return }
        guard let currentUser = PFUser.current() else { return }
        
        let symbolStringArray: [String] = extractSymbolNames(selectedCards)
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: symbolStringArray) { (result) in
            
            do {
                
                let stockObjects = try result()
                print("Successfully retrieved \(stockObjects.count) object")
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: stockObjects, activityType: [Constants.ActivityType.StockLong.rawValue, Constants.ActivityType.StockShort.rawValue], skip: 0, limit: 0, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObjects = try result()
                        
                        PFObject.deleteAll(inBackground: activityObjects, block: { (success, error) in
                            
                            if success {
                                
                                for stockObject: PFObject in stockObjects {
                                    
                                    let symbol = stockObject.object(forKey: "Symbol") as! String
                                    
                                    if let selectedCard = selectedCards.find({ $0.symbol == symbol }), let cardModel = selectedCard.cardModel, let userChoice = Constants.UserChoices(rawValue: cardModel.userChoice) {
                                        
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
                                
                                // Delete from CoreData
                                self.deleteFromCoreData(selectedCards)
                                
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
                                            self.CollectionView.reloadEmptyDataSet()
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
    
    func deleteItemsFromDataSource(_ selectedCards: [Card]) {
        
        // Delete from DataSource
        self.cards.removeObjectsInArray(selectedCards)
        
        // Delete from CollectionView
        if let selectedIndexPaths = self.CollectionView.indexPathsForSelectedItems , selectedIndexPaths.count != 0 {
            self.CollectionView.deleteItems(at: selectedIndexPaths)
        }
        
    }
    
    func deleteFromCoreData(_ selectedCards: [Card]) {
        
        // Delete from Core Data and save
        for (_, card) in selectedCards.enumerated() {
            if let cardModel = card.cardModel {
                Constants.context.delete(cardModel)
            }
        }
        
        do {
            
            try Constants.context.save()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
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
                vc.addToWatchlistButton.isHidden = true
            })
        }
    }
}
