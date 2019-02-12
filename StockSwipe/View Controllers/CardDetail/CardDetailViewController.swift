//
//  CardDetailViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/11/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit

class CardDetailViewController: StatusBarAnimatableViewController, UIScrollViewDelegate {
    
    // This constraint limits card content to not be covered by root view.
    // This is useful to make the card content expands when presenting,
    // as intially the card is fully contained in a smaller environment (card cell).
    // When animating detail view controller to be full-screen size, it should gradually expands along the bottom edge.
    //
    // ***But we dismiss disable this after presenting***
    @IBOutlet weak var cardBottomToRootBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cardContentView: SwipeCardView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet var summaryLabel: UITextView!
    @IBOutlet var PELabel: UILabel!
    @IBOutlet var marketCapLabel: UILabel!
    @IBOutlet var EPSLabel: UILabel!
    @IBOutlet var bookValueLabel: UILabel!
    @IBOutlet var divYieldLabel: UILabel!
    @IBOutlet var earningsDateLabel: UILabel!
    @IBOutlet var EBITDALabel: UILabel!
    @IBOutlet var wallstreetTargetLabel: UILabel!
    
    @IBOutlet var fiftyTwoWeekRange: UILabel!
    @IBOutlet var fiftyMALabel: UILabel!
    @IBOutlet var twoHundredMALabel: UILabel!
    @IBOutlet var betaLabel: UILabel!
    @IBOutlet var shortRatioLabel: UILabel!
    
    @IBOutlet var sectorLabel: UILabel!
    @IBOutlet var industryLabel: UILabel!
    @IBOutlet var fulltimeEmployeesLabel: UILabel!
    @IBOutlet var exchangeLabel: UILabel!
    
    var card: Card! {
        didSet {
            if self.cardContentView != nil {
                cardContentView.card = card
                cardContentView.setCardInfo()
            }
        }
    }
    
    var unhighlightedCard: Card!
    
    var isFontStateHighlighted: Bool = true {
        didSet {
//            cardContentView.setFontState(isHighlighted: isFontStateHighlighted)
        }
    }
    
    var draggingDownToDismiss = false
    
    final class DismissalPanGesture: UIPanGestureRecognizer {}
    final class DismissalScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer {}
    
    private lazy var dismissalPanGesture: DismissalPanGesture = {
        let pan = DismissalPanGesture()
        pan.maximumNumberOfTouches = 1
        return pan
    }()
    
    private lazy var dismissalScreenEdgePanGesture: DismissalScreenEdgePanGesture = {
        let pan = DismissalScreenEdgePanGesture()
        pan.edges = .left
        return pan
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Constants.isEnabledDebugAnimatingViews {
            scrollView.layer.borderWidth = 3
            scrollView.layer.borderColor = UIColor.green.cgColor
            
            scrollView.subviews.first!.layer.borderWidth = 3
            scrollView.subviews.first!.layer.borderColor = UIColor.purple.cgColor
        }
        
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
//        cardContentView.setFontState(isHighlighted: isFontStateHighlighted)
        
        dismissalPanGesture.addTarget(self, action: #selector(handleDismissalPan(gesture:)))
        dismissalPanGesture.delegate = self
        dismissalScreenEdgePanGesture.addTarget(self, action: #selector(handleDismissalPan(gesture:)))
        dismissalScreenEdgePanGesture.delegate = self
        
        // Make drag down/scroll pan gesture waits til screen edge pan to fail first to begin
        dismissalPanGesture.require(toFail: dismissalScreenEdgePanGesture)
        scrollView.panGestureRecognizer.require(toFail: dismissalScreenEdgePanGesture)
        
        loadViewIfNeeded()
        view.addGestureRecognizer(dismissalPanGesture)
        view.addGestureRecognizer(dismissalScreenEdgePanGesture)
    
        cardContentView.card = card
        cardContentView.setCardInfo()
        self.loadInfo()
    }
    
    func loadInfo() {
        guard let eodFundamentalsData = card.eodFundamentalsData else { return }
        
        self.PELabel.text = eodFundamentalsData.highlights.peRatio ?? "--"
        self.marketCapLabel.text = (eodFundamentalsData.highlights.marketCapitalization != nil) ? eodFundamentalsData.highlights.marketCapitalization?.suffixNumber() : "--"
        self.EPSLabel.text = eodFundamentalsData.highlights.eps ?? "--"
        self.bookValueLabel.text = eodFundamentalsData.highlights.bookValue ?? "--"
        self.divYieldLabel.text =  eodFundamentalsData.highlights.dividendYield ?? "--"
        self.earningsDateLabel.text = eodFundamentalsData.highlights.mostRecentQuarter ?? "--"
        self.EBITDALabel.text = eodFundamentalsData.highlights.EBITDA != nil ? String(eodFundamentalsData.highlights.EBITDA!.suffixNumber()) : "--"
        self.wallstreetTargetLabel.text = eodFundamentalsData.highlights.wallStreetTargetPrice ?? "--"
        
        let fifyTwoWeekLow = eodFundamentalsData.technicals.fiftyTwoWeekLow ?? ""
        let fifyTwoWeekHigh = eodFundamentalsData.technicals.fiftyTwoWeekHigh ?? ""
        self.fiftyTwoWeekRange.text = fifyTwoWeekLow + " - " + fifyTwoWeekHigh
        self.fiftyMALabel.text = eodFundamentalsData.technicals.fiftyDayMA ?? "--"
        self.twoHundredMALabel.text = eodFundamentalsData.technicals.twoHundredDayMA ?? "--"
        self.betaLabel.text = eodFundamentalsData.technicals.beta ?? "--"
        self.shortRatioLabel.text = eodFundamentalsData.technicals.shortRatio ?? "--"
        
        self.sectorLabel.text = eodFundamentalsData.general.sector ?? "--"
        self.industryLabel.text = eodFundamentalsData.general.industry ?? "--"
        self.fulltimeEmployeesLabel.text = (eodFundamentalsData.general.fullTimeEmployees != nil) ? String(eodFundamentalsData.general.fullTimeEmployees!) : "--"
        self.exchangeLabel.text = eodFundamentalsData.general.exchange ?? "--"
        self.summaryLabel.text = eodFundamentalsData.general.description ?? "--"
    }
    
    func didSuccessfullyDragDownToDismiss() {
        card = unhighlightedCard
        dismiss(animated: true)
    }
    
    func userWillCancelDissmissalByDraggingToTop(velocityY: CGFloat) {}
    
    func didCancelDismissalTransition() {
        // Clean up
        interactiveStartingPoint = nil
        dismissalAnimator = nil
        draggingDownToDismiss = false
    }
    
    var interactiveStartingPoint: CGPoint?
    var dismissalAnimator: UIViewPropertyAnimator?
    
    // This handles both screen edge and dragdown pan. As screen edge pan is a subclass of pan gesture, this input param works.
    @objc func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        
        let isScreenEdgePan = gesture.isKind(of: DismissalScreenEdgePanGesture.self)
        let canStartDragDownToDismissPan = !isScreenEdgePan && !draggingDownToDismiss
        
        // Don't do anything when it's not in the drag down mode
        if canStartDragDownToDismissPan { return }
        
        let targetAnimatedView = gesture.view!
        let startingPoint: CGPoint
        
        if let p = interactiveStartingPoint {
            startingPoint = p
        } else {
            // Initial location
            startingPoint = gesture.location(in: nil)
            interactiveStartingPoint = startingPoint
        }
        
        let currentLocation = gesture.location(in: nil)
        let progress = isScreenEdgePan ? (gesture.translation(in: targetAnimatedView).x / 100) : (currentLocation.y - startingPoint.y) / 100
        let targetShrinkScale: CGFloat = 0.86
        let targetCornerRadius: CGFloat = Constants.cardCornerRadius
        
        func createInteractiveDismissalAnimatorIfNeeded() -> UIViewPropertyAnimator {
            if let animator = dismissalAnimator {
                return animator
            } else {
                let animator = UIViewPropertyAnimator(duration: 0, curve: .linear, animations: {
                    targetAnimatedView.transform = .init(scaleX: targetShrinkScale, y: targetShrinkScale)
                    targetAnimatedView.layer.cornerRadius = targetCornerRadius
                })
                animator.isReversed = false
                animator.pauseAnimation()
                animator.fractionComplete = progress
                return animator
            }
        }
        
        switch gesture.state {
        case .began:
            dismissalAnimator = createInteractiveDismissalAnimatorIfNeeded()
            
        case .changed:
            dismissalAnimator = createInteractiveDismissalAnimatorIfNeeded()
            
            let actualProgress = progress
            let isDismissalSuccess = actualProgress >= 1.0
            
            dismissalAnimator!.fractionComplete = actualProgress
            
            if isDismissalSuccess {
                dismissalAnimator!.stopAnimation(false)
                dismissalAnimator!.addCompletion { [unowned self] (pos) in
                    switch pos {
                    case .current:
                        self.didSuccessfullyDragDownToDismiss()
                    default:
                        fatalError("Must finish dismissal at end!")
                    }
                }
                dismissalAnimator!.finishAnimation(at: .current)
            }
            
        case .ended, .cancelled:
            if dismissalAnimator == nil {
                // Gesture's too quick that it doesn't have dismissalAnimator!
                print("Too quick there's no animator!")
                didCancelDismissalTransition()
                return
            }
            // NOTE:
            // If user lift fingers -> ended
            // If gesture.isEnabled -> cancelled
            
            // Ended, Animate back to start
            dismissalAnimator!.pauseAnimation()
            dismissalAnimator!.isReversed = true
            
            // Disable gesture until reverse closing animation finishes.
            gesture.isEnabled = false
            dismissalAnimator!.addCompletion { [unowned self] (pos) in
                self.didCancelDismissalTransition()
                gesture.isEnabled = true
            }
            dismissalAnimator!.startAnimation()
        default:
            fatalError("Impossible gesture state? \(gesture.state.rawValue)")
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollView.scrollIndicatorInsets = .init(top: cardContentView.bounds.height, left: 0, bottom: 0, right: 0)
        if Constants.isEnabledTopSafeAreaInsetsFixOnCardDetailViewController {
            self.additionalSafeAreaInsets = .init(top: max(-view.safeAreaInsets.top,0), left: 0, bottom: 0, right: 0)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if draggingDownToDismiss || (scrollView.isTracking && scrollView.contentOffset.y < 0) {
            draggingDownToDismiss = true
            scrollView.contentOffset = .zero
        }
        
        scrollView.showsVerticalScrollIndicator = !draggingDownToDismiss
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Without this, when user drag down and lift the finger fast at the top, there'll be some scrolling going on.
        // This check prevents that.
        if velocity.y > 0 && scrollView.contentOffset.y <= 0 {
            scrollView.contentOffset = .zero
        }
    }
    
    override var statusBarAnimatableConfig: StatusBarAnimatableConfig {
        return StatusBarAnimatableConfig(prefersHidden: true,
                                         animation: .slide)
    }
}

extension CardDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

