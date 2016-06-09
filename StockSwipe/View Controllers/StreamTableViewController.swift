//
//  StreamTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-02.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import TwitterKit
import DZNEmptyDataSet
import SafariServices

class StreamTableViewController: TWTRTimelineViewController, TWTRTweetViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var symbol: String!
    var companyName: String?
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tweetViewDelegate = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        self.tableView.tableFooterView = UIView()
        
        let parentTabBarController = self.tabBarController as! ChartDetailTabBarController
        symbol = parentTabBarController.symbol
        companyName = parentTabBarController.companyName
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        if symbol != nil {
            // Request Twitter Feed
            let client = TWTRAPIClient()
            
            let querySymbol = self.symbol.stringByReplacingOccurrencesOfString("^", withString: "")
            self.dataSource = TWTRSearchTimelineDataSource(searchQuery: "$\(querySymbol) OR \(companyName)", APIClient: client)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    // TWTRTweetViewDelegate
    
    func tweetView(tweetView: TWTRTweetView, shouldDisplayDetailViewController controller: TWTRTweetDetailViewController) -> Bool {
        return false
    }
    
    func tweetView(tweetView: TWTRTweetView, didTapURL url: NSURL) {
        Functions.presentSafariBrowser(url)
    }
    
    func tweetView(tweetView: TWTRTweetView, didTapProfileImageForUser user: TWTRUser) {
        Functions.presentSafariBrowser(user.profileURL)
    }
    
    func tweetView(tweetView: TWTRTweetView, didTapImage image: UIImage, withURL imageURL: NSURL) {
        Functions.presentSafariBrowser(imageURL)
    }
    
    func tweetView(tweetView: TWTRTweetView, didTapVideoWithURL videoURL: NSURL) {
        Functions.presentSafariBrowser(videoURL)
    }
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(named: "twitter_big")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No Tweets!", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString!
        
        attributedDescription = NSAttributedString(string: "No one seems to be tweeting about \(self.symbol)", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
}
