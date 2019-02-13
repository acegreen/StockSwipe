//
//  CardDetailViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/11/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit

class CardDetailViewController: StatusBarAnimatableViewController, UIScrollViewDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case CardDetailContainerViewControllerSegue = "CardDetailContainerViewControllerSegue"
    }
    
    // This constraint limits card content to not be covered by root view.
    // This is useful to make the card content expands when presenting,
    // as intially the card is fully contained in a smaller environment (card cell).
    // When animating detail view controller to be full-screen size, it should gradually expands along the bottom edge.
    //
    // ***But we dismiss disable this after presenting***
    @IBOutlet weak var cardBottomToRootBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var cardContentView: SwipeCardView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet var addToWatchlistButton: UIButton!
    @IBAction func addToWatchlistButtonPressed(_ sender: Any) {
        Functions.promptAddToWatchlist(card, registerChoice: true) { (choice) in }
    }
    
    @IBAction func xPressed(_ sender: UIButton) {
        
        if !forceDisableDragDownToDismiss {
            dismissalAnimator = createInteractiveDismissalAnimatorIfNeeded(targetAnimatedView: self.view,
                                                                           targetShrinkScale: 0.86,
                                                                           targetCornerRadius: Constants.cardCornerRadius,
                                                                           progress: 100)
            
            // Disable gesture until reverse closing animation finishes.
            dismissalAnimator!.addCompletion { [unowned self] (pos) in
                self.didCancelDismissalTransition()
                self.dismiss(animated: true, completion: nil)
            }
            dismissalAnimator!.startAnimation()
            
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
        sender.isHidden = true
    }
    
    var card: Card! {
        didSet {
            if self.view != nil {
                cardContentView.card = card
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
    var forceDisableDragDownToDismiss = false
    
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
        
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        
        if !forceDisableDragDownToDismiss {
            dismissalPanGesture.addTarget(self, action: #selector(handleDismissalPan(gesture:)))
            dismissalPanGesture.delegate = self
            //        dismissalScreenEdgePanGesture.addTarget(self, action: #selector(handleDismissalPan(gesture:)))
            //        dismissalScreenEdgePanGesture.delegate = self
            
            // Make drag down/scroll pan gesture waits til screen edge pan to fail first to begin
            dismissalPanGesture.require(toFail: dismissalScreenEdgePanGesture)
            //        scrollView.panGestureRecognizer.require(toFail: dismissalScreenEdgePanGesture)
        
            view.addGestureRecognizer(dismissalPanGesture)
            //        view.addGestureRecognizer(dismissalScreenEdgePanGesture)
        }
    
        loadViewIfNeeded()
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
    
    func createInteractiveDismissalAnimatorIfNeeded(targetAnimatedView: UIView, targetShrinkScale: CGFloat, targetCornerRadius: CGFloat, progress: CGFloat) -> UIViewPropertyAnimator {
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
        
        switch gesture.state {
        case .began:
            dismissalAnimator = createInteractiveDismissalAnimatorIfNeeded(targetAnimatedView: targetAnimatedView,
                                                                           targetShrinkScale: targetShrinkScale,
                                                                           targetCornerRadius: targetCornerRadius,
                                                                           progress: progress)
            
        case .changed:
            dismissalAnimator = createInteractiveDismissalAnimatorIfNeeded(targetAnimatedView: targetAnimatedView,
                                                                           targetShrinkScale: targetShrinkScale,
                                                                           targetCornerRadius: targetCornerRadius,
                                                                           progress: progress)
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
        if draggingDownToDismiss || (scrollView.isTracking && scrollView.contentOffset.y < 0 && !forceDisableDragDownToDismiss) {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .CardDetailContainerViewControllerSegue:
            let cardDetailFirstPageViewController = segue.destination as! CardDetailContainerPageViewController
            cardDetailFirstPageViewController.card = self.card
        }
    }
}

extension CardDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

