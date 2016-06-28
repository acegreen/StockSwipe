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
import SafariServices
import DZNEmptyDataSet

class OverviewViewController: UIViewController, CloudLayoutOperationDelegate {
    
    var iCarouselTickers = ["^IXIC","^GSPC","^RUT","^VIX","^GDAXI","^FTSE","^FCHI","^N225","^HSI","^GSPTSE","CAD=X"]
    var tickers = [Ticker]()
    var cloudWords = [CloudWord]()
    var trendingStocksJSON = JSON.null
    var news = [News]()
    var charts = [Chart]()
    
    var cloudColors:[UIColor] = [UIColor.grayColor()]
    var cloudFontName = "HelveticaNeue"

    var stockTwitsLastQueriedDate: NSDate!
    var carouselLastQueriedDate: NSDate!
    var topStoriesLastQueriedDate: NSDate!
    
    var refreshControl = UIRefreshControl()
    var overviewVCOperationQueue: NSOperationQueue = NSOperationQueue()
    
    @IBOutlet var carousel : iCarousel!
    
    @IBOutlet var cloudView: UIView!
    
    @IBOutlet var latestNewsTableView: UITableView!
    
    @IBOutlet var cloudLockedImage: UIImageView!

    @IBOutlet var emptyLabel1: UILabel!
    
    @IBOutlet var emptyLabel2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.autoscroll = -0.3
        carousel.type = .Linear
        carousel.contentOffset = CGSize(width: 0, height: 10)
        
        // set tableView properties
        self.latestNewsTableView.rowHeight = UITableViewAutomaticDimension
        self.latestNewsTableView.estimatedRowHeight = 100.0
        
        // Add refresh control to top stories tableView
        self.latestNewsTableView.tableFooterView = UIView(frame: CGRectZero)
        refreshControl.addTarget(self, action: #selector(OverviewViewController.refreshTopStories(_:)), forControlEvents: .ValueChanged)
        self.latestNewsTableView.addSubview(refreshControl)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        reloadViewData()
    }
    
    //    deinit {
    //        cloudLayoutOperationQueue.cancelAllOperations()
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Carousel Functions
    
    func queryICarouselTickers() {
        
        if carouselLastQueriedDate != nil {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(carouselLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 1 else {
                return
            }
        }
        
        print("refreshing carousel")
        
        // Setup config parameters
        Functions.setupConfigParameter("CAROUSELTICKERARRAY") { (parameterValue) -> Void in
            
            if parameterValue != nil {
                self.iCarouselTickers = parameterValue as! [String]
            }
            
            QueryHelper.sharedInstance.queryYahooSymbolQuote(self.iCarouselTickers, completionHandler: { (symbolQuote, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if symbolQuote != nil {
                    
                    guard let carsouelJson:JSON? = JSON(data: symbolQuote!) else { return }
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
                        
                        let chart = Chart(symbol: symbol, companyName: companyName, image: nil, shorts: nil, longs: nil, parseObject: nil)
                        
                        self.tickers.append(ticker)
                        self.charts.append(chart)
                        
                        
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.carousel.reloadData()
                        self.carouselLastQueriedDate = NSDate()
                        
                        print("carousel query complete")
                    })
                }
            })
        }
    }
    
    // MARK: - <CloudLayoutOperationDelegate>
    
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
        self.overviewVCOperationQueue.addOperation(newCloudLayoutOperation)
        
        print("layoutCloudWords complete")
    }
    
    func wordTapped(sender: UITapGestureRecognizer) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            
            return
        }
        
        performSegueWithIdentifier("showChartDetail", sender: sender.view)
    }
    
    func wordLongPressed(sender: UILongPressGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            print("UIGestureRecognizerState Began")
            
            guard Functions.isConnectedToNetwork() else {
                
                SweetAlert().showAlert("Can't Add To Watchlist!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
                return
            }
            
            guard let chart = (self.charts.find{ $0.symbol == (sender.view as! UIButton).currentTitle }) else { return }
            
            QueryHelper.sharedInstance.queryChartImage(chart.symbol, completion: { (result) in
                
                do {
                    
                    let chartImage = try result()
                    
                    chart.image = chartImage
                    
                    
                } catch {
                    
                    print(error)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    SweetAlert().showAlert("Add To Watchlist?", subTitle: "Do you like this symbol as a long or short trade", style: AlertStyle.CustomImag(imageFile: "add"), dismissTime: nil, buttonTitle:"SHORT", buttonColor:UIColor.redColor() , otherButtonTitle: "LONG", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                        
                        guard Functions.isUserLoggedIn(self) else { return }
                        
                        if !isOtherButton {
                            
                            Functions.registerUserChoice(chart, and: chart.parseObject, with: .LONG)
                            
                        } else if isOtherButton {
                            
                            Functions.registerUserChoice(chart, and: chart.parseObject, with: .SHORT)
                        }
                    }
                    
                })
                
                // Index to Spotlight
                Functions.addToSpotlight(chart, uniqueIdentifier: chart.symbol, domainIdentifier: "com.stockswipe.stocksQueried")
            })
        }
    }
    
    func reloadViewData() {
        
        overviewVCOperationQueue.cancelAllOperations()
        overviewVCOperationQueue.waitUntilAllOperationsAreFinished()
        
        let trendingCloudOperation = NSBlockOperation { () -> Void in
            self.requestStockTwitsTrendingStocks()
        }
        trendingCloudOperation.queuePriority = .High
        
        let marketCarouselOperation = NSBlockOperation { () -> Void in
            self.queryICarouselTickers()
        }
        marketCarouselOperation.queuePriority = .Normal
        
        let topStoriesOperation = NSBlockOperation { () -> Void in
            self.grabTopStories()
        }
        topStoriesOperation.queuePriority = .Normal
        
        overviewVCOperationQueue.addOperations([trendingCloudOperation, marketCarouselOperation, topStoriesOperation], waitUntilFinished: false)
    }
    
    func requestStockTwitsTrendingStocks() {
        
        // Layout dummy words until later
        if cloudWords.count == 0 && stockTwitsLastQueriedDate == nil {
            
            let noInternetSentence = "The cloud is empty we ran out of words or are still trying to find some Weird indeed"
            let breakupSentence = noInternetSentence.componentsSeparatedByString(" ")
            
            for (index, word) in breakupSentence.enumerate() {
                let cloudWord = CloudWord(word: word, wordCount: breakupSentence.count - Int(index), wordTappable: false)
                self.cloudWords.append(cloudWord)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.layoutCloudWords()
                self.cloudWords = []
                
            })
        }
        
        guard Functions.isConnectedToNetwork() else { return }
        
        if stockTwitsLastQueriedDate != nil && self.cloudWords.count > 0 {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(stockTwitsLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 5 else {
                return
            }
        }
        
        print("refreshing cloud")
        
        QueryHelper.sharedInstance.queryStockTwitsTrendingStocks { (trendingStocksData) in
        
            do {
                
                let trendingStocksData = try trendingStocksData()
                
                self.trendingStocksJSON = JSON(data: trendingStocksData)["symbols"]
                guard self.trendingStocksJSON.error == nil else { return }
                
                QueryHelper.sharedInstance.queryStockObjectsFor(self.trendingStocksJSON.map { $0.1 }.map{ $0["symbol"].string! }, completion: { (result) in
                    
                    do {
                        
                        let stockObjects = try result()
                        self.cloudWords = []
                        
                        for (index, subJson) in self.trendingStocksJSON {
                            
                            if let chart = (self.charts.find{ $0.symbol == subJson["symbol"].string!}) {
                                self.charts.removeObject(chart)
                            }
                            
                            let parseObject = stockObjects.find{ $0["Symbol"] as! String == subJson["symbol"].string!}
                            
                            let shorts = parseObject?["Shorted_By"]
                            let longs = parseObject?["Longed_By"]
                            
                            let cloudWord = CloudWord(word: subJson["symbol"].string! , wordCount: self.trendingStocksJSON.count - Int(index)!, wordTappable: true)
                            self.cloudWords.append(cloudWord)
                            
                            let chart = Chart(symbol: subJson["symbol"].string!, companyName: subJson["title"].string!, image: nil, shorts: shorts?.count, longs: longs?.count, parseObject: parseObject)
                            self.charts.append(chart)
                            
                            //Index to Spotlight
                            Functions.addToSpotlight(chart, uniqueIdentifier: chart.symbol, domainIdentifier: "com.stockswipe.stocksQueried")
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.layoutCloudWords()
                        })
                        
                        self.stockTwitsLastQueriedDate = NSDate()
                        
                        print("cloud query complete")
                        
                    } catch {
                        
                        if let error = error as? Constants.Errors {
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                            })
                        }
                    }
                    
                })
                
            } catch {
                
            }
        }
    }
    
    func refreshTopStories(refreshControl: UIRefreshControl) {
        let topStoriesOperation = NSBlockOperation { () -> Void in
            self.grabTopStories()
        }
        topStoriesOperation.queuePriority = .VeryHigh
        overviewVCOperationQueue.addOperation(topStoriesOperation)
    }
    
    func grabTopStories() {
        
        if topStoriesLastQueriedDate != nil {
            
            let timeSinceLastRefresh = NSDate().timeIntervalSinceDate(topStoriesLastQueriedDate)
            
            guard timeSinceLastRefresh / 60 > 1 else {
                self.refreshControl.endRefreshing()
                return
            }
        }
        
        print("refreshing top stories")
        
        let queryString = "http://feeds.reuters.com/reuters/businessNews?format=xml"
        
        QueryHelper.sharedInstance.queryWith(queryString) { (result) -> Void in
            
            do {
            
                let result = try result()
                let xml = SWXMLHash.parse(result)
                
                do {
                    
                    let items = try xml.byKey("rss").byKey("channel").byKey("item")
                    
                    self.news = []
                    
                    for item in items {
                        
                        var newsDecodedTitle: String!
                        var newsUrl: String!
                        var newsDetails: String!
                        var newsPublishedDate: String!
                        
                        // Get title
                        if let title = item["title"].element!.text {
                            newsDecodedTitle = title.decodeEncodedString()
                        }
                        
                        // Get URL
                        if let link = item["link"].element!.text {
                            newsUrl = link.decodeEncodedString()
                        }
                        
                        // Get details
                        if let description = item["description"].element!.text {
                            newsDetails = description.decodeEncodedString()
                        }
                        
                        // Get Published Date
                        if let pubDate = item["pubDate"].element!.text {
                            let publishedDateFormatter = NSDateFormatter()
                            publishedDateFormatter.dateFormat = "EEE, dd MMM yy HH:mm:ss z"
                            
                            if let formattedDate: NSDate? = publishedDateFormatter.dateFromString(pubDate) {
                                newsPublishedDate = formattedDate!.formattedAsTimeAgo()
                            }
                        }
                        
                        let newNews = News(image: nil, title: newsDecodedTitle, details: newsDetails,url: newsUrl, publisher: nil, publishedDate: newsPublishedDate)
                        self.news.append(newNews)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.latestNewsTableView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.topStoriesLastQueriedDate = NSDate()
                        
                        print("top stories query complete")
                        
                    })
                    
                } catch let error as XMLIndexer.Error {
                        print("\(error)")
                }
                
            } catch {
                
                if error is Constants.Errors {
                        print(error)
                }
            }
        }
    }
    
    // MARK: - Segue Method
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showChartDetail" {
            
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
        
        performSegueWithIdentifier("showChartDetail", sender: carousel.itemViewAtIndex(index))
        
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

    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return news.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as TopNewsCell
        
        guard news.get(indexPath.row) != nil else { return cell }
        
        let newsAtIndex = self.news[indexPath.row]
        
        if let newsTitleAtIndex = newsAtIndex.title {
            
            cell.newsTitle.text = newsTitleAtIndex
        }
        
        if let newsDetails = newsAtIndex.details {
            
            cell.newsDescription.text = newsDetails
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard news.get(indexPath.row) != nil else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        let newsAtIndex = self.news[indexPath.row]
        
        if let newsurl = newsAtIndex.url {
            
            Functions.presentSafariBrowser(NSURL(string: newsurl))

        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(assetIdentifier: .newsBigImage)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        attributedTitle = NSAttributedString(string: "No News?", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
}