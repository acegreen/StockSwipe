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
    var tradeIdeas = [TradeIdea]()
    var topStories = [News]()
    var charts = [Chart]()
    
    var cloudFontName = "HelveticaNeue"
    
    var stockTwitsLastQueriedDate: Date!
    var carouselLastQueriedDate: Date!
    var tradeIdeasLastQueriedDate: Date!
    var topStoriesLastQueriedDate: Date!
    
    var isQueryingForTrendingStocks = false
    var isQueryingForiCarousel = false
    var isQueryingForTradeIdeas = false
    var isQueryingForTopStories = false
    
    var tradeIdeasRefreshControl = UIRefreshControl()
    var topStoriesRefreshControl = UIRefreshControl()
    
    var overviewVCOperationQueue: OperationQueue = OperationQueue()
    var cloudLayoutOperationQueue: OperationQueue = OperationQueue()
    
    var queryTimer: Timer!
    let QUERY_INTERVAL: Double = 60 // 5 minutes
    
    @IBOutlet var cloudViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var carousel : iCarousel!
    
    @IBOutlet var cloudView: UIView!
    
    @IBOutlet var trendingCloudShowButton: UIButton!
    
    @IBOutlet var latestTradeIdeasTableView: UITableView!
    
    @IBOutlet var latestNewsTableView: UITableView!
    
    @IBOutlet var cloudLockedImage: UIImageView!
    
    @IBOutlet var emptyLabel1: UILabel!
    
    @IBOutlet var emptyLabel2: UILabel!
    
    @IBAction func trendingCloudShowButtonAction(_ sender: UIButton) {
        
        if sender.currentTitle == "See Less" {
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: UIView.AnimationOptions.curveEaseIn,
                           animations: { () -> Void in
                            self.cloudViewHeightConstraint = self.cloudViewHeightConstraint.setMultiplier(multiplier: 0.2)
                }, completion: { (success) in
                    
                    // hardcoding the size because of a glitch when animating
                    self.layoutCloudWords(for: CGSize(width: self.cloudView.bounds.width, height: self.view.bounds.height * 0.2))
                    sender.setTitle("See More", for: UIControl.State())
            })
            
        } else {
            
            UIView.animate(withDuration: 1.0,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: UIView.AnimationOptions.curveEaseIn,
                           animations: { () -> Void in
                            self.cloudViewHeightConstraint = self.cloudViewHeightConstraint.setMultiplier(multiplier: 0.4)
                            
                }, completion: { (success) in
                    
                    // hardcoding the size because of a glitch when animating
                    self.layoutCloudWords(for: CGSize(width: self.cloudView.bounds.width, height: self.view.bounds.height * 0.4))
                    sender.setTitle("See Less", for: UIControl.State())
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.autoscroll = -0.3
        carousel.type = .linear
        carousel.contentOffset = CGSize(width: 0, height: 10)
        
        // Add refresh control to top stories tableView
        self.latestTradeIdeasTableView.tableFooterView = UIView(frame: CGRect.zero)
        tradeIdeasRefreshControl.addTarget(self, action: #selector(OverviewViewController.refreshTradeIdeas(_:)), for: .valueChanged)
        self.latestTradeIdeasTableView.addSubview(tradeIdeasRefreshControl)
        
        self.latestNewsTableView.tableFooterView = UIView(frame: CGRect.zero)
        topStoriesRefreshControl.addTarget(self, action: #selector(OverviewViewController.refreshTopStories(_:)), for: .valueChanged)
        self.latestNewsTableView.addSubview(topStoriesRefreshControl)
        
        // Set "Show less" button
        if Constants.current.userInterfaceIdiom == .phone {
            self.trendingCloudShowButton.isHidden = false
        }
        
        self.loadViewData(firstLaunch: true)
        self.scheduleQueryTimer()
        
        // register for foreground notificaions so we can refresh views
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewViewController.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewViewController.applicationsDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        cloudLayoutOperationQueue.cancelAllOperations()
        overviewVCOperationQueue.cancelAllOperations()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func applicationWillEnterForeground() {
        self.loadViewData()
        self.scheduleQueryTimer()
    }
    
    @objc func applicationsDidEnterBackground() {
        self.queryTimer.invalidate()
    }
    
    private func scheduleQueryTimer() {
        self.queryTimer = Timer.scheduledTimer(withTimeInterval: QUERY_INTERVAL, repeats: true, block: { timer in
            self.loadViewData()
        })
    }
    
    private func loadViewData(firstLaunch: Bool = false) {
        
        let trendingCloudOperation = BlockOperation { () -> Void in
            self.queryStockTwitsTrendingStocks()
        }
        trendingCloudOperation.queuePriority = .high
        
        let tradeIdeasOperation = BlockOperation { () -> Void in
            self.queryTradeIdeas()
        }
        tradeIdeasOperation.queuePriority = .high
        
        let marketCarouselOperation = BlockOperation { () -> Void in
            self.queryCarouselTickers()
        }
        marketCarouselOperation.queuePriority = .normal
        
        let topStoriesOperation = BlockOperation { () -> Void in
            self.queryTopStories()
        }
        topStoriesOperation.queuePriority = .normal
        
        overviewVCOperationQueue.addOperations([trendingCloudOperation, tradeIdeasOperation, marketCarouselOperation, topStoriesOperation], waitUntilFinished: true)
        
        if firstLaunch {
            
            let animationOperation = BlockOperation { () -> Void in
                self.animationDelegate?.didFinishLoading()
            }
            animationOperation.queuePriority = .normal
            overviewVCOperationQueue.addOperation(animationOperation)
        }
    }
    
    func queryStockTwitsTrendingStocks() {
        
        if cloudWords.count == 0 && stockTwitsLastQueriedDate == nil {
            
            let noInternetSentence = "The cloud is empty weird indeed could not grab Any trending stocks"
            let breakupSentence = noInternetSentence.components(separatedBy: " ")
            
            for (index, word) in breakupSentence.enumerated() {
                if let cloudWord = CloudWord(word: word, wordCount: (breakupSentence.count - Int(index)) as NSNumber, wordColor: UIColor.gray, wordTappable: false) {
                    self.cloudWords.append(cloudWord)
                }
            }
            
            self.cloudWords.removeAll()
            
            DispatchQueue.main.async {
                self.layoutCloudWords(for: self.cloudView.bounds.size)
            }
        }
        
        guard Functions.isConnectedToNetwork() else { return }
        
        if stockTwitsLastQueriedDate != nil && self.cloudWords.count > 0 {
            
            let timeSinceLastRefresh = Date().timeIntervalSince(stockTwitsLastQueriedDate)
            
            guard timeSinceLastRefresh > QUERY_INTERVAL else {
                return
            }
        }
        
        NSLog("refreshing cloud on %@", Thread.isMainThread ? "main thread" : "other thread")
        
        isQueryingForTrendingStocks = true
        
        QueryHelper.sharedInstance.queryStockTwitsTrendingStocks { (trendingStocksData) in
            
            do {
                
                let trendingStocksData = try trendingStocksData()
                let trendingStocksJSON = try JSON(data: trendingStocksData)["symbols"]
                
                DataCache.instance.write(data: trendingStocksData, forKey: "TRENDINGSTOCKSCACHEDATA")
                QueryHelper.sharedInstance.queryStockObjectsFor(symbols: trendingStocksJSON.map { $0.1 }.map{ $0["symbol"].string! }, completion: { (result) in
                    
                    self.isQueryingForTrendingStocks = false
                    
                    do {
                        
                        // print(trendingStocksJSON)
                        
                        let stockObjects = try result()
                        self.createCloudWords(trendingStocksJSON, stockObjects: stockObjects)
                        self.stockTwitsLastQueriedDate = Date()
                        
                    } catch {
                        //TODO: handle error
                    }
                })
                
            } catch {
                //TODO: handle error
            }
        }
    }
    
    func queryCarouselTickers() {
        
        if carouselLastQueriedDate == nil || !Functions.isConnectedToNetwork() {
            if let carouselCacheData = DataCache.instance.readData(forKey: "CAROUSELCACHEDATA") {
                updateCarousel(from: try! QueryHelper.EODQuoteResult.decodeFrom(data: carouselCacheData))
            }
        } else if carouselLastQueriedDate != nil {
            let timeSinceLastRefresh = Date().timeIntervalSince(carouselLastQueriedDate)
            guard timeSinceLastRefresh > QUERY_INTERVAL else {
                return
            }
        }
        
        NSLog("refreshing carousel on %@", Thread.isMainThread ? "main thread" : "other thread")
        
        // Setup config parameters
        Functions.setupConfigParameter("CAROUSELTICKERARRAY") { (parameterValue) -> Void in
            
            if parameterValue != nil {
                self.iCarouselTickers = parameterValue as! [String]
            }
            
            self.isQueryingForiCarousel = true
            
            QueryHelper.sharedInstance.queryEODQuotes(for: self.iCarouselTickers, completionHandler: { eodQuoteResults in
                
                do {
                    let eodResults = try eodQuoteResults()
                    DataCache.instance.write(data: eodResults.1, forKey: "CAROUSELCACHEDATA")
                    self.updateCarousel(from: eodResults.0)
                    self.carouselLastQueriedDate = Date()
                } catch {
                    //TODO: handle error
                }
                
                self.isQueryingForiCarousel = false
            })
        }
    }
    
    func queryTradeIdeas() {
        
        guard Functions.isConnectedToNetwork() else { return }
        
        if tradeIdeasLastQueriedDate != nil && self.tradeIdeas.count > 0 {
            
            let timeSinceLastRefresh = Date().timeIntervalSince(tradeIdeasLastQueriedDate)

            guard timeSinceLastRefresh > QUERY_INTERVAL else {
                DispatchQueue.main.async {
                    if self.tradeIdeasRefreshControl.isRefreshing == true {
                        self.tradeIdeasRefreshControl.endRefreshing()
                    }
                }
                return
            }
        }
        
        isQueryingForTradeIdeas = true
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue], skip: nil, limit: QueryHelper.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"]) { (result) in
            
            do {
                
                let activityObjects = try result()
                
                var tradeIdeaObjects = [PFObject]()
                for activityObject in activityObjects {
                    if let tradeIdeaObject = activityObject["tradeIdea"] as? PFObject {
                        tradeIdeaObjects.append(tradeIdeaObject)
                    }
                }
                
                self.updateTradeIdeas(tradeIdeaObjects)
                self.tradeIdeasLastQueriedDate = Date()
                
            } catch {
                
                //TODO: Show sweet alert with Error.message()
                DispatchQueue.main.async {
                    if self.tradeIdeasRefreshControl.isRefreshing == true {
                        self.tradeIdeasRefreshControl.endRefreshing()
                    }
                }
            }
        }
    }
    
    func queryTopStories() {
        
        if topStoriesLastQueriedDate == nil || !Functions.isConnectedToNetwork() {
            if let topStoriesCacheData = DataCache.instance.readData(forKey: "TOPSTORIESCACHEDATA") {
                self.updateTopStories(topStoriesCacheData)
            }
        } else if topStoriesLastQueriedDate != nil {
            
            let timeSinceLastRefresh = Date().timeIntervalSince(topStoriesLastQueriedDate)
            
            guard timeSinceLastRefresh > QUERY_INTERVAL else {
                DispatchQueue.main.async {
                    if self.topStoriesRefreshControl.isRefreshing == true {
                        self.topStoriesRefreshControl.endRefreshing()
                    }
                }
                return
            }
        }
        
        NSLog("refreshing top stories on %@", Thread.isMainThread ? "main thread" : "other thread")
        
        isQueryingForTopStories = true
        
        let queryString = "http://feeds.reuters.com/reuters/businessNews?format=xml"
        
        QueryHelper.sharedInstance.queryWith(queryString: queryString) { (result) -> Void in
            
            do {
                
                let result = try result()
                
                DataCache.instance.write(data: result, forKey: "TOPSTORIESCACHEDATA")
                self.updateTopStories(result)
                self.topStoriesLastQueriedDate = Date()
                
            } catch {
                //TODO: handle error
                if error is QueryHelper.QueryError {
                    print(error)
                }
            }
            
            self.isQueryingForTopStories = false
        }
    }
    
    func createCloudWords(_ trendingStocksJSON: JSON, stockObjects: [PFObject]) {
        
        let stockNames = trendingStocksJSON.map { $0.1 }.map{ $0["symbol"].string! }
        
        self.cloudWords.removeAll()
        for (index, subJson) in trendingStocksJSON {
            
            if let chart = (self.charts.find{ $0.symbol == subJson["symbol"].string }) {
                self.charts.removeObject(chart)
            }
            
            guard let symbol = subJson["symbol"].string, let wordCount = trendingStocksJSON.count - Int(index)! as? NSNumber else { continue }
            guard let cloudWord = CloudWord(word: symbol , wordCount: wordCount, wordColor: UIColor.gray, wordTappable: true) else { continue }
            self.cloudWords.append(cloudWord)
            
            if let parseObject = (stockObjects.find{ $0["Symbol"] as? String == subJson["symbol"].string }) {
                let chart = Chart(parseObject: parseObject)
                self.charts.append(chart)
                
            } else {
                Functions.createParseObject(for: symbol) { object in
                    do {
                        
                        let parseObject = try object()
                        let chart = Chart(parseObject: parseObject)
                        self.charts.append(chart)
                        
                    } catch {
                        //TODO: handle error
                    }
                }
            }
        }
        
        self.layoutCloudWords(for: self.cloudView.bounds.size)
    }
    
    func updateCarousel(from eodQuoteResults: [QueryHelper.EODQuoteResult]) {
        
        self.tickers = Ticker.makeTickers(from: eodQuoteResults)
        for ticker in tickers {
            if let chart = (self.charts.find{ $0.symbol == ticker.symbol}) {
                self.charts.removeObject(chart)
            }
            
            let chart = Chart(symbol: ticker.symbol, companyName: ticker.companyName)
            self.charts.append(chart)
        }
        
        DispatchQueue.main.async {
            self.carousel.reloadData()
            NSLog("carousel completed on %@", Thread.isMainThread ? "main thread" : "other thread")
        }
    }
    
    func updateTradeIdeas(_ tradeIdeaObjects: [PFObject]) {
        
        self.tradeIdeas = TradeIdea.makeTradeIdeas(from: tradeIdeaObjects)

        // reload table
        self.latestTradeIdeasTableView.reloadData()
        
        // end refresh indicator
        if self.tradeIdeasRefreshControl.isRefreshing == true {
            self.tradeIdeasRefreshControl.endRefreshing()
        }
        
        self.isQueryingForTradeIdeas = false
    }
    
    func updateTopStories(_ result: Data) {
        
        let xml = SWXMLHash.parse(result)
        
        let items = xml["rss"]["channel"]["item"]
        
        self.topStories.removeAll()
        
        for item in items.all {
            
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
                let publishedDateFormatter = DateFormatter()
                publishedDateFormatter.dateFormat = "EEE, dd MMM yy HH:mm:ss z"
                
                if let formattedDate = publishedDateFormatter.date(from: pubDate) {
                    let nsformattedDate = formattedDate as NSDate
                    newsPublishedDate = nsformattedDate.formattedAsTimeAgo()
                }
            }
            
            let newNews = News(image: nil, title: newsDecodedTitle, details: newsDetails,url: newsUrl, publisher: nil, publishedDate: newsPublishedDate)
            self.topStories.append(newNews)
        }
        
        DispatchQueue.main.async {
            self.latestNewsTableView.reloadData()
            if self.topStoriesRefreshControl.isRefreshing == true {
                self.topStoriesRefreshControl.endRefreshing()
            }
            NSLog("top stories completed on %@", Thread.isMainThread ? "main thread" : "other thread")
        }
    }
    
    @objc func refreshTradeIdeas(_ refreshControl: UIRefreshControl) {
        let tradeIdeasOperation = BlockOperation { () -> Void in
            self.queryTradeIdeas()
        }
        tradeIdeasOperation.queuePriority = .high
        overviewVCOperationQueue.addOperation(tradeIdeasOperation)
    }
    
    @objc func refreshTopStories(_ refreshControl: UIRefreshControl) {
        let topStoriesOperation = BlockOperation { () -> Void in
            self.queryTopStories()
        }
        topStoriesOperation.queuePriority = .normal
        overviewVCOperationQueue.addOperation(topStoriesOperation)
    }
    
    // MARK: - Segue Method
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        
        case .ChartDetailSegueIdentifier:
            
            var symbol: String!
            
            switch sender {
                
            case is UIButton:
                
                symbol = (sender as! UIButton).currentTitle
                
                let destinationView = segue.destination as! CardDetailTabBarController
                destinationView.chart = self.charts.find{ $0.symbol == symbol }
                
            case is UIView:
                
                print(carousel.index(ofItemView: sender as! UIView))
                
                if tickers.get(carousel.index(ofItemView: sender as! UIView)) != nil {
                    
                    let tickerAtIndex = tickers[carousel.index(ofItemView: sender as! UIView)]
                    
                    symbol = tickerAtIndex.symbol
                    
                }
                
                let destinationView = segue.destination as! CardDetailTabBarController
                destinationView.chart = self.charts.find{ $0.symbol == symbol }
                
            default:
                break
            }
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.tradeIdea = cell.tradeIdea
            
        case .SearchSegueIdentifier:
            break
            
        case .PostIdeaSegueIdentifier:
            
            let destinationViewController = segue.destination as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.tradeIdeaType = .new
            ideaPostViewController.delegate =  self
        }
    }
}

extension OverviewViewController: CloudLayoutOperationDelegate {
    
    // MARK: - CloudLayoutOperationDelegate
    
    func insertWord(_ word: String, pointSize: CGFloat, color: UIColor, center: CGPoint, vertical isVertical: Bool, tappable: Bool) {
        
        let wordButton: UIButton = UIButton(type: UIButton.ButtonType.system)
        wordButton.setTitle(word, for: UIControl.State())
        wordButton.titleLabel?.textAlignment = NSTextAlignment.center
        wordButton.setTitleColor(color, for: UIControl.State())
        wordButton.titleLabel?.font = UIFont(name: self.cloudFontName, size: pointSize)
        wordButton.sizeToFit()
        var wordButtonRect: CGRect = wordButton.frame
        wordButtonRect.size.width = (((wordButtonRect.width + 3) / 2)) * 2
        wordButtonRect.size.height = (((wordButtonRect.height + 3) / 2)) * 2
        wordButton.frame = wordButtonRect
        wordButton.center = center
        
        if tappable {
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OverviewViewController.wordTapped(_:)))
            wordButton.addGestureRecognizer(tapGestureRecognizer)
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(OverviewViewController.wordLongPressed(_:)))
            wordButton.addGestureRecognizer(longPressRecognizer)
        }
        
        if isVertical {
            wordButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
        }
        
        self.cloudView.addSubview(wordButton)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        weak var weakSelf = self
        
        coordinator.animate(alongsideTransition: {(context) -> Void in
            let strongSelf = weakSelf
            strongSelf!.layoutCloudWords(for: self.cloudView.bounds.size)
            }, completion: nil)
        
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
    
    // Content size category has changed.  Layout cloud again, to account for new pointSize
    func contentSizeCategoryDidChange(_ __unused: Notification) {
        self.layoutCloudWords(for: self.cloudView.bounds.size)
    }
    
    func removeCloudWords() {
        
        let removableObjects = NSMutableArray()
        for subview: AnyObject in self.cloudView.subviews {
            if subview.isKind(of: UIButton.self) {
                removableObjects.add(subview)
            }
        }
        
        removableObjects.enumerateObjects( { object, index, stop in
            (object as AnyObject).removeFromSuperview()
        })
    }
    
    func layoutCloudWords(for size: CGSize) {
        
        self.cloudLayoutOperationQueue.cancelAllOperations()
        self.cloudLayoutOperationQueue.waitUntilAllOperationsAreFinished()
        self.removeCloudWords()
        
        let cloudFrame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        let newCloudLayoutOperation: CloudLayoutOperation = CloudLayoutOperation(cloudWords: self.cloudWords, fontName: self.cloudFontName, forContainerWithFrame: cloudFrame, scale: UIScreen.main.scale, delegate: self)
        self.cloudLayoutOperationQueue.addOperation(newCloudLayoutOperation)
        
        NSLog("cloud completed on %@", Thread.isMainThread ? "main thread" : "other thread")
    }
    
    @objc func wordTapped(_ sender: UITapGestureRecognizer) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            
            return
        }
        
        performSegue(withIdentifier: "ChartDetailSegueIdentifier", sender: sender.view)
    }
    
    @objc func wordLongPressed(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            print("UIGestureRecognizer.State Began")
            
            guard let chart = (self.charts.find{ $0.symbol == (sender.view as! UIButton).currentTitle }) else { return }
            
            Functions.promptAddToWatchlist(chart, registerChoice: true) { (choice) in
            }
        }
    }
}

extension OverviewViewController: iCarouselDataSource, iCarouselDelegate {
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return tickers.count
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
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
        
        guard let tickerAtIndex = tickers.get(index) else { return itemView }
        itemView.nameLabel.text = tickerAtIndex.symbol
        itemView.priceLabel.text = tickerAtIndex.priceFormatted
        //itemView.priceLabel.textColor = tickerAtIndex.changeInDollar < 0 ? Constants.stockSwipeRedColor : Constants.stockSwipeGreenColor
        
        itemView.priceChangeLabel.text = tickerAtIndex.changeFormatted
        itemView.priceChangeLabel.textColor = tickerAtIndex.changeInDollar < 0 ? Constants.stockSwipeRedColor : Constants.stockSwipeGreenColor
        
        return itemView
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        performSegue(withIdentifier: "ChartDetailSegueIdentifier", sender: carousel.itemView(at: index))
        
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        if option == .spacing {
            
            return value * 1.15
            
        } else if option == .wrap {
            
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == latestNewsTableView {
            return topStories.count
        } else if tableView == latestTradeIdeasTableView {
            return tradeIdeas.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
            
            guard let tradeIdeaAtIndex = self.tradeIdeas.get(indexPath.row) else { return cell }
            cell.configureCell(with: tradeIdeaAtIndex, timeFormat: .short)
            cell.delegate = self
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UITableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == latestNewsTableView {
            
            guard topStories.get(indexPath.row) != nil else {
                return
            }
            
            let newsAtIndex = self.topStories[indexPath.row]
            
            if let newsurl = newsAtIndex.url {
                Functions.presentSafariBrowser(with: URL(string: newsurl))
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK: - DZNEmptyDataSet Delegates
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        if scrollView == latestNewsTableView && !isQueryingForTopStories && topStories.count == 0 {
            return true
        } else if scrollView == latestTradeIdeasTableView && !isQueryingForTradeIdeas && tradeIdeas.count == 0 {
            return true
        }
        
        return false
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage? {
        if scrollView == latestTradeIdeasTableView {
            return UIImage(assetIdentifier: .noIdeaBulbImage)
        }
        
        return nil
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        var attributedTitle: NSAttributedString!
        
        if scrollView == latestNewsTableView {
            attributedTitle = NSAttributedString(string: "No News", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        } else if scrollView == latestTradeIdeasTableView {
            attributedTitle = NSAttributedString(string: "No Trade Ideas", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        }
        
        return attributedTitle
    }
}

extension OverviewViewController: IdeaPostDelegate {
        
    internal func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .new {
            
            let indexPath = IndexPath(row: 0, section: 0)
            self.tradeIdeas.insert(tradeIdea, at: 0)
            self.latestTradeIdeasTableView.insertRows(at: [indexPath], with: .automatic)
            
            self.latestTradeIdeasTableView.reloadEmptyDataSet()
        }
    }
    
    internal func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            
            if let reshareOf = tradeIdea.nestedTradeIdea, let reshareTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == reshareOf.parseObject.objectId })  {
                
                let indexPath = IndexPath(row: self.tradeIdeas.index(of: reshareTradeIdea)!, section: 0)
                self.latestTradeIdeasTableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            let indexPath = IndexPath(row: self.tradeIdeas.index(of: tradeIdea)!, section: 0)
            self.tradeIdeas.removeObject(tradeIdea)
            self.latestTradeIdeasTableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if tradeIdeas.count == 0 {
            self.latestTradeIdeasTableView.reloadEmptyDataSet()
        }
    }
    
    internal func ideaUpdated(with tradeIdea: TradeIdea) {
        if let currentTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == tradeIdea.parseObject.objectId }), let index = self.tradeIdeas.index(of: currentTradeIdea) {
            let indexPath = IndexPath(row: index, section: 0)
            self.latestTradeIdeasTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
