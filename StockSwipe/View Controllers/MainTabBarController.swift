//
//  MainNavigationController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-12.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import BubbleTransition

class MainTabBarController: UITabBarController {
    
    let transition = BubbleTransition()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destinationViewController
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .Custom
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = UIColor.goldColor()
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = UIColor.whiteColor()
        return transition
    }
}
