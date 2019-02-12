//
//  OverviewFirstPageViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/10/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import WordCloud
import SwiftyJSON
import DataCache
import SWXMLHash
import DZNEmptyDataSet
import NVActivityIndicatorView

class OverviewFirstPageViewController: UIViewController, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case ChartDetailSegueIdentifier = "ChartDetailSegueIdentifier"
    }
    
    var cloudWords = [CloudWord]()
    var tradeIdeas = [TradeIdea]()
    var topStories = [News]()
    
    var cloudFontName = "HelveticaNeue"
    
    var stockTwitsLastQueriedDate: Date!
    var tradeIdeasLastQueriedDate: Date!
    var topStoriesLastQueriedDate: Date!
    
    var isQueryingForTrendingStocks = false
    var isQueryingForTradeIdeas = false
    var isQueryingForTopStories = false
    
    var overviewVCOperationQueue: OperationQueue = OperationQueue()
    var cloudLayoutOperationQueue: OperationQueue = OperationQueue()
    
    var topStoriesRefreshControl = UIRefreshControl()
    
    var queryTimer: Timer!
    let QUERY_INTERVAL: Double = 60 // 5 minutes
    
    @IBOutlet var cloudView: UIView!
    
    @IBOutlet var trendingCloudShowButton: UIButton!
    
    @IBOutlet var latestNewsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.latestNewsTableView.tableFooterView = UIView(frame: CGRect.zero)
        topStoriesRefreshControl.addTarget(self, action: #selector(OverviewFirstPageViewController.refreshTopStories(_:)), for: .valueChanged)
        self.latestNewsTableView.addSubview(topStoriesRefreshControl)
        
        self.loadViewData(firstLaunch: true)
        self.scheduleQueryTimer()
        
        // register for foreground notificaions so we can refresh views
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewFirstPageViewController.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewFirstPageViewController.applicationsDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
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
        
        let topStoriesOperation = BlockOperation { () -> Void in
            self.queryTopStories()
        }
        topStoriesOperation.queuePriority = .normal
        
        overviewVCOperationQueue.addOperations([trendingCloudOperation, topStoriesOperation], waitUntilFinished: true)
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
    
    //    func queryTradeIdeas() {
    //
    //        guard Functions.isConnectedToNetwork() else { return }
    //
    //        if tradeIdeasLastQueriedDate != nil && self.tradeIdeas.count > 0 {
    //
    //            let timeSinceLastRefresh = Date().timeIntervalSince(tradeIdeasLastQueriedDate)
    //
    //            guard timeSinceLastRefresh > QUERY_INTERVAL else {
    //                DispatchQueue.main.async {
    //                    if self.tradeIdeasRefreshControl.isRefreshing == true {
    //                        self.tradeIdeasRefreshControl.endRefreshing()
    //                    }
    //                }
    //                return
    //            }
    //        }
    //
    //        isQueryingForTradeIdeas = true
    //
    //        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue], skip: nil, limit: QueryHelper.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"]) { (result) in
    //
    //            do {
    //
    //                let activityObjects = try result()
    //
    //                var tradeIdeaObjects = [PFObject]()
    //                for activityObject in activityObjects {
    //                    if let tradeIdeaObject = activityObject["tradeIdea"] as? PFObject {
    //                        tradeIdeaObjects.append(tradeIdeaObject)
    //                    }
    //                }
    //
    //                self.updateTradeIdeas(tradeIdeaObjects)
    //                self.tradeIdeasLastQueriedDate = Date()
    //
    //            } catch {
    //
    //                //TODO: Show sweet alert with Error.message()
    //                DispatchQueue.main.async {
    //                    if self.tradeIdeasRefreshControl.isRefreshing == true {
    //                        self.tradeIdeasRefreshControl.endRefreshing()
    //                    }
    //                }
    //            }
    //        }
    //    }
    
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
            guard let symbol = subJson["symbol"].string, let wordCount = trendingStocksJSON.count - Int(index)! as? NSNumber else { continue }
            guard let cloudWord = CloudWord(word: symbol , wordCount: wordCount, wordColor: UIColor.white, wordTappable: true) else { continue }
            self.cloudWords.append(cloudWord)
        }
        
        self.layoutCloudWords(for: self.cloudView.bounds.size)
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

                let destinationView = segue.destination as! CardDetailTabBarController
                symbol = (sender as! UIButton).currentTitle
                Functions.makeCard(for: symbol, completion: { card in
                    do {
                        let card = try card()
                        destinationView.card = card
                    } catch {
                        //  TODO: handle error
                    }
                })
            default:
                break
            }
        }
    }
}

extension OverviewFirstPageViewController: CloudLayoutOperationDelegate {
    
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
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OverviewFirstPageViewController.wordTapped(_:)))
            wordButton.addGestureRecognizer(tapGestureRecognizer)
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(OverviewFirstPageViewController.wordLongPressed(_:)))
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
            
            SweetAlert().showAlert("Can't Access Card!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            
            return
        }
        
        performSegue(withIdentifier: "ChartDetailSegueIdentifier", sender: sender.view)
    }
    
    @objc func wordLongPressed(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizer.State.began {
            print("UIGestureRecognizer.State Began")
            
            Functions.makeCard(for: (sender.view as! UIButton).currentTitle!, completion: { card in
                do {
                    let card = try card()
                    Functions.promptAddToWatchlist(card, registerChoice: true) { (choice) in }
                } catch {
                    //  TODO: handle error
                }
            })
        }
    }
}

extension OverviewFirstPageViewController: UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, CellType {
    
    enum CellIdentifier: String {
        case TopNewsCell = "TopNewsCell"
    }
    
    // MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topStories.count
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
        }
        
        return false
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage? {
        return nil
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        var attributedTitle: NSAttributedString!
        
        if scrollView == latestNewsTableView {
            attributedTitle = NSAttributedString(string: "No News", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        }
        
        return attributedTitle
    }
}