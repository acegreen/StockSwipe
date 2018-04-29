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

class StreamTableViewController: TWTRTimelineViewController, TWTRTweetViewDelegate, ChartDetailDelegate {
    
    var symbol: String!
    var companyName: String!
    
    var isQueryingForTweets = false
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tweetViewDelegate = self
        
        //Setup Appearance
        //TWTRTweetView.appearance().primaryTextColor = Constants.stockSwipeFontColor
        TWTRTweetView.appearance().linkTextColor = Constants.stockSwipeGreenColor
        
        let parentTabBarController = self.tabBarController as! CardDetailTabBarController
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
            
            let querySymbol = self.symbol.replacingOccurrences(of: "^", with: "")
            self.dataSource = TWTRSearchTimelineDataSource(searchQuery: "$\(querySymbol) OR \(companyName)", apiClient: client)
            self.showTweetActions = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    // TWTRTweetViewDelegate
    func tweetView(_ tweetView: TWTRTweetView, didTap url: URL) {
        Functions.presentSafariBrowser(with: url)
    }
    
    func tweetView(_ tweetView: TWTRTweetView, didTapProfileImageFor user: TWTRUser) {
        Functions.presentSafariBrowser(with: user.profileURL)
    }
    
//    func tweetView(tweetView: TWTRTweetView, didTapImage image: UIImage, withURL imageURL: NSURL) {
//        Functions.presentSafariBrowser(imageURL)
//    }
    
//    func tweetView(tweetView: TWTRTweetView, didTapVideoWithURL videoURL: NSURL) {
//        Functions.presentSafariBrowser(videoURL)
//    }
    
}

// DZNEmptyDataSet delegate functions
extension StreamTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        if countOfTweets() == 0 {
            return true
        }
        return false
    }

    
//    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
//        let image = UIImage(named: "twitter_logo")
//        return image
//    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No Tweets!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let symbolOrCompanyName = self.symbol != nil ? self.symbol! : self.companyName!
        let attributedDescription: NSAttributedString!
        attributedDescription = NSAttributedString(string: "No one seems to be tweeting about \(symbolOrCompanyName)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.paragraphStyle: paragraphStyle])
        
        return attributedDescription
        
    }
}
