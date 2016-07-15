//
//  MainNavigationController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-12.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import LaunchKit
import BubbleTransition

protocol PushNotificationDelegate {
    func didReceivePushNotification(userInfo: [NSObject:AnyObject])
}

class MainTabBarController: UITabBarController, PushNotificationDelegate {
    
    let transition = BubbleTransition()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Become AppDelegate push delegate
        Constants.appDel.pushDelegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
        
        if PFUser.currentUser() == nil && Constants.userDefaults.boolForKey("TUTORIAL_SHOWN") == false {
            
            let logInViewcontroller = self.storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            self.presentViewController(logInViewcontroller, animated: true, completion: {
                Constants.userDefaults.setBool(true, forKey: "TUTORIAL_SHOWN")
            })
            
        } else if SARate.sharedInstance().eventCount >= SARate.sharedInstance().eventsUntilPrompt && Constants.userDefaults.boolForKey("FEEDBACK_GIVEN") == false {
            
            self.performSegueWithIdentifier("FeedbackSegueIdentifier", sender: self)
            SARate.sharedInstance().eventCount = 0
            
        } else {
            
            // Release notes on update
            LaunchKit.sharedInstance().presentAppReleaseNotesIfNeededFromViewController(self, completion: { (didPresent) -> Void in
                if didPresent {
                    print("Woohoo, we showed the release notes card!")
                }
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "FeedbackSegueIdentifier" {
            
            let controller = segue.destinationViewController
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .Custom
        }
    }
    
    func didReceivePushNotification(userInfo: [NSObject : AnyObject]) {
        
        // Handle received remote notification
        if let notificationTitle = userInfo["title"] as? String {
            if notificationTitle == "Follower Notification" || notificationTitle == "Trade Idea New Notification" || notificationTitle == "Trade Idea Reply Notification" || notificationTitle == "Trade Idea Like Notification" || notificationTitle == "Trade Idea Reshare Notification" {
                self.tabBar.items?[3].badgeValue = "1"
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = Constants.stockSwipeGoldColor
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
