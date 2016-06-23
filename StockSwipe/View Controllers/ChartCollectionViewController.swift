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
    
    func onSwitchToggleOn(on: Bool)
    
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
    
    @IBOutlet var SelectAllButton: UIBarButtonItem!
    
    @IBOutlet var CollectionView: UICollectionView!
    
    @IBOutlet var CollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet var EditButton: UIBarButtonItem!
    
    @IBAction func EditButtonPressed(sender: AnyObject) {
        
        if self.EditButton.image == UIImage(named: "edit_pen") {
            
            setEditing(true, animated: false)
            
            self.EditButton.image = UIImage(named: "edit_checkmark")
            
        } else {
            
            setEditing(false, animated: false)
            
            if self.CollectionView.indexPathsForSelectedItems()!.count != 0 {
                
                self.TrashButton.enabled = false
                
                for indexPath in self.CollectionView.indexPathsForSelectedItems()! {
                    
                    self.CollectionView.deselectItemAtIndexPath((indexPath), animated: false)
                    
                }
                
                // reload view
                self.CollectionView.reloadData()
            }
            
            self.EditButton.image = UIImage(named: "edit_pen")
            
        }
    }
    
    @IBAction func TrashButtonPressed(sender: AnyObject) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Delete!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            return
        }
        
        let selectedCoreDataObjects = (self.CollectionView.indexPathsForSelectedItems()?.map{swippeChartsdArray[$0.row]})!
        
        // Delete user from Parse (for the object were the user has Longed/Shorted)
        performDeletionOfObjects(selectedCoreDataObjects)
    }
    
    @IBAction func SelectAllButtonPressed(sender: AnyObject) {
        
        if self.SelectAllButton.title == "Select All" {
            
            self.SelectAllButton.title = "Deselect All"
            
            print("Select All button pressed")
            
            for row in 0 ..< self.CollectionView.numberOfItemsInSection(0) {
                
                let indexPathForRow: NSIndexPath = NSIndexPath(forRow: row, inSection: 0)
                
                self.CollectionView.selectItemAtIndexPath(indexPathForRow, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
                
            }
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems()!.count != 0 {
                
                self.TrashButton.enabled = true
                
            }
            
        } else {
            
            self.SelectAllButton.title = "Select All"
            
            print("Deselect All button pressed")
            
            for indexPath in self.CollectionView.indexPathsForSelectedItems()! {
                
                self.CollectionView.deselectItemAtIndexPath((indexPath), animated: false)
                
            }
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems()!.count == 0 {
                
                self.TrashButton.enabled = false
                
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        
        if editing == true {
            
            // Make it possible to select & deselect multiple cells
            self.CollectionView.allowsMultipleSelection = true
        
            self.SelectAllButton.enabled = true
            
            // reload view
            self.CollectionView.reloadData()
            
        } else {
            
            // Make it possible to select & deselect multiple cells
            self.CollectionView.allowsMultipleSelection = false
            
            self.SelectAllButton.title = "Select All"
            self.SelectAllButton.enabled = false
            self.TrashButton.enabled = false
            
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
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            cellWidth = (self.view.bounds.width - 30) / numberOfCellsHorizontally
            
            cellHeight = (cellWidth * 0.60) + Constants.chartImageTopPadding + Constants.informationViewHeight

        } else {
            
            cellWidth = chartWidth / numberOfCellsHorizontally
            
            cellHeight = cellWidth
        }
        
        CollectionViewFlowLayout.itemSize = CGSizeMake(cellWidth, cellHeight)
    }
    
    override func viewWillAppear(animated: Bool) {
        reloadViewData()
    }
    
    func reloadViewData() {
        
        // Get charts from CoreData
        swippeChartsdArray = Functions.getChartsFromCoreData()?.mutableCopy() as! [ChartModel]
        
        // Enable edit button if array exists
        if self.swippeChartsdArray.count != 0 {
            
            self.CollectionView.reloadData()
            self.EditButton.enabled = true
            
        } else if self.swippeChartsdArray.count == 0 {
            
            self.CollectionView.reloadEmptyDataSet()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Collection View Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return swippeChartsdArray.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: ChartCollectionViewCell = CollectionView.dequeueReusableCellWithReuseIdentifier("chartCollectionCellIdentifier", forIndexPath: indexPath) as! ChartCollectionViewCell

        let chartData = swippeChartsdArray[indexPath.row] 
        cell.configure(withDataSource: chartData)
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("cell selected")
        
        if self.editing {
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems()!.count != 0 {
                
                self.TrashButton.enabled = true
                
            }
            
        } else {
            
            let selectedObject = swippeChartsdArray[self.CollectionView.indexPathsForSelectedItems()!.first!.row]
            
            QueryHelper.sharedInstance.queryStockObjectsFor([selectedObject.symbol]) { (result) in
                
                do {
                    
                    let stockObjects = try result()
                    
                    for stockObject in stockObjects {
                        
                        let symbol = stockObject["Symbol"] as? String
                        let companyName = stockObject["Company"] as? String
                        let shorts: AnyObject? = stockObject["Shorted_By"]
                        let longs: AnyObject? = stockObject["Longed_By"]
                        
                        let chart = Chart(symbol: symbol, companyName: companyName, image: nil, shorts: shorts?.count, longs: longs?.count, parseObject: stockObject)
                        self.selectedChart = chart
                        
                        self.performSegueWithIdentifier("showChartDetail", sender: self)
                    }
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                        })
                    }
                }
            }
            
            self.CollectionView.deselectItemAtIndexPath(indexPath, animated: false)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("cell de-selected")
        
        if self.editing  {
            
            // Check if selection count is greater than 0, then enable trash button
            if self.CollectionView.indexPathsForSelectedItems()!.count == 0  {
                
                self.TrashButton.enabled = false
                
            }
        }
    }
    
    func performDeletionOfObjects(selectedObjects: [ChartModel]) {
        
        //Delete Objects From Parse, CoreData and DataSource(and collectionView)
        deleteUserFromParseObjectLongedShortedColumn(selectedObjects)
        
        /// TODO: Need to breka down deleteUserFromParseObjectLongedShortedColumn
    }
    
    func deleteItemsFromDataSource(selectedObjects: [ChartModel]) {
        
        // Delete from DataSource
        self.swippeChartsdArray.removeObjectsInArray(selectedObjects)
        
        // Delete from CollectionView
        if let selectedIndexPaths = self.CollectionView.indexPathsForSelectedItems() where selectedIndexPaths.count != 0 {
            self.CollectionView.deleteItemsAtIndexPaths(selectedIndexPaths)
        }
        
    }
    
    func deleteFromCoreData(selectedObjects: [ChartModel]) {
        
        // Delete from Core Data and save
        for (_, object) in selectedObjects.enumerate() {
            
            // Delete from Core Data
            Constants.context.deleteObject(object)
            
        }
        
        do {
            
            try Constants.context.save()
            
        } catch let error as NSError {
            
            print("Fetch failed: \(error.localizedDescription)")
            
            abort()
        }
    }
    
    func deleteUserFromParseObjectLongedShortedColumn(selectedObjects: [ChartModel]) {
        
        guard Functions.isUserLoggedIn(self) else { return }
        
        let symbolStringArray: [String] = extractSymbolNames(selectedObjects)
    
        let parseLocalQuery = PFQuery(className:"Stocks")
        //parseLocalQuery.fromLocalDatastore()
        parseLocalQuery.whereKey("Symbol", containedIn: symbolStringArray)
        parseLocalQuery.findObjectsInBackgroundWithBlock({ (objects, error) -> Void in
            
            if error == nil {
                
                guard objects != nil else { return }
                
                print("Successfully retrieved \(objects!.count) object")
                
                for object in objects! {
                    
                    object.removeObject(PFUser.currentUser()!, forKey: "Shorted_By")
                    object.removeObject(PFUser.currentUser()!, forKey: "Longed_By")
                    
                    object.saveEventually({ (success, error) -> Void in
//                        object.unpinInBackgroundWithBlock({ (success, error) -> Void in
//                          
//                            if success {
//                            }
//                            
//                        })
                        print("User removed object: \(object)")
                    })
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
                            
                            if self.CollectionView.indexPathsForSelectedItems()!.count == 0  {
                                
                                self.TrashButton.enabled = false
                                
                            }
                            
                            if self.swippeChartsdArray.count == 0 {
                                
                                self.EditButtonPressed(self)
                                self.EditButton.enabled = false
                                
                                self.CollectionView.reloadEmptyDataSet()
                                
                            }
                            
                        }
                })
                
            } else {
                
                // Log details of the failure
                print("Error: \(error) \(error!.userInfo)")
                
            }
        })
    }

    func extractSymbolNames (coreDataObjects: [ChartModel]) -> [String] {
        
        if coreDataObjects.isEmpty {
            
            return []
            
        } else {
            
            return coreDataObjects.map { $0.symbol }
        }
    }
}

extension ChartCollectionViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(assetIdentifier: .IdeaGuyImage)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: "No Charts!", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString = NSAttributedString(string: "You can add charts by swiping the cards LEFT or RIGHT", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
    
    // MARK: - Segue stuff
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showChartDetail" {

            let destinationView = segue.destinationViewController as! ChartDetailTabBarController
            destinationView.chart = selectedChart
        }
    }
}
