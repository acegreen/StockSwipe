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
import NVActivityIndicatorView
import Crashlytics

class CardsViewController: UIViewController, MDCSwipeToChooseDelegate {
    
    var url: URL!
    var chartRequest:URLRequest!
    
    var isGettingObjects: Bool = false
    
    var parseObjects = [PFObject]()
    var includedExchanges = [AnyObject]()
    var includedSectors = [AnyObject]()
    
    var charts = [Chart]()
    
    var numberOfCardsToQuery: Int = 25
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
    
    var halo: NVActivityIndicatorView!
    
    enum CardPosition: Int {
        case firstCard = 0
        case secondCard = 1
        case thirdCard = 2
        case fourthCard = 3
        
    }
    
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var reloadButton: UIBarButtonItem!
    
    @IBAction func reloadButtonPressed(_ sender: AnyObject) {
        
        guard !Functions.isConnectedToNetwork() && self.charts.count != 0 else {
            
            self.reloadCardViews()
            return
        }
        
        SweetAlert().showAlert("Reload?", subTitle: "Reloading with no internet will cause you to lose your loaded cards", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Cancel", buttonColor: UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: "Reload", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
            
            if !isOtherButton {
                
                self.reloadCardViews()
                
            }
        }
    }
    
    @IBAction func returnToMainviewController (_ segue:UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("CardsViewController loaded")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Get Parse Objects and Make Charts
        if self.charts.count <= 10 && !self.isGettingObjects {
            
            // Initial config
            self.options.delegate = self
            self.options.onPan = { state -> Void in
                
                if self.secondCardView != nil {
                    
                    let frame:CGRect = self.middleCardViewFrame()
                    self.secondCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-((state?.thresholdRatio)! * 10), width: frame.width, height: frame.height)
                }
                
                if self.thirdCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame()
                    self.thirdCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-((state?.thresholdRatio)! * 8), width: frame.width, height: frame.height)
                }
                
                if self.fourthCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame()
                    self.fourthCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-(state?.thresholdRatio)!, width: frame.width, height: frame.height)
                }
                
                if self.informationCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame()
                    self.informationCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-(state?.thresholdRatio)!, width: frame.width, height: frame.height)
                }
            }
            
            guard Functions.isConnectedToNetwork() else {
                self.reloadCardViews()
                return
            }
            
            Functions.setupConfigParameter("THRESHOLDX", completion: { (parameterValue) -> Void in
                
                if parameterValue != nil {
                    self.thresholdX = parameterValue as! CGFloat
                }
                
                self.options.threshold = (self.view.bounds.width / 2) * self.thresholdX
                print("threshold:",self.options.threshold)
                
                // GetObjects and make charts
                self.reloadCardViews()
            })
        }
    }
    
    func reloadCardViews() {
        
        // Disable all buttons
        //self.fadeInOutButton("Out")
        reloadFilterButtonsEnabled(false)
        //self.enableDisableButtons("Off")
        
        // Check and remove subviews
        self.removalAllCards()
        
        // Empty Data sources
        self.charts.removeAll()
        self.parseObjects.removeAll()
        
        // GetObjects and make charts
        do {
            
            try self.getObjectsAndMakeCharts()
            
        } catch  {
            
            if let error = error as? Constants.Errors {
                
                // Make information card
                self.makeCardWithInformation(error)
                
                // Enable short/long buttons
                //self.fadeInOutButton("In")
                self.reloadFilterButtonsEnabled(true)
            }
        }
    }
    
    func getObjectsAndMakeCharts() throws {
        
        guard Functions.isConnectedToNetwork() else {
            
            self.isGettingObjects = false
            
            throw Constants.Errors.noInternetConnection
        }
        
        // Setup filters from defaults
        setupFilters()
        
        guard !self.includedExchanges.isEmpty && !self.includedSectors.isEmpty else {
            
            self.isGettingObjects = false
            
            throw Constants.Errors.noExchangesOrSectorsSelected
        }
        
        // Mark fetching began
        self.isGettingObjects = true
        
        // Disable buttons and enable activity indicator
        self.reloadFilterButtonsEnabled(false)
        
        if firstCardView == nil {
            activityIndicator(state: true)
        }
        
        // Setup config parameters
        Functions.setupConfigParameter("NUMBEROFCARDSTOQUERY") { (parameterValue) -> Void in
            
            self.numberOfCardsToQuery = parameterValue as? Int ?? 25
            
            self.getObjects({ (result) -> Void in
                
                do {
                    
                    guard let results = try result() else { return }
                    self.parseObjects += results
                    
                    self.getCharts(results, completion: { (result) -> Void in
                        
                        do {
                            
                            try result()
                            
                            // Make 3 card stack
                            self.makeChartViews()
                            
                            // Enable short/long buttons
                            //self.fadeInOutButton("In")
                            self.reloadFilterButtonsEnabled(true)
                            
                        } catch {
                            
                            if let error = error as? Constants.Errors {
                                
                                // Make information card
                                self.makeCardWithInformation(error)
                                
                                // Enable short/long buttons
                                //self.fadeInOutButton("In")
                                self.reloadFilterButtonsEnabled(true)
                            }
                        }
                    })
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                    
                        // Make information card
                        self.makeCardWithInformation(error)
                        
                        // Enable short/long buttons
                        //self.fadeInOutButton("In")
                        self.reloadFilterButtonsEnabled(true)
                    }
                }
                
                self.isGettingObjects = false
            })
        }
    }
    
    // Mark - Get Symbols
    
    func getObjects(_ completion: @escaping (_ result: () throws -> [PFObject]?) -> Void) -> Void {
        
        PFCloud.callFunction(inBackground: "getRandomStockObjects", withParameters: ["numberOfCardsToQuery":numberOfCardsToQuery, "includedExchanges": includedExchanges, "includedSectors": includedSectors]) { (results, error) -> Void in
            
            guard error == nil else {
                return completion({throw Constants.Errors.errorAccessingParseDatabase})
            }
            
            guard results != nil else {
                return completion({throw Constants.Errors.ranOutOfChartCards})
            }
        
            let extraSetOfObjects = results as! [PFObject]
            
            // The find succeeded.
            print("Successfully retrieved \((results as AnyObject).count) objects")
            
            print("extraSetOfObjects count", extraSetOfObjects.count)
            
            completion({ return extraSetOfObjects })
        }
    }
    
    // Mark - Get Charts
    
    func getCharts(_ objects: [PFObject], completion: @escaping (_ result: () throws -> Bool) -> Void) -> Void {
        
        guard objects.count != 0  else {
           return completion({throw Constants.Errors.ranOutOfChartCards})
        }
        
        for object in objects {
            
            let chart = Chart(parseObject: object)
            
            chart.getChartImage(completion: { (image) in
                
                if let image = image {
                    chart.image = image
                    self.charts.append(chart)
                }
                
                if self.charts.count > 4 {
                    completion({ return true })
                }
            })
        }
    }
    
    func makeChartViews() {
        
        DispatchQueue.main.async {
            
            self.activityIndicator(state: false)
            
            // Display First Card
            if self.firstCardView == nil {
                
                self.firstCardView = self.popChartViewWithFrame(CardPosition.firstCard , frame: CGRect(x: self.view.bounds.width + self.frontCardViewFrame().width, y: self.navigationController!.navigationBar.frame.height + 50, width: chartWidth, height: chartHeight))
                
                if self.firstCardView != nil {
                    
                    self.view.addSubview(self.firstCardView)
                    
                    self.firstCardView.isUserInteractionEnabled = true
                    
                    self.firstCardView.transform = CGAffineTransform(rotationAngle: CGFloat(Functions.degreesToRadians(30)))
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                        
                        self.firstCardView.transform = CGAffineTransform(rotationAngle: CGFloat(Functions.degreesToRadians(0)))
                        
                        self.firstCardView.frame = self.frontCardViewFrame()
                        
                        }, completion: { (finished) -> Void in
                            
                            Functions.showPopTipOnceForKey("TAP_CARD_TIP_SHOWN", userDefaults: Constants.userDefaults,
                                                           popTipText: NSLocalizedString("Tap a card to view more details", comment: ""),
                                                           inView: self.view,
                                                           fromFrame: self.frontCardViewFrame(), direction: .up, color: Constants.stockSwipeGreenColor)
                            
                    })
                }
            }
            
            // Display Second Card
            if self.secondCardView == nil {
                
                self.secondCardView = self.popChartViewWithFrame(CardPosition.secondCard, frame: CGRect(x: 0 - self.frontCardViewFrame().width, y: self.frontCardViewFrame().origin.y + self.chartOffsetsY, width: self.frontCardViewFrame().width - (self.chartOffsetsX * 2), height: self.frontCardViewFrame().height))
                
                if self.secondCardView != nil {
                    
                    self.view.insertSubview(self.secondCardView, belowSubview: self.firstCardView)
                    self.secondCardView.isUserInteractionEnabled = false
                    
                    self.secondCardView.transform = CGAffineTransform(rotationAngle: CGFloat(Functions.degreesToRadians(-30)))
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                        
                        self.secondCardView.transform = CGAffineTransform(rotationAngle: CGFloat(Functions.degreesToRadians(0)))
                        
                        self.secondCardView.frame = self.middleCardViewFrame()
                        
                        }, completion: { (finished) -> Void in
                    })
                }
                
            }
            
            // Display Third Card
            if self.thirdCardView == nil {
                
                self.thirdCardView = self.popChartViewWithFrame(CardPosition.thirdCard, frame: CGRect(x: self.middleCardViewFrame().origin.x + self.chartOffsetsX, y: self.view.bounds.height + self.middleCardViewFrame().height, width: self.middleCardViewFrame().width - (self.chartOffsetsX * 2), height: self.middleCardViewFrame().height))
                
                if self.thirdCardView != nil {
                    
                    self.view.insertSubview(self.thirdCardView, belowSubview: self.secondCardView)
                    
                    self.thirdCardView.isUserInteractionEnabled = false
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
                        
                        self.thirdCardView.frame = self.backCardViewFrame()
                        
                        }, completion: { (finished) -> Void in
                            
                            if self.fourthCardView == nil  {
                                
                                self.fourthCardView = self.popChartViewWithFrame(CardPosition.fourthCard, frame: self.fourthCardViewFrame())
                                
                                if self.thirdCardView != nil && self.fourthCardView != nil {
                                    
                                    self.view.insertSubview(self.fourthCardView, belowSubview: self.thirdCardView)
                                    self.fourthCardView.isUserInteractionEnabled = false
                                }
                            }
                    })
                    
                }
            }
        }
    }
        
    func makeCardWithInformation(_ error: Constants.Errors) {
        
        DispatchQueue.main.async {
            
            self.activityIndicator(state: false)
            
            guard self.informationCardView == nil else { return }
            
            self.informationCardView = NoChartView(frame: self.backCardViewFrame(), text: error.message())
            
            self.view.addSubview(self.informationCardView)
            self.view.sendSubview(toBack: self.informationCardView)
            
            self.informationCardView.alpha = 0.0
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                
                self.informationCardView.alpha = 1.0
                
                //            // draw shadow
                //            self.informationCardView.layer.shadowOpacity = 0.5
                //            self.informationCardView.layer.shadowRadius = 5
                //            self.informationCardView.layer.shadowOffset = CGSizeMake(0, 10)
                //            self.informationCardView.layer.shadowPath = UIBezierPath(roundedRect: self.informationCardView.bounds, cornerRadius: 50).CGPath
                
                },completion: nil)
        }
    }
    
    func view(_ view: UIView!, shouldBeChosenWith direction: MDCSwipeDirection, yes: (() -> Void)!, no: (() -> Void)!) {
        
        if (direction == .left || direction == .right) {
            
            guard Functions.isUserLoggedIn(presenting: self) else { return no() }
            
            return yes()
            
        } else if direction == .up {
            
            return yes()
            
        } else {
            return no()
        }
    }
    
    // This is called when a user swipes the view in a direction.
    func view(_ view: UIView, wasChosenWith wasChosenWithDirection: MDCSwipeDirection) -> Void {
        
        guard let chartChosen: Chart = self.charts.find({$0.symbol == self.firstCardView.chart.symbol}) else { return }
       
        // Register choice
        if wasChosenWithDirection == MDCSwipeDirection.left {
            
            Functions.registerUserChoice(chartChosen, with: .SHORT)
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction":  Constants.UserChoices.SHORT.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
            
        } else if wasChosenWithDirection == MDCSwipeDirection.right {
            
            Functions.registerUserChoice(chartChosen, with: .LONG)
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction": Constants.UserChoices.LONG.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
            
        } else {
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction": Constants.UserChoices.SKIP.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
        }
        
        // Create NSUserActivity
        Functions.createNSUserActivity(chartChosen, domainIdentifier: "com.stockswipe.stocksSwiped")
        
        self.parseObjects.removeObject(chartChosen.parseObject!)
        self.charts.removeObject(chartChosen)
            
        // Swap and resize cards after each choice made
        self.swapAndResizeCardView(self.secondCardView)
        
        // make card views
        if self.fourthCardView == nil  {
            
            self.fourthCardView = self.popChartViewWithFrame(CardPosition.fourthCard, frame: self.fourthCardViewFrame())
            
            if self.thirdCardView != nil && self.fourthCardView != nil {
                
                self.view.insertSubview(self.fourthCardView, belowSubview: self.thirdCardView)
                self.fourthCardView.isUserInteractionEnabled = false
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
                    
                    // Enable short/long buttons
                    //self.fadeInOutButton("In")
                    self.reloadFilterButtonsEnabled(true)
                }
            }
        }
        
        //print("charts.count after swipe", self.charts.count)
    }
    
    // This is called when a user didn't fully swipe left or right.
    func viewDidCancelSwipe(_ view: UIView) -> Void {
        
        //print("You couldn't decide")
        
        if self.secondCardView != nil {
            
            let frame:CGRect = self.frontCardViewFrame()
            self.secondCardView.frame = CGRect(x: frame.origin.x + chartOffsetsX, y: frame.origin.y + chartOffsetsY, width: frame.width - (chartOffsetsX * 2), height: frame.height)
        }
        
        if self.thirdCardView != nil {
            
            let frame:CGRect = self.middleCardViewFrame()
            self.thirdCardView.frame = CGRect(x: frame.origin.x + chartOffsetsX, y: frame.origin.y + chartOffsetsY, width: frame.width - (chartOffsetsX * 2), height: frame.height)
        }
    }
    
    func viewDidGetTapped(_ view: UIView!) {
        
        print("View did get tapped")
        
        self.performCustomSegue(self)
    }
    
    func viewDidGetLongPressed(_ view: UIView!) {
        
        print("View did get long pressed")
        
        guard let chart: Chart = self.charts.find({ $0.symbol == self.firstCardView.chart.symbol }) else { return }
        
        Functions.addToWatchlist(chart, registerChoice: false) { (choice) in
            switch choice {
            case .LONG:
                self.longCardView()
            case .SHORT:
                self.shortCardView()
            case .SKIP:
                self.skipCardView()
            }
        }
    }
    
    func swapAndResizeCardView(_ CardView: SwipeChartView?) -> Void {
        
        // Keep track of the chart currently on top
        self.firstCardView = CardView
        self.secondCardView = self.thirdCardView
        self.thirdCardView = self.fourthCardView
        self.fourthCardView = nil
        
        if firstCardView != nil {
            
            self.firstCardView.isUserInteractionEnabled = true
            
        }
        
        self.resizeCardViews()
    }
    
    func popChartViewWithFrame(_ cardPosition: CardPosition, frame:CGRect) -> SwipeChartView? {
        
        if let chartAtIndex = self.charts.get(cardPosition.rawValue) {
            
            return SwipeChartView(frame: frame, chart: chartAtIndex, options: options)
            
        } else {
            
            return nil
        }
        
    }
    
    func frontCardViewFrame() -> CGRect {
        
        return CGRect(x: self.view.bounds.midX - (chartWidth / 2), y: self.view.bounds.midY - (chartHeight / 2) + verticalPadding, width: chartWidth, height: chartHeight)
        
    }
    
    func middleCardViewFrame() ->CGRect {
        
        let frontFrame:CGRect = frontCardViewFrame()
        return CGRect(x: frontFrame.origin.x + chartOffsetsX, y: frontFrame.origin.y + chartOffsetsY, width: frontFrame.width - (chartOffsetsX * 2), height: frontFrame.height)
        
    }
    
    func backCardViewFrame() ->CGRect {
        
        let middleFrame:CGRect = middleCardViewFrame()
        return CGRect(x: middleFrame.origin.x + chartOffsetsX, y: middleFrame.origin.y + chartOffsetsY, width: middleFrame.width - (chartOffsetsX * 2), height: middleFrame.height)
        
    }
    
    func fourthCardViewFrame() ->CGRect {
        
        let thirdFrame:CGRect = backCardViewFrame()
        return CGRect(x: thirdFrame.origin.x + chartOffsetsX, y: thirdFrame.origin.y, width: thirdFrame.width - (chartOffsetsX * 2), height: thirdFrame.height)
        
    }
    
    func shortCardView() {
        self.firstCardView.mdc_swipe(MDCSwipeDirection.left)
    }
    
    func longCardView() {
        self.firstCardView.mdc_swipe(MDCSwipeDirection.right)
    }
    
    func skipCardView() {
        self.firstCardView.mdc_swipe(MDCSwipeDirection.up)
    }
    
    func setupFilters() {
        
        includedExchanges = []
        includedSectors = []
        
        for exchange in Constants.Symbol.Exchange.allExchanges {
            
            guard Constants.userDefaults.bool(forKey: exchange.key()) == true else { continue }
            
            includedExchanges.append(exchange.key() as AnyObject)
        }
        
        for sector in Constants.Symbol.Sector.allSectors {
            
            guard Constants.userDefaults.bool(forKey: sector.key()) else { continue }
            
            includedSectors.append(sector.key().capitalized as AnyObject)
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
    
    func reloadFilterButtonsEnabled (_ state: Bool) {
        
        DispatchQueue.main.async {
            if state {
                self.reloadButton.isEnabled = true
                self.filterButton.isEnabled = true
            } else {
                self.reloadButton.isEnabled = false
                self.filterButton.isEnabled = false
            }
        }
    }
    
    func resizeCardViews() {
        
        DispatchQueue.main.async {
            
            // resize the middle card as it becomes top view.
            if self.firstCardView != nil {
                
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    
                    self.firstCardView.frame = self.frontCardViewFrame()
                    
                })
            }
            
            // resize the second as it becomes middle view.
            if self.secondCardView != nil {
                
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    
                    self.secondCardView.frame = self.middleCardViewFrame()
                })
                
            }
            
            // resize the back card as it becomes middle view.
            if self.thirdCardView != nil {
                
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    
                    self.thirdCardView.frame = self.backCardViewFrame()
                    //                self.thirdCardView.layer.shadowOpacity = 0.0
                })
                
            }
            
            // resize information card if it exits
            if self.informationCardView != nil {
                
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    
                    self.informationCardView.frame = self.backCardViewFrame()
                })
                
            }
        }
    }
    
    func removalAllCards() {
        
        DispatchQueue.main.async {
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
    }
    
    func activityIndicator(state: Bool) {
        
        var halo: NVActivityIndicatorView!
        
        if state {
            
            if halo != nil, halo.isDescendant(of: view) {
                halo.stopAnimating()
                halo.removeFromSuperview()
                halo = nil
            }
            
            if halo == nil {
                // Create loading animation
                let frame = CGRect(x: view.bounds.midX - view.bounds.height / 4 , y: view.bounds.midY - view.bounds.height / 4, width: view.bounds.height / 2, height: view.bounds.height / 2)
                halo = NVActivityIndicatorView(frame: frame, type: .ballScaleMultiple, color: UIColor.lightGray)
                view.addSubview(halo)
                halo.startAnimating()
            }
            
        } else {
            
            if halo != nil {
                halo.stopAnimating()
                halo.removeFromSuperview()
                halo = nil
            }
        }
    }
    
    // MARK: - Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showChartDetail" {
            
            guard let chart: Chart = self.charts.find({$0.symbol == self.firstCardView.chart.symbol}) else { return }
            
            let destinationView = segue.destination as! ChartDetailTabBarController
            destinationView.chart = chart
        }
    }
    
    func performCustomSegue(_ whoThat: AnyObject?) {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("Can't Access Chart!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
        self.performSegue(withIdentifier: "showChartDetail", sender: whoThat)
    }
    
    //    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
    //
    //        let segue = CustomUnwindSegue(identifier: identifier, source: fromViewController, destination: toViewController)
    //        return segue
    //
    //    }
}
