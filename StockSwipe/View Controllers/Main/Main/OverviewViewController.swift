//
//  OverviewViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-29.
//  Copyright © 2015 Ace Green. All rights reserved.
//

import UIKit
import Parse
import DataCache
import Reachability

class OverviewViewController: UIViewController, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case ChartDetailSegueIdentifier = "ChartDetailSegueIdentifier"
        case SearchSegueIdentifier = "SearchSegueIdentifier"
        case PostIdeaSegueIdentifier = "PostIdeaSegueIdentifier"
        case OverviewContainerEmbededSegueIdentifier = "OverviewContainerEmbededSegueIdentifier"
    }
    
    var animationDelegate: SplashAnimationDelegate?
    
    var iCarouselTickers = ["^IXIC","^GSPC","^RUT","^VIX","^GDAXI","^FTSE","^FCHI","^N225","^HSI","^GSPTSE","CAD=X"]
    var tickers = [Ticker]()
    
    var overviewVCOperationQueue: OperationQueue = OperationQueue()
    var carouselLastQueriedDate: Date!

    var isQueryingForiCarousel = false
    var queryTimer: Timer?
    let QUERY_INTERVAL: Double = 60 // 5 minutes
    
    let reachability = Reachability()
    
    @IBOutlet var carousel : iCarousel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.autoscroll = -0.3
        carousel.type = .linear
        carousel.contentOffset = CGSize(width: 0, height: 10)
        
        self.handleReachability()
        
        // register for foreground notificaions so we can refresh views
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewViewController.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OverviewViewController.applicationsDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        overviewVCOperationQueue.cancelAllOperations()
        NotificationCenter.default.removeObserver(self)
        self.reachability?.stopNotifier()
        self.queryTimer?.invalidate()
    }
    
    @objc func applicationWillEnterForeground() {
        self.handleReachability()
    }
    
    @objc func applicationsDidEnterBackground() {
        self.reachability?.stopNotifier()
        self.queryTimer?.invalidate()
    }
    
    private func scheduleQueryTimer() {
        self.queryTimer = Timer.scheduledTimer(withTimeInterval: QUERY_INTERVAL, repeats: true, block: { timer in
            self.loadViewData()
        })
    }
    
    private func loadViewData() {
        
        let marketCarouselOperation = BlockOperation { () -> Void in
            self.queryCarouselTickers()
        }
        marketCarouselOperation.queuePriority = .normal
        overviewVCOperationQueue.addOperations([marketCarouselOperation], waitUntilFinished: true)
        
        self.scheduleQueryTimer()
    }
    
    private func loadCachedData() {
        if let carouselCacheData = DataCache.instance.readData(forKey: "CAROUSELCACHEDATA") {
            self.updateCarousel(from: try! QueryHelper.EODQuoteResult.decodeFrom(data: carouselCacheData))
        }
        
        if self.carouselLastQueriedDate == nil {
            let animationOperation = BlockOperation { () -> Void in
                self.animationDelegate?.didFinishLoading()
            }
            animationOperation.queuePriority = .normal
            self.overviewVCOperationQueue.addOperation(animationOperation)
        }
    }
    
    func queryCarouselTickers() {
        
        if carouselLastQueriedDate != nil {
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
                    
                    if self.carouselLastQueriedDate == nil {
                        let animationOperation = BlockOperation { () -> Void in
                            self.animationDelegate?.didFinishLoading()
                        }
                        animationOperation.queuePriority = .normal
                        self.overviewVCOperationQueue.addOperation(animationOperation)
                    }
                    
                    self.carouselLastQueriedDate = Date()
                } catch {
                    //TODO: handle error
                }
                
                self.isQueryingForiCarousel = false
            })
        }
    }
        
    func updateCarousel(from eodQuoteResults: [QueryHelper.EODQuoteResult]) {
        
        self.tickers = Ticker.makeTickers(from: eodQuoteResults)
        DispatchQueue.main.async {
            self.carousel.reloadData()
            NSLog("carousel completed on %@", Thread.isMainThread ? "main thread" : "other thread")
        }
    }
    
    // MARK: - Segue Method
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .ChartDetailSegueIdentifier:
            let cardDetailViewController = segue.destination as! CardDetailViewController
            cardDetailViewController.card = sender as? Card
            cardDetailViewController.forceDisableDragDownToDismiss = true
            
        case .PostIdeaSegueIdentifier:
            
            let destinationViewController = segue.destination as! UINavigationController
            let ideaPostViewController = destinationViewController.viewControllers.first as! IdeaPostViewController
            ideaPostViewController.tradeIdeaType = .new
//            ideaPostViewController.delegate =  self
            
        case .SearchSegueIdentifier, .OverviewContainerEmbededSegueIdentifier:
            break
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
        //itemView.priceLabel.textColor = tickerAtIndex.changeInDollar < 0 ? Constants.stockSwipeRedColor : Constants.SSColors.green
        
        itemView.priceChangeLabel.text = tickerAtIndex.changeFormatted
        itemView.priceChangeLabel.textColor = tickerAtIndex.changeInDollar < 0 ? Constants.SSColors.red : Constants.SSColors.green
        
        return itemView
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Access Card!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        self.carousel.isUserInteractionEnabled = false
        
        if let tickerAtIndex = tickers.get(index) {
            Functions.makeCard(for: tickerAtIndex.symbol) { card in
                do {
                    let card = try card()
                    
                    DispatchQueue.main.async {
                        self.performSegueWithIdentifier(.ChartDetailSegueIdentifier, sender: card)
                    }
                } catch {
                    if let error = error as? QueryHelper.QueryError {
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
                
                self.carousel.isUserInteractionEnabled = true
            }
        }
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

extension OverviewViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            self.loadViewData()
        }
        
        self.reachability?.whenUnreachable = { _ in
            self.loadCachedData()
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}

//extension OverviewViewController: IdeaPostDelegate {
//        
//    internal func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
//
//        if tradeIdeaTyp == .new {
//
//            let indexPath = IndexPath(row: 0, section: 0)
//            self.tradeIdeas.insert(tradeIdea, at: 0)
//            self.latestTradeIdeasTableView.insertRows(at: [indexPath], with: .automatic)
//
//            self.latestTradeIdeasTableView.reloadData()
//        }
//    }
//
//    internal func ideaDeleted(with parseObject: PFObject) {
//
//        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
//
//            if let reshareOf = tradeIdea.nestedTradeIdea, let reshareTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == reshareOf.parseObject.objectId })  {
//
//                let indexPath = IndexPath(row: self.tradeIdeas.index(of: reshareTradeIdea)!, section: 0)
//                self.latestTradeIdeasTableView.reloadRows(at: [indexPath], with: .automatic)
//            }
//
//            let indexPath = IndexPath(row: self.tradeIdeas.index(of: tradeIdea)!, section: 0)
//            self.tradeIdeas.removeObject(tradeIdea)
//            self.latestTradeIdeasTableView.deleteRows(at: [indexPath], with: .automatic)
//        }
//
//        if tradeIdeas.count == 0 {
//            self.latestTradeIdeasTableView.reloadData()
//        }
//    }
//
//    internal func ideaUpdated(with tradeIdea: TradeIdea) {
//        if let currentTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == tradeIdea.parseObject.objectId }), let index = self.tradeIdeas.index(of: currentTradeIdea) {
//            let indexPath = IndexPath(row: index, section: 0)
//            self.latestTradeIdeasTableView.reloadRows(at: [indexPath], with: .none)
//        }
//    }
//}
