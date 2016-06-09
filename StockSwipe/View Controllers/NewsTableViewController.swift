//
//  NewsTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import SwiftyJSON

class NewsTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var symbol: String!
    var companyName: String!
    
    var jsonResults = JSON.null
    var news = [News]()
    
    var isQueryingResults: Bool = true
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parentTabBarController = self.tabBarController as! ChartDetailTabBarController
        symbol = parentTabBarController.symbol
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        self.refreshControl?.addTarget(self, action: #selector(NewsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        if jsonResults == nil && self.companyName != nil {
            handleRefresh(self.refreshControl!)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return jsonResults.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("newsCell", forIndexPath: indexPath) as! NewsTableViewCell
        
        let newsAtIndex = self.news[indexPath.row]
        
        if let newsImageAtIndex = newsAtIndex.image {
            
            cell.newsImage.image = newsImageAtIndex
            
        }
        
        if let newsTitleAtIndex = newsAtIndex.title {
            
            cell.newsTitle.text = newsTitleAtIndex
        }
        
        if let newsPublisher = newsAtIndex.publisher {
            
            cell.newsPublisher.text = newsPublisher
        }
        
        if let newsPublishedDate = newsAtIndex.publishedDate {
            
            cell.newsReleaseDate.text = newsPublishedDate
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        let newsAtIndex = self.news[indexPath.row]
        
        if let newsLink = newsAtIndex.url {
            
             UIApplication.sharedApplication().openURL(NSURL(string: newsLink)!)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == jsonResults.count - 1 && jsonResults.count < 64 {
            
            getGoogleNewsdata(jsonResults.count)
            
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            return 125
            
        } else {
            
            return 100
        }
        
    }
    
    func getGoogleNewsdata(start: Int) {
        
        self.isQueryingResults = true
        
        if self.refreshControl?.refreshing == false {
            
            self.footerActivityIndicator.startAnimating()
        }
        
        guard let formattedCompanyName = companyName.URLEncodedString() else { return }
        
        if let companyNewsURL: NSURL = NSURL(string: "https://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=\(formattedCompanyName)&rsz=8&start=\(start)&ned=us") {
            
            let companyNewsSession = NSURLSession.sharedSession()
            
            let task = companyNewsSession.dataTaskWithURL(companyNewsURL, completionHandler: { (companyNewsData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.footerActivityIndicator.stopAnimating()
                        self.refreshControl!.endRefreshing()
                        
                        self.isQueryingResults = false
                    })
                    
                } else {
                    
                    if companyNewsData != nil {
                        
                        let newJsonResults = JSON(data: companyNewsData!)["responseData"]["results"]
                        
                        if newJsonResults.count != 0 {
                            
                            print("newJsonResults.count = ", newJsonResults.count)
                            
                            if self.jsonResults.count != 0 {
                                
                                self.jsonResults = JSON(self.jsonResults.arrayObject! + newJsonResults.arrayObject!)
                                
                                print("jsonResults.count = ", self.jsonResults.count)
                                
                            } else if self.jsonResults.count == 0 {
                                
                                self.jsonResults = newJsonResults
                                
                                print("jsonResults.count = ", self.jsonResults.count)
                            }
                            
                            for (index,_) in newJsonResults.enumerate() {
                                
                                var newImage: UIImage!
                                var newDecodedTitle: String!
                                var newUrl: String!
                                var newPublisher: String!
                                var newPublishedDate: String!
                                
                                // Get title
                                
                                if let newsTitle = newJsonResults[index]["titleNoFormatting"].string {
                                    
                                    newDecodedTitle = newsTitle.decodeEncodedString()
                                }
                                
                                // Get URL
                                
                                if let newsLink = newJsonResults[index]["unescapedUrl"].string {
                                    
                                    newUrl = newsLink
                                }
                                
                                // Get Publisher
                                
                                if let newsPublisher = newJsonResults[index]["publisher"].string {
                                    
                                    newPublisher = newsPublisher
                                }
                                
                                // Get Published Date
                                
                                if let newsPublishedDate = newJsonResults[index]["publishedDate"].string {
                                    
                                    let publishedDateFormatter = NSDateFormatter()
                                    publishedDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                                    
                                    let formattedDate: NSDate = publishedDateFormatter.dateFromString(newsPublishedDate)!
                                    
                                    newPublishedDate = formattedDate.formattedAsTimeAgo()
                                }
                                
                                // Get image
                                
                                if let companyNewsImagesUrl = newJsonResults[index]["image"]["url"].string {
                                    
                                    if let companyNewsImagesUrl: NSURL = NSURL(string: companyNewsImagesUrl) {
                                        
                                        let companyNewsImagesSession = NSURLSession.sharedSession()
                                        
                                        let task = companyNewsImagesSession.dataTaskWithURL(companyNewsImagesUrl, completionHandler: { (companyNewsImagesData, response, error) -> Void in
                                            
                                            if error != nil {
                                                
                                                print("error: \(error!.localizedDescription): \(error!.userInfo)")
                                                
                                                newImage = UIImage(named: "no_image")
                                                                                            
                                                let newNews = News(image: newImage, title: newDecodedTitle, details: nil, url: newUrl, publisher: newPublisher, publishedDate: newPublishedDate)
                                                self.news.append(newNews)
                                                
                                                return
                                                
                                            } else {
                                                
                                                if companyNewsImagesData != nil {
                                                    
                                                    newImage = UIImage(data: companyNewsImagesData!)
                                                    
                                                    let newNews = News(image: newImage, title: newDecodedTitle, details: nil, url: newUrl, publisher: newPublisher, publishedDate: newPublishedDate)
                                                    self.news.append(newNews)
                                                    
                                                    self.checkIfNewsIsComplete()
                                                    
                                                } else {
                                                    
                                                    newImage = UIImage(named: "no_image")
                                                    
                                                    let newNews = News(image: newImage, title: newDecodedTitle, details: nil, url: newUrl, publisher: newPublisher, publishedDate: newPublishedDate)
                                                    self.news.append(newNews)
                                                    
                                                    self.checkIfNewsIsComplete()
                                                }
                                            }
                                        })
                                        
                                        task.resume()
                                        
                                    } else {
                                        
                                        newImage = UIImage(named: "no_image")
                                        
                                        let newNews = News(image: newImage, title: newDecodedTitle, details: nil, url: newUrl, publisher: newPublisher, publishedDate: newPublishedDate)
                                        self.news.append(newNews)
                                        
                                        self.checkIfNewsIsComplete()
                                    }
                                    
                                } else {
                                    
                                    newImage = UIImage(named: "no_image")
                                    
                                    let newNews = News(image: newImage, title: newDecodedTitle, details: nil, url: newUrl, publisher: newPublisher, publishedDate: newPublishedDate)
                                    self.news.append(newNews)
                                    
                                    self.checkIfNewsIsComplete()
                                }
                            }
                            
                        } else {
                            
                            print("newJsonResults is nil")
                            
                            self.isQueryingResults = false
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                self.footerActivityIndicator.stopAnimating()
                                self.refreshControl!.endRefreshing()
                                self.tableView.reloadData()
                            })
                        }
                    }
                }
            })
            
            task.resume()
            
        } else {
            
            print("URL is nil")
            
            self.isQueryingResults = false
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.footerActivityIndicator.stopAnimating()
                self.refreshControl!.endRefreshing()
                self.tableView.reloadData()
            })
        }
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        // Empty data sources
        jsonResults = JSON.null
        news = [News]()
        
        getGoogleNewsdata(0)
        
        let refreshDateFormatter = NSDateFormatter()
        refreshDateFormatter.dateStyle = .LongStyle
        refreshDateFormatter.timeStyle = .ShortStyle
        
        refreshControl.attributedTitle = NSAttributedString(string: "Last Update: \(refreshDateFormatter.stringFromDate(NSDate()))")
    }
    
    func checkIfNewsIsComplete() {
        
        self.isQueryingResults = false
        
        if self.news.count == self.jsonResults.count {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.footerActivityIndicator.stopAnimating()
                self.refreshControl!.endRefreshing()
                self.tableView.reloadData()
                
            })
        }
    }
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(named: "news_big")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        if self.isQueryingResults {
            
            attributedTitle = NSAttributedString(string: "Hold on!", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
            
        } else {
            
            attributedTitle = NSAttributedString(string: "No News!", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        }
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString!
        
        if self.isQueryingResults {
            
            attributedDescription = NSAttributedString(string: "While we load more news", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
            
        } else {
            
            attributedDescription = NSAttributedString(string: "There are no related news for this stock", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        }
        
        return attributedDescription
        
    }
}
