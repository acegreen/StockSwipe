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
    
    enum Errors: Error {
        case timeOut
        case errorQueryingForData
        case queryDataEmpty
        case errorParsingData
        case urlEmpty
        
        func message() -> String {
            switch self {
            case .timeOut:
                return "We have to wait before requesting new data"
            case .errorQueryingForData:
                return  "Oops! We ran into an issue querying for data"
            case .queryDataEmpty:
                return "Oops! We ran into an issue querying for data"
            case .errorParsingData:
                return "Oops! We ran into an issue querying for data"
            case .urlEmpty:
                return "Oops! We ran into an issue querying for data"
            }
        }
    }
    
    var cloudFontName = "HelveticaNeue"
    var cloudLayoutOperationQueue: OperationQueue!
    var cloudWords = [CloudWord]()
 
    var trendingStocksJSON = JSON.null
    var stockTwitsLastQueriedDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cloudLayoutOperationQueue = OperationQueue()
        cloudLayoutOperationQueue.name = "Cloud layout operation queue"
        cloudLayoutOperationQueue.maxConcurrentOperationCount = 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        } else {
            self.preferredContentSize = CGSize(width: 320, height: 300)
        }
        
        requestStockTwitsTrendingStocks { (result) in
            
        }
    }
    
    deinit {
        cloudLayoutOperationQueue.cancelAllOperations()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - <CloudLayoutOperationDelegate>
    
    func insertWord(_ word: String, pointSize: CGFloat,color: UIColor, center: CGPoint, vertical isVertical: Bool, tappable: Bool) {
        
        let wordButton: UIButton = UIButton(type: UIButton.ButtonType.system)
        wordButton.setTitle(word, for: UIControl.State())
        wordButton.titleLabel?.textAlignment = NSTextAlignment.center
        wordButton.setTitleColor(color, for: UIControl.State())
        wordButton.titleLabel?.font = UIFont(name: cloudFontName, size: pointSize)
        wordButton.sizeToFit()
        var wordButtonRect: CGRect = wordButton.frame
        wordButtonRect.size.width = (((wordButtonRect.width + 3) / 2)) * 2
        wordButtonRect.size.height = (((wordButtonRect.height + 3) / 2)) * 2
        wordButton.frame = wordButtonRect
        wordButton.center = center
        
        if tappable {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TodayViewController.wordTapped(_:)))
            wordButton.addGestureRecognizer(tapGestureRecognizer)
        }
        
        if isVertical {
            wordButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.layoutCloudWords(for: size)
    }
    
    // MARK: - <UIStateRestoring>
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
    
    // MARK: - Notification handlers
    
    /**
    Content size category has changed.  Layout cloud again, to account for new pointSize
    **/
    func contentSizeCategoryDidChange(_ unused: Notification) {
        self.layoutCloudWords(for: self.view.bounds.size)
    }
    
    // MARK: - Private methods
    
    func removeCloudWords() {
        
        let removableObjects = NSMutableArray()
        for subview: AnyObject in self.view.subviews {
            if subview is UIButton {
                removableObjects.add(subview)
            }
        }
        
        removableObjects.enumerateObjects( { object, index, stop in
            
            (object as AnyObject).removeFromSuperview()
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
    
    func layoutCloudWords(for size: CGSize) {
        
        self.cloudLayoutOperationQueue.cancelAllOperations()
        self.cloudLayoutOperationQueue.waitUntilAllOperationsAreFinished()
        self.removeCloudWords()
        //self.view.backgroundColor = UIColor.clear
        let cloudFrame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        let newCloudLayoutOperation: CloudLayoutOperation = CloudLayoutOperation(cloudWords: self.cloudWords, fontName: self.cloudFontName, forContainerWithFrame: cloudFrame, scale: UIScreen.main.scale, delegate: self)
        self.cloudLayoutOperationQueue.addOperation(newCloudLayoutOperation)
        
        print("layoutCloudWords complete")
    }
    
    @objc func wordTapped(_ sender: UITapGestureRecognizer) {
        
        let buttonPressed = sender.view as! UIButton
        
        for (_, subJson) in self.trendingStocksJSON {
            
            if subJson["symbol"].string == buttonPressed.currentTitle {
                
                guard let symbol = subJson["symbol"].string,
                      let url = URL(string: "stockswipe://chart?symbol=" + symbol)
                else { return }
                            
                extensionContext?.open(url, completionHandler: nil)
            }
        }
    }
    
    func requestStockTwitsTrendingStocks(_ completion: @escaping (_ result: () throws -> ()) -> Void) {
        
        if let trendingStocksUrl = URL(string: "https://api.stocktwits.com/api/2/trending/symbols/equities.json") {
            
            let trendingStocksSession = URLSession.shared
            let task = trendingStocksSession.dataTask(with: trendingStocksUrl, completionHandler: { (trendingStocksData, response, error) -> Void in
                
                guard error == nil else { return completion({throw Errors.errorQueryingForData}) }
            
                guard trendingStocksData != nil, let trendingStocksData = trendingStocksData else {
                    return completion({throw Errors.queryDataEmpty})
                }
                
                self.cloudWords.removeAll()
                
                do {
                    self.trendingStocksJSON = try JSON(data: trendingStocksData)["symbols"]
                } catch {
                    completion({throw Errors.errorParsingData})
                }
                
                for (index, subJson) in self.trendingStocksJSON {
                    
                    guard let symbol = subJson["symbol"].string, let wordCount = self.trendingStocksJSON.count - Int(index)! as? NSNumber else { continue }
                    guard let cloudWord = CloudWord(word: symbol , wordCount: wordCount, wordColor: UIColor.white, wordTappable: true) else { continue }
                    self.cloudWords.append(cloudWord)
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.layoutCloudWords(for: self.view.bounds.size)
                })
                
                self.stockTwitsLastQueriedDate = Date()
                
                completion({})
            })
            
            task.resume()
            
        } else {
            completion({throw Errors.urlEmpty})
        }
        
        print("trending symbols requested")
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        requestStockTwitsTrendingStocks({ (result) in
            do {
                try result()
                completionHandler(NCUpdateResult.newData)
            } catch {
                if error is Errors {
                    completionHandler(NCUpdateResult.failed)
                }
            }
        })
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        switch activeDisplayMode {
        case .compact:
            self.preferredContentSize = CGSize(width: 320, height: 200)
        case .expanded:
            self.preferredContentSize = CGSize(width: 320, height: 300)
        }
    }
}
