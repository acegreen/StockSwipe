//
//  TodayViewController.swift
//  StockSwipeWidget
//
//  Created by Ace Green on 2015-10-11.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import NotificationCenter
import WordCloud
import SwiftyJSON

class TodayViewController: UIViewController, NCWidgetProviding, CloudLayoutOperationDelegate {
        
    var cloudColors:[UIColor] = [UIColor.whiteColor()]
    var cloudFontName = "HelveticaNeue"
    var cloudLayoutOperationQueue: NSOperationQueue!
    var cloudWords = [CloudWord]()
 
    var trendingStocksJSON = JSON.null
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSizeMake(320, 300);
        
        cloudLayoutOperationQueue = NSOperationQueue()
        cloudLayoutOperationQueue.name = "Cloud layout operation queue"
        cloudLayoutOperationQueue.maxConcurrentOperationCount = 1
        
        if cloudWords.count == 0 {
            requestStockTwitsTrendingStocks()
        }
    }
    
    //    deinit {
    //
    //        cloudLayoutOperationQueue.cancelAllOperations()
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - <CloudLayoutOperationDelegate>
    
    func insertWord(word: String, pointSize: CGFloat,color: Int, center: CGPoint, vertical isVertical: Bool, tappable: Bool) {
        
        let wordButton: UIButton = UIButton(type: UIButtonType.System)
        wordButton.setTitle(word, forState: UIControlState.Normal)
        wordButton.titleLabel?.textAlignment = NSTextAlignment.Center
        wordButton.setTitleColor(self.cloudColors[color < self.cloudColors.count ? color : 0], forState: UIControlState.Normal)
        wordButton.titleLabel?.font = UIFont(name: cloudFontName, size: pointSize)
        wordButton.sizeToFit()
        var wordButtonRect: CGRect = wordButton.frame
        wordButtonRect.size.width = (((CGRectGetWidth(wordButtonRect) + 3) / 2)) * 2
        wordButtonRect.size.height = (((CGRectGetHeight(wordButtonRect) + 3) / 2)) * 2
        wordButton.frame = wordButtonRect
        wordButton.center = center
        
        if tappable {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TodayViewController.wordTapped(_:)))
            wordButton.addGestureRecognizer(tapGestureRecognizer)
        }
        
        if isVertical {
            wordButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        }
        
        self.view.addSubview(wordButton)
    }
    
    #if DEBUG
    func insertBoundingRect(rect: CGRect) {
    let boundingRect: CALayer = CALayer()
    boundingRect.frame = rect
    boundingRect.borderColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5).CGColor
    boundingRect.borderWidth = 1
    self.view.layer.addSublayer(boundingRect)
    }
    #endif
    
    // MARK: - <UIContentContainer>
    
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        
//        weak var weakSelf = self
//        
//        coordinator.animateAlongsideTransition({(id__unused context) -> Void in
//            let strongSelf = weakSelf
//            strongSelf!.layoutCloudWords()
//            }, completion: nil)
//        
//    }
    
    // MARK: - <UIStateRestoring>
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
    }
    
    // MARK: - Notification handlers
    
    /**
    Content size category has changed.  Layout cloud again, to account for new pointSize
    **/
    func contentSizeCategoryDidChange(__unused: NSNotification) {
        self.layoutCloudWords()
    }
    
    // MARK: - Private methods
    
    func removeCloudWords() {
        
        let removableObjects = NSMutableArray()
        for subview: AnyObject in self.view.subviews {
            if subview.isKindOfClass(UIButton) {
                removableObjects.addObject(subview)
            }
        }
        
        removableObjects.enumerateObjectsUsingBlock( { object, index, stop in
            
            object.removeFromSuperview()
        })
        
        #if DEBUG
            removableObjects.removeAllObjects()
            for sublayer: AnyObject in self.view.layer.sublayers! {
                if sublayer.isKindOfClass(CALayer) {
                    removableObjects.addObject(sublayer)
                }
            }
            
            removableObjects.enumerateObjectsUsingBlock( { object, index, stop in
                
                object.removeFromSuperlayer()
            })
        #endif
    }
    
    func layoutCloudWords() {
        
        self.cloudLayoutOperationQueue.cancelAllOperations()
        self.cloudLayoutOperationQueue.waitUntilAllOperationsAreFinished()
        self.removeCloudWords()
        self.view.backgroundColor = UIColor.clearColor()
        let cloudFrame = CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: self.view.bounds.height)
        let newCloudLayoutOperation: CloudLayoutOperation = CloudLayoutOperation(cloudWords: self.cloudWords, fontName: self.cloudFontName, forContainerWithFrame: cloudFrame, scale: UIScreen.mainScreen().scale, delegate: self)
        self.cloudLayoutOperationQueue.addOperation(newCloudLayoutOperation)
        
        print("layoutCloudWords complete")
    }
    
    func wordTapped(sender: UITapGestureRecognizer) {
        
        let buttonPressed = sender.view as! UIButton
        
        for (_, subJson) in self.trendingStocksJSON {
            
            if subJson["symbol"].string == buttonPressed.currentTitle {
                
                let symbol = subJson["symbol"].string!
                let companyName = subJson["title"].string!
                
                guard let url = NSURL(string: "stockswipe://Chart?symbol=" + symbol + "&companyName=" + companyName.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!) else { return }
                            
                extensionContext?.openURL(url, completionHandler: nil)
            }
        }
    }
    
    func requestStockTwitsTrendingStocks() {
        
        if let trendingStocksUrl = NSURL(string: "https://api.stocktwits.com/api/2/trending/symbols/equities.json") {
            
            let trendingStocksSession = NSURLSession.sharedSession()
            
            let task = trendingStocksSession.dataTaskWithURL(trendingStocksUrl, completionHandler: { (trendingStocksData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if trendingStocksData != nil {
                    
                    self.cloudWords = []
                    self.trendingStocksJSON = JSON(data: trendingStocksData!)["symbols"]
                    
                    for (index, subJson) in self.trendingStocksJSON {
                        
                        let cloudWord = CloudWord(word: subJson["symbol"].string! , wordCount: self.trendingStocksJSON.count - Int(index)!, wordTappable: true)
                        self.cloudWords.append(cloudWord)
                        
                    }
                    
                    self.layoutCloudWords()
                }
            })
            
            task.resume()
            
        } else {
            
            print("couldn't grab URL")
        }
        
        print("trending symbols requested")
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        
        return UIEdgeInsetsZero
    }
    
}
