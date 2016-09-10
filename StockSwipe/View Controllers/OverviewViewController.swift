//
//  OverviewViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import WordCloud
import Parse
import TwitterKit
import LaunchKit
import SWXMLHash
import SwiftyJSON
import DataCache
import SafariServices
import DZNEmptyDataSet
import NVActivityIndicatorView

protocol SplashAnimationDelegate {
    func didFinishLoading()
}

class OverviewViewController: UIViewController, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case ChartDetailSegueIdentifier = "ChartDetailSegueIdentifier"
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case SearchSegueIdentifier = "SearchSegueIdentifier"
        case PostIdeaSegueIdentifier = "PostIdeaSegueIdentifier"
    }
    
    var animationDelegate: SplashAnimationDelegate?
    
    var iCarouselTickers = ["^IXIC","^GSPC","^RUT","^VIX","^GDAXI","^FTSE","^FCHI","^N225","^HSI","^GSPTSE","CAD=X"]
    var tickers = [Ticker]()
    var cloudWords = [CloudWord]()
    var tradeIdeaObjects = [PFObject]()
    var topStories = [News]()
    var charts = [Chart]()
    
    var cloudColors:[UIColor] = [UIColor.grayColor()]
    var cloudFontName = "HelveticaNeue"
    
    var stockTwitsLastQueriedDate: NSDate!
    var carouselLastQueriedDate: NSDate!
    var tradeIdeasLastQueriedDate: NSDate!
    var topStoriesLastQueriedDate: NSDate!
    
    var isQueryingForTrendingStocks = false
    var isQueryingForiCarousel = false
    var isQueryingForTradeIdeas = false
    var isQueryingForTopStories = false
    
    let  tradeIdeaQueryLimit = 15
    
    var tradeIdeasRefreshControl = UIRefreshControl()
    var topStoriesRefreshControl = UIRefreshControl()
    
//    var TrendingStocksHalo: NVActivityIndicatorView!
//    var iCarouselHalo: NVActivityIndicatorView!
//    var topStoriesHalo: NVActivityIndicatorView!
    
    var overviewVCOperationQueue: NSOperationQueue = NSOperationQueue()
    var cloudLayoutOperationQueue: NSOperationQueue = NSOperationQueue()
    
    @IBOutlet var carousel : iCarousel!
    
    @IBOutlet var cloudView: UIView!
    
    @IBOutlet var latestTradeIdeasTableView: UITableView!
    
    @IBOutlet var latestNewsTableView: UITableView!
    
    @IBOutlet var cloudLockedImage: UIImageView!
    
    @IBOutlet var emptyLabel1: UILabel!
    
    @IBOutlet var emptyLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.autoscroll = -0.3
        carousel.type = .Linear
        carousel.contentOffset = CGSize(width: 0, height: 10)
        
        // Add refresh control to top stories tableView
        self.latestTradeIdeasTableView.tableFooterView = UIView(frame: CGRectZero)
        tradeIdeasRefreshControl.addTarget(self, action: #selector(OverviewViewController.refreshTradeIdeas(_:)), forControlEvents: .ValueChanged)
        self.latestTradeIdeasTableView.addSubview(tradeIdeasRefreshControl)
        
        self.latestNewsTableView.tableFooterView = UIView(frame: CGRectZero)
        topStoriesRefreshControl.addTarget(self, action: #selector(OverviewViewController.refreshTopStories(_:)), forControlEvents: .ValueChanged)
        self.latestNewsTableView.addSubview(topStoriesRefreshControl)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        loadViewData()
    }
    
    //    deinit {
    //        cloudLayoutOperationQueue.cancelAllOperations()
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadViewData() {
        
        let trendingCloudOperation = NSBlockOperation { () -> Void in
            self.queryStockTwitsTrendingStocks()
        }
        trendingCloudOperation.queuePriority = .High
        
        let marketCarouselOperation = NSBlockOperation { () -> Void in
            self.queryICarouselTickers()
        }
        marketCarouselOperation.queuePriority = .Normal
        
        let tradeIdeasOperation = NSBlockOperation { () -> Void in
            self.queryTradeIdeas()
        }
        tradeIdeasOperation.queuePriority = .Normal
        
        let topStoriesOperation = NSBlockOperation { () -> Void in
            self.queryTopStories()
        }
        topStoriesOperation.queuePriority = .Normal
        
        overviewVCOperationQueue.addOperations([trendingCloudOperation, marketCarouselOperation, tradeIdeasOperation, topStoriesOperation], waitUntilFinished: true)
        
        let animationOperation = NSBlockOperation { () -> Void in
            self.animationDelegate?.didFinishLoading()
        }
        animationOperation.queuePriority = .Normal
        
        overviewVCOperationQueue.addOperation(animationOperation)
    }
    
    func queryStockTwitsTrendingStocks() {
        
        if cloudWords.count == 0 && stockTwitsLastQueriedDate == nil {
            
            let noInternetSentence = "The cloud is empty weird indeed could not grab Any Trending Stocks"
            let breakupSentence = noInternetSentence.componentsSeparatedByString(" ")
            
            for (index, word) in breakupSentence.enumerate() {
                let cloudWord = CloudWord(word: word, wordCount: breakupSentence.count - Int(index), wordTappable: false)
                self.cloudWords.append(cloudWord)
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({() -> Void in
                self.layoutCloudWords()
                self.cloudWords.removeAll()
                
            })
        }
        
        guard Functions.isConnectedToNetwork() else { return }
        
        if stockTwitsLastQueriedDate != nil && self.cloudWords.count > 0 {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(stockTwitsLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 5 else {
                return
            }
        }
        
        NSLog("refreshing cloud on %@", NSThread.isMainThread() ? "main thread" : "other thread")
        
        isQueryingForTrendingStocks = true
        
        QueryHelper.sharedInstance.queryStockTwitsTrendingStocks { (trendingStocksData) in
            
            do {
                
                let trendingStocksData = try trendingStocksData()
                
                let trendingStocksJSON = JSON(data: trendingStocksData)["symbols"]
                
                DataCache.defaultCache.writeData(trendingStocksData, forKey: "TRENDINGSTOCKSCACHEDATA")
                QueryHelper.sharedInstance.queryStockObjectsFor(trendingStocksJSON.map { $0.1 }.map{ $0["symbol"].string! }, completion: { (result) in
                    
                    self.isQueryingForTrendingStocks = false
                    
                    do {
                        
                        let stockObjects = try result()
                        self.createCloudWords(trendingStocksJSON, stockObjects: stockObjects)
                        
                        self.stockTwitsLastQueriedDate = NSDate()
                        
                    } catch {
                    }
                })
                
            } catch {
                
            }
        }
    }
    
    func queryICarouselTickers() {
        
        if carouselLastQueriedDate == nil || !Functions.isConnectedToNetwork() {
            if let carouselCacheData = DataCache.defaultCache.readDataForKey("CAROUSELCACHEDATA") {
                updateCarousel(carouselCacheData)
            }
        } else if carouselLastQueriedDate != nil {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(carouselLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 1 else {
                return
            }
        }
        
        NSLog("refreshing carousel on %@", NSThread.isMainThread() ? "main thread" : "other thread")
        
        // Setup config parameters
        Functions.setupConfigParameter("CAROUSELTICKERARRAY") { (parameterValue) -> Void in
            
            if parameterValue != nil {
                self.iCarouselTickers = parameterValue as! [String]
            }
            
            self.isQueryingForiCarousel = true
            
            QueryHelper.sharedInstance.queryYahooSymbolQuote(self.iCarouselTickers, completionHandler: { (symbolQuote, response, error) -> Void in
                
                self.isQueryingForiCarousel = false
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if let symbolQuote = symbolQuote {
                    
                    DataCache.defaultCache.writeData(symbolQuote, forKey: "CAROUSELCACHEDATA")
                    self.updateCarousel(symbolQuote)
                    
                    self.carouselLastQueriedDate = NSDate()
                }
            })
        }
    }
    
    func queryTradeIdeas() {
        
        guard Functions.isConnectedToNetwork() else { return }
        
        if tradeIdeasLastQueriedDate != nil && self.tradeIdeaObjects.count > 0 {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(tradeIdeasLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 5 else {
                if self.tradeIdeasRefreshControl.refreshing == true {
                    self.tradeIdeasRefreshControl.endRefreshing()
                }
                return
            }
        }
        
        isQueryingForTradeIdeas = true
        QueryHelper.sharedInstance.queryActivityFor(nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue], skip: nil, limit: tradeIdeaQueryLimit, includeKeys: ["tradeIdea"]) { (result) in
            
            self.isQueryingForTradeIdeas = false
            
            do {
                
                let activityObjects = try result()
                
                self.updateTradeIdeas(activityObjects.lazy.map { $0["tradeIdea"] as! PFObject })
                
                self.tradeIdeasLastQueriedDate = NSDate()
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.latestTradeIdeasTableView.reloadData()
                    if self.tradeIdeasRefreshControl.refreshing == true {
                        self.tradeIdeasRefreshControl.endRefreshing()
                    }
                })
            }
            
        }
    }
    
    func queryTopStories() {
        
        if topStoriesLastQueriedDate == nil || !Functions.isConnectedToNetwork() {
            if let topStoriesCacheData = DataCache.defaultCache.readDataForKey("TOPSTORIESCACHEDATA") {
                self.updateTopStories(topStoriesCacheData)
            }
        } else if topStoriesLastQueriedDate != nil {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(topStoriesLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 1 else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.topStoriesRefreshControl.refreshing == true {
                        self.topStoriesRefreshControl.endRefreshing()
                    }
                })
                return
            }
        }
        
        NSLog("refreshing top stories on %@", NSThread.isMainThread() ? "main thread" : "other thread")
        
        isQueryingForTopStories = true
        
        let queryString = "http://feeds.reuters.com/reuters/businessNews?format=xml"
        
        QueryHelper.sharedInstance.queryWith(queryString) { (result) -> Void in
            
            self.isQueryingForTopStories = false
            
            do {
                
                let result = try result()
                
                DataCache.defaultCache.writeData(result, forKey: "TOPSTORIESCACHEDATA")
                self.updateTopStories(result)
                self.topStoriesLastQueriedDate = NSDate()
                
            } catch {
                
                if error is Constants.Errors {
                    print(error)
                }
            }
        }
    }
    
    func createCloudWords(trendingStocksJSON: JSON, stockObjects: [PFObject]) {
        
        self.cloudWords.removeAll()
        for (index, subJson) in trendingStocksJSON {
            
            if let chart = (self.charts.find{ $0.symbol == subJson["symbol"].string }) {
                self.charts.removeObject(chart)
            }
            
            guard let symbol = subJson["symbol"].string else { continue }
            
            let cloudWord = CloudWord(word: symbol , wordCount: trendingStocksJSON.count - Int(index)!, wordTappable: true)
            self.cloudWords.append(cloudWord)
            
            var chart: Chart!
            if let parseObject = (stockObjects.find{ $0["Symbol"] as? String == subJson["symbol"].string }) {
                chart = Chart(parseObject: parseObject)
            } else {
                chart = Chart(symbol: symbol, companyName: subJson["title"].string)
            }
            
            self.charts.append(chart)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.layoutCloudWords()
        })
    }
    
    func updateCarousel(symbolQuote: NSData) {
        
        guard let carsouelJson:JSON? = JSON(data: symbolQuote) else { return }
        guard carsouelJson != nil else { return }
        guard let carsouelJsonResults:JSON? = carsouelJson!["query"]["results"] else { return }
        guard let quoteJsonResultsQuote = carsouelJsonResults!["quote"].array else { return }
        
        for quote in quoteJsonResultsQuote {
            
            let symbol = quote["Symbol"].string
            let companyName = quote["Name"].string
            let exchange = quote["StockExchange"].string
            let currentPrice = quote["LastTradePriceOnly"].string
            let changeInDollar = quote["Change"].string
            let changeInPercent = quote["ChangeinPercent"].string
            
            if let ticker = (self.tickers.find{ $0.symbol == symbol}) {
                self.tickers.removeObject(ticker)
            }
            
            if let chart = (self.charts.find{ $0.symbol == symbol}) {
                self.charts.removeObject(chart)
            }
            
            let ticker = Ticker(symbol: symbol, companyName: companyName, exchange: exchange, currentPrice: currentPrice, changeInDollar: changeInDollar, changeInPercent: changeInPercent)
            
            let chart = Chart(symbol: symbol, companyName: companyName)
            
            self.tickers.append(ticker)
            self.charts.append(chart)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.carousel.reloadData()
            NSLog("carousel completed on %@", NSThread.isMainThread() ? "main thread" : "other thread")
        })
        
    }
    
    func updateTradeIdeas(tradeIdeaObjects: [PFObject]) {
        
        self.tradeIdeaObjects = tradeIdeaObjects
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.latestTradeIdeasTableView.reloadData()
            if self.tradeIdeasRefreshControl.refreshing == true {
                self.tradeIdeasRefreshControl.endRefreshing()
            }
        })
    }
    
    func updateTopStories(result: NSData) {
        
        let xml = SWXMLHash.parse(result)
        
        let items = xml["rss"]["channel"]["item"]
        
        self.topStories = []
        
        for item in items {
            
            var newsDecodedTitle: String?
            var newsUrl: String?
            var newsDetails: String?
            var newsPublishedDate: String?
            
            // Get title
            if let title = item["title"].element?.text {
                newsDecodedTitle = title
            }
            
            // Get URL
            if let link = item["link"].element?.text {
                newsUrl = link
            }
            
            // Get details
            if let description = item["description"].element?.text {
                newsDetails = description
            }
            
            // Get Published Date
            if let pubDate = item["pubDate"].element?.text {
                let publishedDateFormatter = NSDateFormatter()
                publishedDateFormatter.dateFormat = "EEE, dd MMM yy HH:mm:ss z"
                
                if let formattedDate = publishedDateFormatter.dateFromString(pubDate) {
                    newsPublishedDate = formattedDate.formattedAsTimeAgo()
                }
            }
            
            let newNews = News(image: nil, title: newsDecodedTitle, details: newsDetails,url: newsUrl, publisher: nil, publishedDate: newsPublishedDate)
            self.topStories.append(newNews)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.latestNewsTableView.reloadData()
            if self.topStoriesRefreshControl.refreshing == true {
                self.topStoriesRefreshControl.endRefreshing()
            }
            
            NSLog("top stories completed on %@", NSThread.isMainThread() ? "main thread" : "other thread")
        })
    }
    
    func refreshTradeIdeas(refreshControl: UIRefreshControl) {
        let tradeIdeasOperation = NSBlockOperation { () -> Void in
            self.queryTradeIdeas()
        }
        tradeIdeasOperation.queuePriority = .Normal
        overviewVCOperationQueue.addOperation(tradeIdeasOperation)
    }
    
    func refreshTopStories(refreshControl: UIRefreshControl) {
        let topStoriesOperation = NSBlockOperation { () -> Void in
            self.queryTopStories()
        }
        topStoriesOperation.queuePriority = .Normal
        overviewVCOperationQueue.addOperation(topStoriesOperation)
    }
    
    // MARK: - Segue Method
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        
        case .ChartDetailSegueIdentifier:
            
            var symbol: String!
            
            switch sender {
                
            case is UIButton:
                
                symbol = sender?.currentTitle
                
                let destinationView = segue.destinationViewController as! ChartDetailTabBarController
                destinationView.chart = self.charts.find{ $0.symbol == symbol }
                
            case is UIView:
                
                print(carousel.indexOfItemView(sender as! UIView))
                
                if tickers.get(carousel.indexOfItemView(sender as! UIView)) != nil {
                    
                    let tickerAtIndex = tickers[carousel.indexOfItemView(sender as! UIView)]
                    
                    symbol = tickerAtIndex.symbol
                    
                }
                
                let destinationView = segue.destinationViewController as! ChartDetailTabBarController
                destinationView.chart = self.charts.find{ $0.symbol == symbol }
                
            default:
                break
            }
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.tradeIdea = cell.tradeIdea
            
        case .SearchSegueIdentifier:
            break
            
        case .PostIdeaSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.tradeIdeaType = .New
            ideaPostViewController.delegate =  self
        }
    }
}

extension OverviewViewController: CloudLayoutOperationDelegate {
    
    // MARK: - CloudLayoutOperationDelegate
    
    func insertWord(word: String, pointSize: CGFloat,color: Int, center: CGPoint, vertical isVertical: Bool, tappable: Bool) {
        
        let wordButton: UIButton = UIButton(type: UIButtonType.System)
        wordButton.setTitle(word, forState: UIControlState.Normal)
        wordButton.titleLabel?.textAlignment = NSTextAlignment.Center
        wordButton.setTitleColor(self.cloudColors[color < self.cloudColors.count ? color : 0], forState: UIControlState.Normal)
        wordButton.titleLabel?.font = UIFont(name: self.cloudFontName, size: pointSize)
        wordButton.sizeToFit()
        var wordButtonRect: CGRect = wordButton.frame
        wordButtonRect.size.width = (((CGRectGetWidth(wordButtonRect) + 3) / 2)) * 2
        wordButtonRect.size.height = (((CGRectGetHeight(wordButtonRect) + 3) / 2)) * 2
        wordButton.frame = wordButtonRect
        wordButton.center = center
        
        if tappable {
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OverviewViewController.wordTapped(_:)))
            wordButton.addGestureRecognizer(tapGestureRecognizer)
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(OverviewViewController.wordLongPressed(_:)))
            wordButton.addGestureRecognizer(longPressRecognizer)
        }
        
        if isVertical {
            wordButton.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        }
        
        self.cloudView.addSubview(wordButton)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        weak var weakSelf = self
        
        coordinator.animateAlongsideTransition({(context) -> Void in
            let strongSelf = weakSelf
            strongSelf!.layoutCloudWords()
            }, completion: nil)
        
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
    }
    
    // Content size category has changed.  Layout cloud again, to account for new pointSize
    func contentSizeCategoryDidChange(__unused: NSNotification) {
        self.layoutCloudWords()
    }
    
    func removeCloudWords() {
        
        let removableObjects = NSMutableArray()
        for subview: AnyObject in self.cloudView.subviews {
            if subview.isKindOfClass(UIButton) {
                removableObjects.addObject(subview)
            }
        }
        
        removableObjects.enumerateObjectsUsingBlock( { object, index, stop in
            object.removeFromSuperview()
        })
    }
    
    func layoutCloudWords() {
        
        self.removeCloudWords()
        self.view.backgroundColor = UIColor.whiteColor()
        let newCloudLayoutOperation: CloudLayoutOperation = CloudLayoutOperation(cloudWords: self.cloudWords, fontName: self.cloudFontName, forContainerWithFrame: self.cloudView.bounds, scale: UIScreen.mainScreen().scale, delegate: self)
        self.cloudLayoutOperationQueue.addOperation(newCloudLayoutOperation)
        
        NSLog("cloud completed on %@", NSThread.isMainThread() ? "main thread" : "other thread")
    }
    
    func wordTapped(sender: UITapGestureRecognizer) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            
            return
        }
        
        performSegueWithIdentifier("ChartDetailSegueIdentifier", sender: sender.view)
    }
    
    func wordLongPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            print("UIGestureRecognizerState Began")
            
            guard let chart = (self.charts.find{ $0.symbol == (sender.view as! UIButton).currentTitle }) else { return }
            
            Functions.addToWatchlist(chart) { (choice) in
                Functions.registerUserChoice(chart, with: choice)
            }
        }
    }
}

extension OverviewViewController: iCarouselDataSource, iCarouselDelegate {
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return tickers.count
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        
        var itemView: iCarouselTickerView
        
        //create new view if no view is available for recycling
        if view == nil {
            
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            itemView = iCarouselTickerView(frame: CGRect(x:0, y:0, width:200, height:60))
            
        } else {
            //get a reference to the label in the recycled view
            itemView = view as! iCarouselTickerView
        }
        
        guard tickers.get(index) != nil else { return itemView }
        
        if let tickerCompanyName = tickers[index].companyName {
            
            itemView.nameLabel.text = tickerCompanyName
        }
        
        if let tickerCurrentPrice = tickers[index].currentPrice {
            
            itemView.priceLabel.text = "\(tickerCurrentPrice)"
        }
        
        if let tickerChangeInDollar = tickers[index].changeInDollar {
            
            if let tickerChangeInPercent = tickers[index].changeInPercent {
                
                itemView.priceChangeLabel.text = "\(tickerChangeInDollar) (\(tickerChangeInPercent))"
                
                //                    if tickerChangeInDollarDoubleValue > 0 {
                //
                //                        itemView.priceChangeLabel.textColor = stockSwipeGreenColor
                //
                //                    } else {
                //
                //                        itemView.priceChangeLabel.textColor = UIColor.redColor()
                //                    }
            }
        }
        
        return itemView
    }
    
    func carousel(carousel: iCarousel, didSelectItemAtIndex index: Int) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            
            return
        }
        
        performSegueWithIdentifier("ChartDetailSegueIdentifier", sender: carousel.itemViewAtIndex(index))
        
    }
    
    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        if option == .Spacing {
            
            return value * 1.15
            
        } else if option == .Wrap {
            
            return 1.0
        }
        
        return value
    }
}

extension OverviewViewController: UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, CellType {
    
    enum CellIdentifier: String {
        case TopNewsCell = "TopNewsCell"
    }
    
    // MARK: - TableView data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == latestNewsTableView {
            return topStories.count
        } else if tableView == latestTradeIdeasTableView {
            return tradeIdeaObjects.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == latestNewsTableView {
            
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as TopNewsCell
            
            guard topStories.get(indexPath.row) != nil else { return cell }
            
            let newsAtIndex = self.topStories[indexPath.row]
            
            if let newsTitleAtIndex = newsAtIndex.title {
                
                cell.newsTitle.text = newsTitleAtIndex
            }
            
            if let newsDetails = newsAtIndex.details {
                
                cell.newsDescription.text = newsDetails
            }
            
            return cell
            
        } else if tableView == latestTradeIdeasTableView {
        
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            
            guard tradeIdeaObjects.get(indexPath.row) != nil else { return cell }
            cell.configureCell(self.tradeIdeaObjects[indexPath.row], timeFormat: .Short)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UITableViewCell
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView == latestNewsTableView {
            
            guard topStories.get(indexPath.row) != nil else {
                return
            }
            
            let newsAtIndex = self.topStories[indexPath.row]
            
            if let newsurl = newsAtIndex.url {
                
                Functions.presentSafariBrowser(NSURL(string: newsurl))
                
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    // MARK: - DZNEmptyDataSet Delegates
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        
        if scrollView == latestNewsTableView && !isQueryingForTopStories && topStories.count == 0 {
            return true
        } else if scrollView == latestTradeIdeasTableView && !isQueryingForTradeIdeas && tradeIdeaObjects.count == 0 {
            return true
        }
        
        return false
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        var attributedTitle: NSAttributedString!
        
        if scrollView == latestNewsTableView {
            attributedTitle = NSAttributedString(string: "No News", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        } else if scrollView == latestTradeIdeasTableView {
            attributedTitle = NSAttributedString(string: "No Trade Ideas", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        }
        
        return attributedTitle
    }
}

extension OverviewViewController: IdeaPostDelegate {
        
        func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
            
            if tradeIdeaTyp == .New {
                
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                self.tradeIdeaObjects.insert(tradeIdea.parseObject, atIndex: 0)
                self.latestTradeIdeasTableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                
                self.latestTradeIdeasTableView.reloadEmptyDataSet()
            }
        }
        
        func ideaDeleted(with parseObject: PFObject) {
            
            if let tradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == parseObject.objectId }) {
                
                if let reshareOf = tradeIdea.objectForKey("reshare_of") as? PFObject, let reshareTradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == reshareOf.objectId })  {
                    
                    let indexPath = NSIndexPath(forRow: self.tradeIdeaObjects.indexOf(reshareTradeIdea)!, inSection: 0)
                    self.latestTradeIdeasTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
                
                let indexPath = NSIndexPath(forRow: self.tradeIdeaObjects.indexOf(tradeIdea)!, inSection: 0)
                self.tradeIdeaObjects.removeObject(tradeIdea)
                self.latestTradeIdeasTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
            
            if tradeIdeaObjects.count == 0 {
                self.latestTradeIdeasTableView.reloadEmptyDataSet()
            }
        }
}
