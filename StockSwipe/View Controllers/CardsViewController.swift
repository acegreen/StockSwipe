//
//  CardsViewController.swift
//  StockSwipe
//

import UIKit
import Foundation
import QuartzCore
import CoreData
import CoreSpotlight
import MDCSwipeToChoose
import Parse
import PulsingHalo
import Spring

class CardsViewController: UIViewController, MDCSwipeToChooseDelegate {
    
    var url: NSURL!
    var chartRequest:NSURLRequest!
    
    var isGettingObjects: Bool = false
    
    var parseObjects = [PFObject]()
    var extraSetOfObjects = [PFObject]()
    var randomIndexes = [Int]()
    var excludedIndexes = [Int]()
    var includedExchanges = [AnyObject]()
    var includedSectors = [AnyObject]()
    
    var charts = [Chart]()
    
    var numberOfCardsToQuery: Int = 50
    var numberofCardsInStack: Int = 3
    
    var firstCardView:SwipeChartView!
    var secondCardView:SwipeChartView!
    var thirdCardView:SwipeChartView!
    var fourthCardView:SwipeChartView!
    var informationCardView:UIView!
    
    var blureffect: UIBlurEffect!
    var blurView: UIVisualEffectView!
    
    let chartOffsetsX: CGFloat = 10
    let chartOffsetsY: CGFloat = 10
    var thresholdX: CGFloat = 0.75
    
    //var redButton:UIButton!
    //var skipButton:UIButton!
    //var reloadButton:UIButton!
    //var filterButton:UIButton!
    //var greenButton:UIButton!
    let buttonCircleLineWidth: CGFloat = 2.0
    
    let options:MDCSwipeToChooseViewOptions = MDCSwipeToChooseViewOptions()
    
    var halo: PulsingHaloLayer!
    
    enum CardType {
        
        case firstCard, secondCard, thirdCard, fourthCard
        
    }
    
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var reloadButton: UIBarButtonItem!
    
    @IBAction func reloadButtonPressed(sender: AnyObject) {
        
        guard !Functions.isConnectedToNetwork() && self.charts.count != 0 else {
            
            self.reloadCardViews()
            return
        }
        
        SweetAlert().showAlert("Reload?", subTitle: "Reloading with no internet will cause you to lose your loaded cards", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Cancel", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: "Reload", otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
            
            if !isOtherButton {
                
                self.reloadCardViews()
                
            }
        }
    }
    
    @IBOutlet var searchImage: UIImageView!
    
    @IBOutlet var mainViewNavigationBar: UINavigationBar!
    
    @IBAction func returnToMainviewController (segue:UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CardsViewController.setupFilters),name:"FilterSettingsChanged", object: nil)
        
        print("CardsViewController loaded")
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        // Get Parse Objects and Make Charts
        if self.charts.count <= 10 && !self.isGettingObjects {
            
            // GetObjects and make charts
            reloadCardViews()
        }
    }
    
    func reloadCardViews() {
        
        // Disable all buttons
        //self.fadeInOutButton("Out")
        reloadFilterButtonsEnabled(false)
        //self.enableDisableButtons("Off")
        
        // Check and remove subviews
        self.removalAllCardViews()
        
        // GetObjects and make charts
        do {
            
            try self.getObjectsAndMakeCharts()
            
        } catch  {
            
            if let error = error as? Constants.Errors {
                
                // Make information card
                self.makeCardWithInformation(error)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // Enable short/long buttons
                    //self.fadeInOutButton("In")
                    self.reloadFilterButtonsEnabled(true)
                })
            }
        }
    }
    
    func getObjectsAndMakeCharts() throws {
        
        guard Functions.isConnectedToNetwork() else {
            
            self.isGettingObjects = false
            
            throw Constants.Errors.NoInternetConnection
        }
        
        // Setup filters from defaults
        setupFilters()
        
        guard !self.includedExchanges.isEmpty && !self.includedSectors.isEmpty else {
            
            self.isGettingObjects = false
            
            throw Constants.Errors.NoExchangesOrSectorsSelected
        }
        
        // Mark fetching began
        self.isGettingObjects = true
        
        // Disable buttons and enable activity indicator
        self.reloadFilterButtonsEnabled(false)
        self.activityIndicatorSearchImageOnOff("Off")
        self.activityIndicatorSearchImageOnOff("On")
        
        // Setup config parameters
        Functions.setupConfigParameter("NUMBEROFCARDSTOQUERY") { (parameterValue) -> Void in
            
            self.numberOfCardsToQuery = parameterValue as? Int ?? 50
            
            self.getObjects({ (result) -> Void in
                
                do {
                    
                    self.randomIndexes = []
                    self.excludedIndexes = []
                    
                    try result()
                    
                    self.parseObjects += self.extraSetOfObjects
                    
                    self.getCharts({ (result) -> Void in
                        
                        do {
                            
                            try result()
                            
                            // Make 3 card stack
                            self.makeChartViews()
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                // Enable short/long buttons
                                //self.fadeInOutButton("In")
                                self.reloadFilterButtonsEnabled(true)
                            })
                            
                        } catch {
                            
                            if let error = error as? Constants.Errors {
                                
                                // Make information card
                                self.makeCardWithInformation(error)
                                
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    
                                    // Enable short/long buttons
                                    //self.fadeInOutButton("In")
                                    self.reloadFilterButtonsEnabled(true)
                                })
                            }
                        }
                    })
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        // Make information card
                        self.makeCardWithInformation(error)
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            // Enable short/long buttons
                            //self.fadeInOutButton("In")
                            self.reloadFilterButtonsEnabled(true)
                        })
                    }
                }
                
                self.isGettingObjects = false
            })
        }
    }
    
    // Mark - Get Symbols
    
    func getObjects(completion: (result: () throws -> Bool) -> Void) -> Void {
        
        PFCloud.callFunctionInBackground("getRandomStockObjects", withParameters: ["numberOfCardsToQuery":numberOfCardsToQuery, "includedExchanges": includedExchanges, "includedSectors": includedSectors]) { (results, error) -> Void in
            
            guard error == nil else {
                return completion(result: {throw Constants.Errors.ErrorAccessingParseDatabase})
            }
            
            guard results != nil else {
                return completion(result: {throw Constants.Errors.RanOutOfChartCards})
            }
        
            self.extraSetOfObjects = []
            
            // The find succeeded.
            print("Successfully retrieved \(results?.count) objects")
            
            // Do something with the found objects
            for object: PFObject in results as! [PFObject] {
                
                if !self.extraSetOfObjects.contains(object) {
                    
                    self.extraSetOfObjects.append(object)
                }
                
            }
            
            print("extraSetOfObjects count", self.extraSetOfObjects.count)
            
            completion(result: {return true})
            
        }
        
    }
    
    // Mark - Get Charts
    
    func getCharts(completion: (result: () throws -> Bool) -> Void) -> Void {
        
        guard extraSetOfObjects.count != 0  else {
           return completion(result: {throw Constants.Errors.RanOutOfChartCards})
        }
            
        for (index,object) in extraSetOfObjects.enumerate() {
            
            let symbol = object.objectForKey("Symbol") as! String
            let company = object.objectForKey("Company") as! String
            let shortedObject: AnyObject? = object.objectForKey("Shorted_By")
            let longedObject: AnyObject? = object.objectForKey("Longed_By")
            
            guard let chartImageURL: NSURL = Functions.setImageURL(symbol) else {
                
                print("image URL is nil")
                
                SweetAlert().showAlert("Couldn't load image", subTitle: "Please try again", style: AlertStyle.Warning)
                
                continue
            }
            
            let chartImageSession = NSURLSession.sharedSession()
            let task = chartImageSession.dataTaskWithURL(chartImageURL, completionHandler: { (chartImagedata, response, error) -> Void in
                
                guard error == nil else {
                    return completion(result: {throw Constants.Errors.ErrorAccessingServer})
                }
                
                if chartImagedata != nil {
                    
                    if let chartImage = UIImage(data: chartImagedata!) {
                        
                        let chart = Chart(symbol: symbol, companyName: company, image: chartImage, shorts: shortedObject?.count, longs: longedObject?.count, parseObject: object)
                        
                        if !self.charts.contains(chart) {
                            
                            self.charts.append(chart)
                            
                        }
                        
                        // Index to Spotlight
                        Functions.addToSpotlight(chart, uniqueIdentifier: chart.symbol, domainIdentifier: "com.stockswipe.stocksQueried")
                    }
                }
                
                // only if all charts are loaded then complete as true
                if index == self.extraSetOfObjects.count - 1 && self.charts.count != 0 {
                    
                    print("charts count:", self.charts.count)
                    completion(result: {return true})
                    
                } else if index == self.extraSetOfObjects.count - 1 && self.charts.count == 0 {
                    completion(result: {throw Constants.Errors.RanOutOfChartCards})
                }
            })
            
            task.resume()
        }
    }
    
    func makeChartViews() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.activityIndicatorSearchImageOnOff("Off")
            
            // Display First Card
            
            if self.firstCardView == nil {
                
                self.setFrontCardViewUpdate(self.popChartViewWithFrame(CardType.firstCard  , frame: CGRectMake(self.view.bounds.width + self.frontCardViewFrame().width, self.mainViewNavigationBar.frame.height + 50, chartWidth, chartHeight))!)
                
                self.firstCardView.userInteractionEnabled = true
                
                self.view.addSubview(self.firstCardView)
                
                self.firstCardView.transform = CGAffineTransformMakeRotation(CGFloat(degreesToRadians(30)))
                
                UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                    
                    self.firstCardView.transform = CGAffineTransformMakeRotation(CGFloat(degreesToRadians(0)))
                    
                    self.firstCardView.frame = self.frontCardViewFrame()
                    
                    }, completion: { (finished) -> Void in
                        
                        Functions.showPopTipOnceForKey("TAP_CARD_TIP_SHOWN", userDefaults: Settings.userDefaults,
                            popTipText: NSLocalizedString("Tap a card to view more details", comment: ""),
                            inView: self.view,
                            fromFrame: self.frontCardViewFrame(), direction: .Up, color: Constants.stockSwipeGreenColor)
                        
                })
            }
            
            // Display Second Card
            
            if self.secondCardView == nil {
                
                self.secondCardView = self.popChartViewWithFrame(CardType.secondCard, frame: CGRectMake(0 - self.frontCardViewFrame().width, self.frontCardViewFrame().origin.y + self.chartOffsetsY, CGRectGetWidth(self.frontCardViewFrame()) - (self.chartOffsetsX * 2), CGRectGetHeight(self.frontCardViewFrame())))
                
                self.secondCardView.userInteractionEnabled = false
                
                self.view.insertSubview(self.secondCardView, belowSubview: self.firstCardView)
                
                self.secondCardView.transform = CGAffineTransformMakeRotation(CGFloat(degreesToRadians(-30)))
                
                UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                    
                    self.secondCardView.transform = CGAffineTransformMakeRotation(CGFloat(degreesToRadians(0)))
                    
                    self.secondCardView.frame = self.middleCardViewFrame()
                    
                    }, completion: { (finished) -> Void in
                        
                })
                
            }
            
            // Display Third Card
            
            if self.thirdCardView == nil {
            
                self.thirdCardView = self.popChartViewWithFrame(CardType.thirdCard, frame: CGRectMake(self.middleCardViewFrame().origin.x + self.chartOffsetsX, self.view.bounds.height + CGRectGetHeight(self.middleCardViewFrame()), CGRectGetWidth(self.middleCardViewFrame()) - (self.chartOffsetsX * 2), CGRectGetHeight(self.middleCardViewFrame())))
                
                self.thirdCardView.userInteractionEnabled = false
                
                self.view.insertSubview(self.thirdCardView, belowSubview: self.secondCardView)
                
                UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                    
                    self.thirdCardView.frame = self.backCardViewFrame()
                    
                    }, completion: { (finished) -> Void in
                        
                        // Display Fourth Card
                        if self.fourthCardView == nil {
                            
                            self.fourthCardView = self.popChartViewWithFrame(CardType.fourthCard, frame: self.fourthCardViewFrame())
                            
                            if self.fourthCardView != nil {
                                
                                self.fourthCardView.userInteractionEnabled = false
                                
                                self.view.insertSubview(self.fourthCardView, belowSubview: self.thirdCardView)
                                
                                //                                // Draw shadow
                                //                                self.fourthCardView.layer.shadowOpacity = 0.5
                                //                                self.fourthCardView.layer.shadowRadius = 5
                                //                                self.fourthCardView.layer.shadowOffset = CGSizeMake(0, 10)
                                //                                self.fourthCardView.layer.shadowPath = UIBezierPath(roundedRect: self.fourthCardView.bounds, cornerRadius: 50).CGPath
                                
                            }
                        }
                        
                })
            }
            
            self.options.delegate = self
            Functions.setupConfigParameter("THRESHOLDX", completion: { (parameterValue) -> Void in
                
                if parameterValue != nil {
                     self.thresholdX = parameterValue as! CGFloat
                }
                
                self.options.threshold = (self.view.bounds.width / 2) * self.thresholdX
                print(self.options.threshold)
                
                self.options.onPan = { state -> Void in
                    
                    if self.secondCardView != nil {
                        
                        let frame:CGRect = self.middleCardViewFrame()
                        self.secondCardView.frame = CGRectMake(frame.origin.x, frame.origin.y-(state.thresholdRatio * 10), CGRectGetWidth(frame), CGRectGetHeight(frame))
                    }
                    
                    if self.thirdCardView != nil {
                        
                        let frame:CGRect = self.backCardViewFrame()
                        self.thirdCardView.frame = CGRectMake(frame.origin.x, frame.origin.y-(state.thresholdRatio * 8), CGRectGetWidth(frame), CGRectGetHeight(frame))
                    }
                    
                    if self.fourthCardView != nil {
                        
                        let frame:CGRect = self.backCardViewFrame()
                        self.fourthCardView.frame = CGRectMake(frame.origin.x, frame.origin.y-(state.thresholdRatio), CGRectGetWidth(frame), CGRectGetHeight(frame))
                    }
                    
                    if self.informationCardView != nil {
                        
                        let frame:CGRect = self.backCardViewFrame()
                        self.informationCardView.frame = CGRectMake(frame.origin.x, frame.origin.y-(state.thresholdRatio), CGRectGetWidth(frame), CGRectGetHeight(frame))
                    }
                }
                
            })
        })
    }
    
    func makeCardWithInformation(error: Constants.Errors) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.activityIndicatorSearchImageOnOff("Off")
            
            guard self.informationCardView == nil else { return }
            
            self.informationCardView = NoChartView(frame: self.backCardViewFrame(), text: error.message())
            
            self.view.addSubview(self.informationCardView)
            self.view.sendSubviewToBack(self.informationCardView)
            
            self.informationCardView.alpha = 0.0
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: {
                
                self.informationCardView.alpha = 1.0
                
                //            // draw shadow
                //            self.informationCardView.layer.shadowOpacity = 0.5
                //            self.informationCardView.layer.shadowRadius = 5
                //            self.informationCardView.layer.shadowOffset = CGSizeMake(0, 10)
                //            self.informationCardView.layer.shadowPath = UIBezierPath(roundedRect: self.informationCardView.bounds, cornerRadius: 50).CGPath
                
                },completion:nil)
        })
    }
    
    func view(view: UIView!, shouldBeChosenWithDirection direction: MDCSwipeDirection) -> Bool {
        
        if (direction == .Left || direction == .Right) {
            
            guard Functions.isUserLoggedIn(self) else { return false }
        }
        
        return true
    }
    
    // This is called when a user swipes the view in a direction.
    func view(view: UIView, wasChosenWithDirection: MDCSwipeDirection) -> Void {
        
        // MDCSwipeToChooseView shows "SHORT" on swipes to the left,
        // and "LONG" on swipes to the right.
        
        guard let chartChoosen: Chart = self.charts.find({$0.symbol == self.firstCardView.chart.symbol}) else { return }
        
        if wasChosenWithDirection == MDCSwipeDirection.Left {
            
            Functions.registerUserChoice(chartChoosen, and: chartChoosen.parseObject, with: .SHORT)
            
        } else if wasChosenWithDirection == MDCSwipeDirection.Right {
            
            Functions.registerUserChoice(chartChoosen, and: chartChoosen.parseObject, with: .LONG)
            
        } else if wasChosenWithDirection == MDCSwipeDirection.Up {
            
            print("swiped up")
            
        }
        
        self.parseObjects.removeObject(chartChoosen.parseObject!)
        self.charts.removeObject(chartChoosen)
        
        // MDCSwipeToChooseView removes the view from the view hierarchy
        // after it is swiped (this behavior can be customized via the
        // MDCSwipeOptions class). Since the front card view is gone, we
        // move the middle card to the front, and create a new back card.
        
        if secondCardView != nil {
            
            self.setFrontCardViewUpdate(self.secondCardView)
            
        }
        
        self.resizeCardViews()
        
        // Fade the back card into view.
        self.fourthCardView = self.popChartViewWithFrame(CardType.fourthCard, frame: self.fourthCardViewFrame())
        
        // Display Fourth Card
        if self.fourthCardView != nil {
            
            self.fourthCardView.userInteractionEnabled = false
            
            if thirdCardView != nil {
                
                self.view.insertSubview(self.fourthCardView, belowSubview: self.thirdCardView)
                
                if informationCardView == nil {
                    
                    //                    // Draw shadow
                    //                    self.fourthCardView.layer.shadowOpacity = 0.5
                    //                    self.fourthCardView.layer.shadowRadius = 5
                    //                    self.fourthCardView.layer.shadowOffset = CGSizeMake(0, 10)
                    //                    self.fourthCardView.layer.shadowPath = UIBezierPath(roundedRect: self.fourthCardView.bounds, cornerRadius: 50).CGPath
                }
                
            } else {
                
                makeChartViews()
                
            }
        }
        
        if self.charts.count <= 10 && !self.isGettingObjects {
            
            // GetObjects and make charts
            do {
                
                try self.getObjectsAndMakeCharts()
                
            } catch  {
                
                if let error = error as? Constants.Errors {
                    
                    // Make information card
                    self.makeCardWithInformation(error)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        // Enable short/long buttons
                        //self.fadeInOutButton("In")
                        self.reloadFilterButtonsEnabled(true)
                    })
                }
            }
            
        }
        
        // Create NSUserActivity
        Functions.createNSUserActivity(chartChoosen, uniqueIdentifier: chartChoosen.symbol, domainIdentifier: "com.stockswipe.stocksSwiped")
        
        print("charts.count after swipe", self.charts.count)
        
        //        self.enableDisableButtons("On")
    }
    
    // This is called when a user didn't fully swipe left or right.
    func viewDidCancelSwipe(view: UIView) -> Void {
        
        print("You couldn't decide")
        
        if self.secondCardView != nil {
            
            let frame:CGRect = self.frontCardViewFrame()
            self.secondCardView.frame = CGRectMake(frame.origin.x + chartOffsetsX, frame.origin.y + chartOffsetsY, CGRectGetWidth(frame) - (chartOffsetsX * 2), CGRectGetHeight(frame))
        }
        
        if self.thirdCardView != nil {
            
            let frame:CGRect = self.middleCardViewFrame()
            self.thirdCardView.frame = CGRectMake(frame.origin.x + chartOffsetsX, frame.origin.y + chartOffsetsY, CGRectGetWidth(frame) - (chartOffsetsX * 2), CGRectGetHeight(frame))
        }
    }
    
    func viewDidGetTapped(view: UIView!) {
        
        print("View did get tapped")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.performCustomSegue(self)
            
        })
    }
    
    func setFrontCardViewUpdate(CardView: SwipeChartView) -> Void {
        
        // Keep track of the chart currently on top
        self.firstCardView = CardView
        self.secondCardView = self.thirdCardView
        self.thirdCardView = self.fourthCardView
        
        if firstCardView != nil {
            
            self.firstCardView.userInteractionEnabled = true
            
        }
    }
    
    func popChartViewWithFrame(cardType: CardType, frame:CGRect) -> SwipeChartView? {
        
        if let chartAtIndex = self.charts.get(cardLocation(cardType)) {
            
            return SwipeChartView(frame: frame, chart: chartAtIndex, options: options)
            
        } else {
            
            return nil
        }
        
    }
    
    func cardLocation(input: CardType) -> Int {
        
        switch input {
            
        case .firstCard: return 0
        case .secondCard: return 1
        case .thirdCard: return 2
        case .fourthCard: return 3
            
        }
    }
    
    func frontCardViewFrame() -> CGRect {
        
        return CGRect(x: CGRectGetMidX(self.view.bounds) - (chartWidth / 2), y: CGRectGetMidY(self.view.bounds) - (chartHeight / 2) + frontCardOffsetFromCenter, width: chartWidth, height: chartHeight)
        
    }
    
    func middleCardViewFrame() ->CGRect {
        
        let frontFrame:CGRect = frontCardViewFrame()
        return CGRectMake(frontFrame.origin.x + chartOffsetsX, frontFrame.origin.y + chartOffsetsY, CGRectGetWidth(frontFrame) - (chartOffsetsX * 2), CGRectGetHeight(frontFrame))
        
    }
    
    func backCardViewFrame() ->CGRect {
        
        let middleFrame:CGRect = middleCardViewFrame()
        return CGRectMake(middleFrame.origin.x + chartOffsetsX, middleFrame.origin.y + chartOffsetsY, CGRectGetWidth(middleFrame) - (chartOffsetsX * 2), CGRectGetHeight(middleFrame))
        
    }
    
    func fourthCardViewFrame() ->CGRect {
        
        let thirdFrame:CGRect = backCardViewFrame()
        return CGRectMake(thirdFrame.origin.x + chartOffsetsX, thirdFrame.origin.y, CGRectGetWidth(thirdFrame) - (chartOffsetsX * 2), CGRectGetHeight(thirdFrame))
        
    }
    
    func nopefirstCardView() {
        
        self.firstCardView.mdc_swipe(MDCSwipeDirection.Left)
        //self.enableDisableButtons("Off")
        
    }
    
    func likefirstCardView() {
        
        self.firstCardView.mdc_swipe(MDCSwipeDirection.Right)
        //self.enableDisableButtons("Off")
        
    }
    
    func skipfirstCardView() {
        
        self.firstCardView.mdc_swipe(MDCSwipeDirection.Up)
        //self.enableDisableButtons("Off")
        
    }
    
    func setupFilters() {
        
        includedExchanges = []
        includedSectors = []
        
        for exchange in Constants.Symbol.Exchange.allExchanges {
            
            guard Settings.userDefaults.boolForKey(exchange.key()) == true else { continue }
            
            includedExchanges.append(exchange.key())
        }
        
        for sector in Constants.Symbol.Sector.allSectors {
            
            guard Settings.userDefaults.boolForKey(sector.key()) else { continue }
            
            includedSectors.append(sector.key().startCase)
        }
        
        print("includedExchanges:", includedExchanges)
        print("includedSectors:", includedSectors)
    }
    
    //    func nightModeToggle() {
    //
    //        nightModeButton.selected = !nightModeButton.selected
    //
    //        if nightModeButton.selected {
    //
    //            print("nightMode")
    //
    ////            let superview = self.view.superview
    ////            self.view.removeFromSuperview()
    ////            self.view = nil
    ////            superview!.addSubview(self.view)
    ////
    //            // Replace blur effect
    //            blureffect = UIBlurEffect(style: .Dark)
    //            blurView = UIVisualEffectView(effect: blureffect)
    //            self.viewWillAppear(false)
    //
    //        } else {
    //
    //            print("dayMode")
    //
    //        }
    //
    //    }
    
    func activityIndicatorSearchImageOnOff (state: String) {
        
        if state == "On" {
            
            if firstCardView == nil && secondCardView == nil && thirdCardView == nil {
                
                // Create loading animation
                self.halo = PulsingHaloLayer()
                self.halo.position = Functions.getCenterOfView(self.view)
                self.halo.radius = self.view.bounds.height / 2
                self.halo.backgroundColor = UIColor.grayColor().CGColor
                self.halo.useTimingFunction = false
                halo.haloLayerNumber = 3
                self.view.layer.addSublayer(self.halo)
                self.halo.start()
                
                self.searchImage.hidden = false
                self.searchImage.tintColor = UIColor.grayColor()
                self.view.bringSubviewToFront(self.searchImage)
                
            }
            
        } else if state == "Off" {
            
            if self.halo !=  nil {
                
                self.halo.removeFromSuperlayer()
                self.searchImage.hidden = true
            }
        }
    }
    
    func reloadFilterButtonsEnabled (state: Bool) {
        
        if state {
            self.reloadButton.enabled = true
            self.filterButton.enabled = true
        } else {
            self.reloadButton.enabled = false
            self.filterButton.enabled = false
        }
    }
    
    func resizeCardViews() {
        
        // resize the middle card as it becomes top view.
        if firstCardView != nil {
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                self.firstCardView.frame = self.frontCardViewFrame()
                
            })
        }
        
        // resize the second as it becomes middle view.
        if secondCardView != nil {
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                self.secondCardView.frame = self.middleCardViewFrame()
            })
            
        }
        
        // resize the back card as it becomes middle view.
        if thirdCardView != nil {
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                self.thirdCardView.frame = self.backCardViewFrame()
                //                self.thirdCardView.layer.shadowOpacity = 0.0
            })
            
        }
        
        // resize information card if it exits
        if informationCardView != nil {
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                self.informationCardView.frame = self.backCardViewFrame()
            })
            
        }
    }
    
    func removalAllCardViews() {
        
        if (self.fourthCardView != nil) {
            
            self.fourthCardView.removeFromSuperview()
            self.fourthCardView = nil
        }
        
        if (self.thirdCardView != nil) {
            
            self.thirdCardView.removeFromSuperview()
            self.thirdCardView = nil
        }
        
        if (self.secondCardView != nil) {
            
            self.secondCardView.removeFromSuperview()
            self.secondCardView = nil
            
        }
        
        if (self.firstCardView != nil) {
            
            self.firstCardView.removeFromSuperview()
            self.firstCardView = nil
            
        }
        
        if (self.informationCardView != nil) {
            
            self.informationCardView.removeFromSuperview()
            self.informationCardView = nil
            
        }
        
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showChartDetail" {
            
            let destinationView = segue.destinationViewController as! ChartDetailTabBarController
            destinationView.symbol = firstCardView.chart.symbol
            destinationView.companyName = firstCardView.chart.companyName
        }
    }
    
    func performCustomSegue(whoThat: AnyObject?) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.Warning)
            return
        }
        
        self.performSegueWithIdentifier("showChartDetail", sender: whoThat)
    }
    
    //    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
    //
    //        let segue = CustomUnwindSegue(identifier: identifier, source: fromViewController, destination: toViewController)
    //        return segue
    //
    //    }
}