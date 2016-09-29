//
//  ChartCollectionViewController.swift
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

class ChartCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var blureffect: UIBlurEffect!
    var blurView: UIVisualEffectView!
    
    var swippeChartsdArray = [ChartModel]()
    var selectedChart: Chart!
    
    var cellWidth: CGFloat!
    var cellHeight: CGFloat!
    
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
        
        let selectedCoreDataObjects = (self.CollectionView.indexPathsForSelectedItems?.map{swippeChartsdArray[($0 as NSIndexPath).row]})!
        
        // Delete user from Parse (for the object were the user has Longed/Shorted)
        performDeletionOfObjects(selectedCoreDataObjects)
    }
    
    @IBAction func SelectAllButtonPressed(_ sender: AnyObject) {
        
        if self.SelectAllButton.title == "Select All" {
            
            self.SelectAllButton.title = "Deselect All"
            
            print("Select All button pressed")
            
            for row in 0 ..< self.CollectionView.numberOfItems(inSection: 0) {
                
                let indexPathForRow: IndexPath = IndexPath(row: row, section: 0)
                
                self.CollectionView.selectItem(at: indexPathForRow, animated: true, scrollPosition: UICollectionViewScrollPosition())
                
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
        
        // setup CollectionViewLayout
        CollectionViewFlowLayout.minimumInteritemSpacing = 10
        CollectionViewFlowLayout.minimumLineSpacing = 10
        CollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            cellWidth = (self.view.bounds.width - 30) / numberOfCellsHorizontally
            
            cellHeight = (cellWidth * 0.60) + Constants.chartImageTopPadding + Constants.informationViewHeight
            
        } else {
            
            cellWidth = chartWidth / numberOfCellsHorizontally
            
            cellHeight = cellWidth
        }
        
        CollectionViewFlowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadViewData()
    }
    
    func reloadViewData() {
        
        // Get charts from CoreData
        guard let coreDataCharts = Functions.getChartsFromCoreData() else { return }
        swippeChartsdArray = coreDataCharts
        
        // Enable edit button if array exists
        if self.swippeChartsdArray.count != 0 {
            
            self.CollectionView.reloadData()
            self.EditButton.isEnabled = true
            
        } else if self.swippeChartsdArray.count == 0 {
            
            self.CollectionView.reloadEmptyDataSet()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Collection View Methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return swippeChartsdArray.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: ChartCollectionViewCell = CollectionView.dequeueReusableCell(withReuseIdentifier: "chartCollectionCellIdentifier", for: indexPath) as! ChartCollectionViewCell
        
        let chartData = swippeChartsdArray[indexPath.row]
        cell.configure(withDataSource: chartData)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("cell selected")
        
        if self.isEditing {
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems!.count != 0 {
                
                self.TrashButton.isEnabled = true
                
            }
            
        } else {
            
            let selectedObject = swippeChartsdArray[(self.CollectionView.indexPathsForSelectedItems!.first! as NSIndexPath).row]
            self.CollectionView.deselectItem(at: indexPath, animated: false)
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
                return
            }
            
            QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [selectedObject.symbol]) { (result) in
                
                do {
                    
                    let stockObjects = try result()
                    
                    for stockObject in stockObjects {
                        
                        let chart = Chart(parseObject: stockObject)
                        self.selectedChart = chart
                        
                        self.performSegue(withIdentifier: "showChartDetail", sender: self)
                    }
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        })
                    }
                }
            }
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
    
    func performDeletionOfObjects(_ selectedObjects: [ChartModel]) {
        
        //Delete Objects From Parse, CoreData and DataSource(and collectionView)
        deleteUserFromParseObjectLongedShortedColumn(selectedObjects)
        
        /// TODO: Need to breka down deleteUserFromParseObjectLongedShortedColumn
    }
    
    func deleteItemsFromDataSource(_ selectedObjects: [ChartModel]) {
        
        // Delete from DataSource
        self.swippeChartsdArray.removeObjectsInArray(selectedObjects)
        
        // Delete from CollectionView
        if let selectedIndexPaths = self.CollectionView.indexPathsForSelectedItems , selectedIndexPaths.count != 0 {
            self.CollectionView.deleteItems(at: selectedIndexPaths)
        }
        
    }
    
    func deleteFromCoreData(_ selectedObjects: [ChartModel]) {
        
        // Delete from Core Data and save
        for (_, object) in selectedObjects.enumerated() {
            
            // Delete from Core Data
            Constants.context.delete(object)
            
        }
        
        do {
            
            try Constants.context.save()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
    }
    
    func deleteUserFromParseObjectLongedShortedColumn(_ selectedObjects: [ChartModel]) {
        
        guard Functions.isUserLoggedIn(self) else { return }
        guard let currentUser = PFUser.current() else { return }
        
        let symbolStringArray: [String] = extractSymbolNames(selectedObjects)
        
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: symbolStringArray) { (result) in
            
            do {
                
                let stockObjects = try result()
                
                print("Successfully retrieved \(stockObjects.count) object")
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: stockObjects, activityType: [Constants.ActivityType.StockLong.rawValue, Constants.ActivityType.StockShort.rawValue], skip: 0, limit: 0, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObjects = try result()
                        
                        PFObject.deleteAll(inBackground: activityObjects, block: { (success, error) in
                            
                            if success {
                                
                                for stockObject: PFObject in stockObjects {
                                    
                                    let symbol = stockObject.object(forKey: "Symbol") as! String
                                    
                                    if let selectedObjectModel = selectedObjects.find({ $0.symbol == symbol }), let userChoice = Constants.UserChoices(rawValue: selectedObjectModel.userChoice) {
                                        
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
                                self.deleteFromCoreData(selectedObjects)
                                
                                // Remove from datasource and collectionView
                                self.CollectionView.performBatchUpdates({ () -> Void in
                                    
                                    // Delete from Data Source & CollectionView
                                    self.deleteItemsFromDataSource(selectedObjects)
                                    
                                    }, completion: { (finished: Bool) -> Void in
                                        
                                        if finished == true {
                                            
                                            // reload view
                                            self.CollectionView.reloadData()
                                            
                                            if self.CollectionView.indexPathsForSelectedItems!.count == 0  {
                                                
                                                self.TrashButton.isEnabled = false
                                                
                                            }
                                            
                                            if self.swippeChartsdArray.count == 0 {
                                                
                                                self.EditButtonPressed(self)
                                                self.EditButton.isEnabled = false
                                                
                                                self.CollectionView.reloadEmptyDataSet()
                                                
                                            }
                                            
                                        }
                                })

                            }
                        })
                    } catch {
                        
                    }
                })
            } catch {
                
            }
        }
    }
    
    func extractSymbolNames (_ coreDataObjects: [ChartModel]) -> [String] {
        
        if coreDataObjects.isEmpty {
            
            return []
            
        } else {
            
            return coreDataObjects.map { $0.symbol }
        }
    }
}

extension ChartCollectionViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // DZNEmptyDataSet delegate functions
    
//    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
//        
//        return UIImage(assetIdentifier: .ideaGuyImage)
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: "No Charts", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: "You can add charts by swiping the cards LEFT or RIGHT", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
    
    // MARK: - Segue stuff
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showChartDetail" {
            
            let destinationView = segue.destination as! ChartDetailTabBarController
            destinationView.chart = selectedChart
        }
    }
}
