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

class CardsViewController: UIViewController, MDCSwipeToChooseDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case FilterSegueIdentifier = "FilterSegueIdentifier"
    }
    
    var url: URL!
    var chartRequest:URLRequest!
    
    var isGettingObjects: Bool = false
    
    var parseObjects = [PFObject]()
    var includedExchanges = [AnyObject]()
    var includedSectors = [AnyObject]()
    
    var cards = [Card]()
    
    var numberOfCardsToQuery: Int = 25
    var numberofCardsInStack: Int = 3
    
    var firstCardView: SwipeCardView!
    var secondCardView: SwipeCardView!
    var thirdCardView: SwipeCardView!
    var fourthCardView: SwipeCardView!
    var informationCardView: UIView!
    
    var frontCardViewFrame: CGRect {
        return CGRect(x: self.view.bounds.midX - (cardWidth / 2), y: self.view.bounds.midY - (cardHeight / 2), width: cardWidth, height: cardHeight)
    }
    
    var middleCardViewFrame: CGRect {
        let frontFrame:CGRect = frontCardViewFrame
        return CGRect(x: frontFrame.origin.x + chartOffsetsX, y: frontFrame.origin.y + chartOffsetsY, width: frontFrame.width - (chartOffsetsX * 2), height: frontFrame.height)
    }
    
    var backCardViewFrame: CGRect {
        let middleFrame:CGRect = middleCardViewFrame
        return CGRect(x: middleFrame.origin.x + chartOffsetsX, y: middleFrame.origin.y + chartOffsetsY, width: middleFrame.width - (chartOffsetsX * 2), height: middleFrame.height)
        
    }
    
    var fourthCardViewFrame: CGRect {
        let thirdFrame:CGRect = backCardViewFrame
        return CGRect(x: thirdFrame.origin.x + chartOffsetsX, y: thirdFrame.origin.y, width: thirdFrame.width - (chartOffsetsX * 2), height: thirdFrame.height)
    }
    
    let chartOffsetsX: CGFloat = 10
    let chartOffsetsY: CGFloat = 10
    var thresholdX: CGFloat = 0.75
    
    let buttonCircleLineWidth: CGFloat = 2.0
    
    let options = MDCSwipeToChooseViewOptions()
    private var transition: CardTransition?
    
    lazy var halo: NVActivityIndicatorView! = {
        let frame = CGRect(x: self.view.bounds.midX - self.view.bounds.height / 4 , y: self.view.bounds.midY - self.view.bounds.height / 4, width: self.view.bounds.height / 2, height: self.view.bounds.height / 2)
        return NVActivityIndicatorView(frame: frame, type: .ballScaleMultiple, color: UIColor.lightGray)
    }()
    
    enum CardPosition: Int {
        case firstCard = 0
        case secondCard = 1
        case thirdCard = 2
        case fourthCard = 3
        
    }
    
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var reloadButton: UIBarButtonItem!
    
    @IBAction func reloadButtonPressed(_ sender: AnyObject) {
        
        guard !Functions.isConnectedToNetwork() && self.cards.count != 0 else {
            self.reloadCardViews()
            return
        }
        
        SweetAlert().showAlert("Reload?", subTitle: "Reloading with no internet will cause you to lose your loaded cards", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Cancel", buttonColor: UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: "Reload", otherButtonColor: Constants.SSColors.green) { (isOtherButton) -> Void in
            
            if !isOtherButton {
                self.reloadCardViews()
            }
        }
    }
    
    @IBAction func unwindToOverviewController (_ segue:UIStoryboardSegue) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register to listen to when AddToWatchlist happens
        NotificationCenter.default.addObserver(self, selector: #selector(CardsViewController.addCardToWatchlist), name: Notification.Name("AddToWatchlist"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // check device orientation
        Functions.setCardsSize()
        
        // Get Parse Objects and Make cards
        if self.cards.count <= 10 && !self.isGettingObjects {
            
            // Initial config
            self.options.delegate = self
            self.options.onPan = { state -> Void in
                
                if self.secondCardView != nil {
                    
                    let frame:CGRect = self.middleCardViewFrame
                    self.secondCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-((state?.thresholdRatio)! * 10), width: frame.width, height: frame.height)
                }
                
                if self.thirdCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame
                    self.thirdCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-((state?.thresholdRatio)! * 8), width: frame.width, height: frame.height)
                }
                
                if self.fourthCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame
                    self.fourthCardView.frame = CGRect(x: frame.origin.x, y: frame.origin.y-(state?.thresholdRatio)!, width: frame.width, height: frame.height)
                }
                
                if self.informationCardView != nil {
                    
                    let frame:CGRect = self.backCardViewFrame
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
                
                // GetObjects and make cards
                self.reloadCardViews()
            })
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        Functions.setCardsSize()
//        self.makeCardViews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reloadCardViews() {
        
        // Disable all buttons
        //self.fadeInOutButton("Out")
        reloadFilterButtonsEnabled(false)
        //self.enableDisableButtons("Off")
        
        // Check and remove subviews
        self.removalAllCards()
        
        // GetObjects and make cards
        do {
            try self.getObjectsAndMakeCards()
        } catch  {
            
            if let error = error as? QueryHelper.QueryError {
                
                // Make information card
                self.makeCardWithInformation(error)
                
                // Enable short/long buttons
                self.reloadFilterButtonsEnabled(true)
            }
        }
    }
    
    @objc func addCardToWatchlist(_ notification: Notification) {
        guard let userChoice = notification.userInfo?["userChoice"] as? Constants.UserChoices else { return }
            
        DispatchQueue.main.async {
            switch userChoice {
            case .LONG:
                self.longCardView()
            case .SHORT:
                self.shortCardView()
            case .SKIP:
                self.skipCardView()
            }
        }
    }
    
    func getObjectsAndMakeCards() throws {
        
        guard Functions.isConnectedToNetwork() else {
            self.isGettingObjects = false
            throw QueryHelper.QueryError.noInternetConnection
        }
        
        // Setup filters from defaults
        setupFilters()
        
        guard !self.includedExchanges.isEmpty && !self.includedSectors.isEmpty else {
            self.isGettingObjects = false
            throw QueryHelper.QueryError.noExchangesOrSectorsSelected
        }
        
        // Mark fetching began
        self.isGettingObjects = true
        
        // Disable buttons and enable activity indicator
        self.reloadFilterButtonsEnabled(false)
        
        if self.cards.count == 0 {
            activityIndicator(state: true)
        }
        
        // Setup config parameters
        Functions.setupConfigParameter("NUMBEROFCARDSTOQUERY") { (parameterValue) -> Void in
            
            self.numberOfCardsToQuery = parameterValue as? Int ?? 25
            
            self.getObjects({ (result) -> Void in
                
                do {
                    
                    guard let results = try result() else { return }
                    self.parseObjects += results
                    
                    self.makeChart(results, completion: { (result) -> Void in
                        
                        do {
                            
                            try result()
                            
                            // Make 3 card stack
                            self.makeCardViews()
                            
                            // Enable short/long buttons
                            //self.fadeInOutButton("In")
                            self.reloadFilterButtonsEnabled(true)
                            
                        } catch {
                            
                            if let error = error as? QueryHelper.QueryError {
                                
                                // Make information card
                                self.makeCardWithInformation(error)
                                
                                // Enable short/long buttons
                                //self.fadeInOutButton("In")
                                self.reloadFilterButtonsEnabled(true)
                            }
                        }
                    })
                    
                } catch {
                    
                    if let error = error as? QueryHelper.QueryError {
                    
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
                return completion({throw QueryHelper.QueryError.errorQueryingForData(error: error! )})
            }
            
            guard let results = results else {
                return completion({throw QueryHelper.QueryError.ranOutOfChartCards})
            }
        
            let extraSetOfObjects = results as! [PFObject]
            
            completion({ return extraSetOfObjects })
        }
    }
    
    // Mark - Get Charts
    
    func makeChart(_ objects: [PFObject], completion: @escaping (_ result: () throws -> Void) -> Void) -> Void {
        
        guard objects.count != 0  else {
           return completion({throw QueryHelper.QueryError.ranOutOfChartCards})
        }
        
        for object in objects {
            let symbol = object.object(forKey: "Symbol") as! String
            QueryHelper.sharedInstance.queryEODHistorical(for: symbol) { eodHistoricalResult in
                do {
                    let eodHistoricalResult = try eodHistoricalResult()

                    QueryHelper.sharedInstance.queryEODFundamentals(for: symbol, completionHandler: { eodFundamentalsResult in
                        
                        do {
                            let eodFundamentalsResult = try eodFundamentalsResult()
                            
                            if !eodHistoricalResult.isEmpty {
                                let card = Card(parseObject: object, eodHistoricalData: eodHistoricalResult, eodFundamentalsData: eodFundamentalsResult)
                                self.cards.append(card)
                            }
                            
                            if self.cards.count > self.numberofCardsInStack / 5 {
                                completion({ () })
                            }
                            
                        } catch {
                            // TODO: handle error
                        }
                    })
                    
                } catch {
                    // TODO: handle error
                }
            }
        }
    }
    
    func makeCardViews() {
        
        DispatchQueue.main.async {
            
            self.activityIndicator(state: false)
            
            // Display First Card
            if self.firstCardView == nil {
                
                self.firstCardView = self.popChartViewWithFrame(CardPosition.firstCard , frame: CGRect(x: self.view.bounds.width + self.frontCardViewFrame.width, y: self.navigationController!.navigationBar.frame.height + 50, width: cardWidth, height: cardHeight))
                
                if self.firstCardView != nil {
                    
                    self.view.addSubview(self.firstCardView)
                    self.firstCardView.isUserInteractionEnabled = true
                    self.firstCardView.transform = CGAffineTransform(rotationAngle: 30.toRadians())
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: { () -> Void in
                        
                        self.firstCardView.transform = CGAffineTransform(rotationAngle: 0.toRadians())
                        self.firstCardView.frame = self.frontCardViewFrame
                        
                        }, completion: { (finished) -> Void in
                            
                            Functions.showPopTipOnceForKey("TAP_CARD_TIP_SHOWN", userDefaults: Constants.userDefaults,
                                                           popTipText: NSLocalizedString("Tap a card to view more details", comment: ""),
                                                           inView: self.view,
                                                           fromFrame: self.frontCardViewFrame, direction: .up, color: Constants.SSColors.green)
                            
                    })
                }
            }
            
            // Display Second Card
            if self.secondCardView == nil {
                
                self.secondCardView = self.popChartViewWithFrame(CardPosition.secondCard, frame: CGRect(x: 0 - self.backCardViewFrame.width, y: self.backCardViewFrame.origin.y + self.chartOffsetsY, width: self.backCardViewFrame.width - (self.chartOffsetsX * 2), height: self.backCardViewFrame.height))
                
                if self.secondCardView != nil {
                    
                    self.view.insertSubview(self.secondCardView, belowSubview: self.firstCardView)
                    self.secondCardView.isUserInteractionEnabled = false
                    self.secondCardView.transform = CGAffineTransform(rotationAngle: -30.toRadians())
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: { () -> Void in
                        
                        self.secondCardView.transform = CGAffineTransform(rotationAngle: 0.toRadians())
                        self.secondCardView.frame = self.middleCardViewFrame
                        
                        }, completion: { (finished) -> Void in
                    })
                }
                
            }
            
            // Display Third Card
            if self.thirdCardView == nil {
                
                self.thirdCardView = self.popChartViewWithFrame(CardPosition.thirdCard, frame: CGRect(x: self.middleCardViewFrame.origin.x + self.chartOffsetsX, y: self.view.bounds.height + self.middleCardViewFrame.height, width: self.middleCardViewFrame.width - (self.chartOffsetsX * 2), height: self.middleCardViewFrame.height))
                
                if self.thirdCardView != nil {
                    
                    self.view.insertSubview(self.thirdCardView, belowSubview: self.secondCardView)
                    self.thirdCardView.isUserInteractionEnabled = false
                    
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: { () -> Void in
                        
                        self.thirdCardView.frame = self.backCardViewFrame
                        
                        }, completion: { (finished) -> Void in
                            
                            if self.fourthCardView == nil  {
                                
                                self.fourthCardView = self.popChartViewWithFrame(CardPosition.fourthCard, frame: self.fourthCardViewFrame)
                                
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
        
    func makeCardWithInformation(_ error: QueryHelper.QueryError) {
        
        DispatchQueue.main.async {
            
            self.activityIndicator(state: false)
            
            guard self.informationCardView == nil else { return }
            
            self.informationCardView = NoChartView(frame: self.backCardViewFrame, text: error.message())
            
            self.view.addSubview(self.informationCardView)
            self.view.sendSubviewToBack(self.informationCardView)
            
            self.informationCardView.alpha = 0.0
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                
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
        
        guard let chartChosen: Card = self.cards.find({ $0.symbol == self.firstCardView.card.symbol }) else { return }
       
        // Register choice
        if wasChosenWithDirection == MDCSwipeDirection.left {
            
            Functions.registerUserChoice(chartChosen, with: .SHORT)
            
            if Constants.swipeAddToWatchlist {
                Functions.saveIntoCoreData(chartChosen, userChoice: .SHORT)
            }
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction":  Constants.UserChoices.SHORT.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
            
        } else if wasChosenWithDirection == MDCSwipeDirection.right {
            
            Functions.registerUserChoice(chartChosen, with: .LONG)
            
            if Constants.swipeAddToWatchlist {
                Functions.saveIntoCoreData(chartChosen, userChoice: .LONG)
            }
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction": Constants.UserChoices.LONG.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
            
        } else {
            
            // log swipe
            Answers.logCustomEvent(withName: "Swipe", customAttributes: ["Direction": Constants.UserChoices.SKIP.rawValue, "User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
        }
        
        // Create NSUserActivity
        Functions.createNSUserActivity(chartChosen, domainIdentifier: "com.stockswipe.stocksSwiped")

        self.parseObjects.removeObject(chartChosen.parseObject!)
        self.cards.removeObject(chartChosen)
            
        // Swap and resize cards after each choice made
        self.swapAndResizeCardView(self.secondCardView)
        
        // make card views
        if self.fourthCardView == nil  {
            
            self.fourthCardView = self.popChartViewWithFrame(CardPosition.fourthCard, frame: self.fourthCardViewFrame)
            
            if self.thirdCardView != nil && self.fourthCardView != nil {
                
                self.view.insertSubview(self.fourthCardView, belowSubview: self.thirdCardView)
                self.fourthCardView.isUserInteractionEnabled = false
            }
        }
        
        if self.cards.count <= 10 && !self.isGettingObjects {
            
            do {
                try self.getObjectsAndMakeCards()
            } catch  {
                
                if let error = error as? QueryHelper.QueryError {
                    
                    // Make information card
                    self.makeCardWithInformation(error)
                    
                    // Enable short/long buttons
                    //self.fadeInOutButton("In")
                    self.reloadFilterButtonsEnabled(true)
                }
            }
        }
        
        //print("cards.count after swipe", self.cards.count)
    }
    
    // This is called when a user didn't fully swipe left or right.
    func viewDidCancelSwipe(_ view: UIView) -> Void {
        
        //print("You couldn't decide")
        
        if self.secondCardView != nil {
            
            let frame:CGRect = self.frontCardViewFrame
            self.secondCardView.frame = CGRect(x: frame.origin.x + chartOffsetsX, y: frame.origin.y + chartOffsetsY, width: frame.width - (chartOffsetsX * 2), height: frame.height)
        }
        
        if self.thirdCardView != nil {
            
            let frame:CGRect = self.middleCardViewFrame
            self.thirdCardView.frame = CGRect(x: frame.origin.x + chartOffsetsX, y: frame.origin.y + chartOffsetsY, width: frame.width - (chartOffsetsX * 2), height: frame.height)
        }
    }
    
    func viewDidGetTapped(_ view: UIView!) {
        self.performCustomSegue()
    }
    
    func viewDidGetLongPressed(_ view: UIView!) {
    }
    
    func swapAndResizeCardView(_ CardView: SwipeCardView?) -> Void {
        
        // Keep track of the card currently on top
        self.firstCardView = CardView
        self.secondCardView = self.thirdCardView
        self.thirdCardView = self.fourthCardView
        self.fourthCardView = nil
        
        if self.firstCardView != nil {
            self.firstCardView.isUserInteractionEnabled = true
        }

        
        self.resizeCardViews()
    }
    
    func popChartViewWithFrame(_ cardPosition: CardPosition, frame: CGRect) -> SwipeCardView? {
        if let cardAtIndex = self.cards.get(cardPosition.rawValue) {
            return SwipeCardView(frame: frame, card: cardAtIndex, options: options)
        } else {
            return nil
        }
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
                    self.firstCardView.frame = self.frontCardViewFrame
                })
            }
            
            // resize the second as it becomes middle view.
            if self.secondCardView != nil {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.secondCardView.frame = self.middleCardViewFrame
                })
            }
            
            // resize the back card as it becomes middle view.
            if self.thirdCardView != nil {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.thirdCardView.frame = self.backCardViewFrame
                    //                self.thirdCardView.layer.shadowOpacity = 0.0
                })
            }
            
            // resize information card if it exits
            if self.informationCardView != nil {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.informationCardView.frame = self.backCardViewFrame
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
        
        // Empty Data sources
        self.cards.removeAll()
        self.parseObjects.removeAll()
    }
    
    func activityIndicator(state: Bool) {
        if state {
            view.addSubview(halo)
            halo.startAnimating()
        } else {
            halo.stopAnimating()
            halo.removeFromSuperview()
        }
    }
    
    // MARK: - Segue
    
    func performCustomSegue() {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("Can't Access Card!", subTitle: "Make sure your device is connected\nto the internet", style: AlertStyle.warning)
            return
        }
        
                
        // Get current frame on screen
        let currentCellFrame = self.firstCardView.frame
        
        // Convert current frame to screen's coordinates
        let cardPresentationFrameOnScreen = self.firstCardView.superview!.convert(currentCellFrame, to: nil)
        
        // Get card frame without transform in screen's coordinates  (for the dismissing back later to original location)
        let cardFrameWithoutTransform = { () -> CGRect in
            let center = self.firstCardView.center
            let size = self.firstCardView.bounds.size
            let r = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return self.firstCardView.superview!.convert(r, to: nil)
        }()
        
        if let selectedCard = cards.find({ $0.symbol == self.firstCardView.card.symbol }) {
            
            // Set up card detail view controller
            let vc = Constants.Storyboards.cardDetailStoryboard.instantiateViewController(withIdentifier: "CardDetailViewController") as! CardDetailViewController
            vc.card = selectedCard
            vc.unhighlightedCard = selectedCard // Keep the original one to restore when dismiss
            let params = CardTransition.Params(fromCardFrame: cardPresentationFrameOnScreen,
                                               fromCardFrameWithoutTransform: cardFrameWithoutTransform,
                                               fromCell: self.firstCardView!)
            self.transition = CardTransition(params: params)
            vc.transitioningDelegate = self.transition
            
            // If `modalPresentationStyle` is not `.fullScreen`, this should be set to true to make status bar depends on presented vc.
            vc.modalPresentationCapturesStatusBarAppearance = true
            vc.modalPresentationStyle = .custom
            
            DispatchQueue.main.async {
                self.present(vc, animated: true, completion: {
                })
            }
        }
    }
    
    //    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue? {
    //
    //        let segue = CustomUnwindSegue(identifier: identifier, source: fromViewController, destination: toViewController)
    //        return segue
    //
    //    }
}
