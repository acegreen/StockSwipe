//
//  BubbleTransition.swift
//  BubbleTransition
//
//  Created by Andrea Mazzini on 04/04/15.
//  Copyright (c) 2015 Fancy Pixel. All rights reserved.
//

import UIKit

/**
 A custom modal transition that presents and dismiss a controller with an expanding bubble effect.

 - Prepare the transition:
 ```swift
 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     let controller = segue.destinationViewController
     controller.transitioningDelegate = self
     controller.modalPresentationStyle = .Custom
 }
 ```
 - Implement UIViewControllerTransitioningDelegate:
 ```swift
 func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
     transition.transitionMode = .Present
     transition.startingPoint = someButton.center
     transition.bubbleColor = someButton.backgroundColor!
     return transition
 }

 func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
     transition.transitionMode = .Dismiss
     transition.startingPoint = someButton.center
     transition.bubbleColor = someButton.backgroundColor!
     return transition
 }
 ```
 */
public class BubbleTransition: NSObject {
    
    /**
    The point that originates the bubble. The bubble starts from this point
    and shrinks to it on dismiss
    */
    public var startingPoint = CGPoint.zero {
        didSet {
            bubble.center = startingPoint
        }
    }
    
    /**
    The transition duration. The same value is used in both the Present or Dismiss actions
    Defaults to `0.5`
    */
    public var duration = 0.5
    
    /**
    The transition direction. Possible values `.Present`, `.Dismiss` or `.Pop`
     Defaults to `.Present`
    */
    public var transitionMode: BubbleTransitionMode = .Present
    
    /**
    The color of the bubble. Make sure that it matches the destination controller's background color.
    */
    public var bubbleColor: UIColor = .white
    
    public fileprivate(set) var bubble = UIView()

    /**
    The possible directions of the transition.
     
     - Present: For presenting a new modal controller
     - Dismiss: For dismissing the current controller
     - Pop: For a pop animation in a navigation controller
    */
    @objc public enum BubbleTransitionMode: Int {
        case Present, Dismiss, Pop
    }
}

extension BubbleTransition: UIViewControllerAnimatedTransitioning {

    // MARK: - UIViewControllerAnimatedTransitioning

    /**
    Required by UIViewControllerAnimatedTransitioning
    */
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    /**
     Required by UIViewControllerAnimatedTransitioning
     */
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView

        if transitionMode == .Present {
            let presentedControllerView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
            let originalCenter = presentedControllerView.center
            let originalSize = presentedControllerView.frame.size

            bubble = UIView()
            bubble.frame = frameForBubble(originalCenter: originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = startingPoint
            bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            bubble.backgroundColor = bubbleColor
            containerView.addSubview(bubble)

            presentedControllerView.center = startingPoint
            presentedControllerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            presentedControllerView.alpha = 0
            containerView.addSubview(presentedControllerView)

            UIView.animate(withDuration: duration, animations: {
                self.bubble.transform = CGAffineTransform.identity
                presentedControllerView.transform = CGAffineTransform.identity
                presentedControllerView.alpha = 1
                presentedControllerView.center = originalCenter
                }) { (_) in
                    transitionContext.completeTransition(true)
            }
        } else {
            let key = (transitionMode == .Pop) ? UITransitionContextViewKey.to : UITransitionContextViewKey.from
            let returningControllerView = transitionContext.view(forKey: key)!
            let originalCenter = returningControllerView.center
            let originalSize = returningControllerView.frame.size

            bubble.frame = frameForBubble(originalCenter: originalCenter, size: originalSize, start: startingPoint)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = startingPoint

            UIView.animate(withDuration: duration, animations: {
                self.bubble.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                returningControllerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                returningControllerView.center = self.startingPoint
                returningControllerView.alpha = 0

                if self.transitionMode == .Pop {
                    containerView.insertSubview(returningControllerView, belowSubview: returningControllerView)
                    containerView.insertSubview(self.bubble, belowSubview: returningControllerView)
                }
                }) { (_) in
                    returningControllerView.center = originalCenter;
                    returningControllerView.removeFromSuperview()
                    self.bubble.removeFromSuperview()
                    transitionContext.completeTransition(true)
            }
        }
    }
}

fileprivate extension BubbleTransition {
    fileprivate func frameForBubble(originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)

        return CGRect(origin: CGPoint.zero, size: size)
    }
}
