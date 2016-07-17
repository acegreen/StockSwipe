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
import SKSplashView

class MainTabBarController: UITabBarController, PushNotificationDelegate, SplashAnimationDelegate {
    
    let transition = BubbleTransition()
    var splashView: SKSplashView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add splash
        initializerSplash()
        
        // Become AppDelegate push delegate
        Constants.appDel.pushDelegate = self
        
        // Become OverviewViewcontroller AnimationDelegate
        let overviewVC = self.viewControllers!.first as! OverviewViewController
        overviewVC.animationDelegate = self
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
    
    func didReceivePushNotification(userInfo: [NSObject : AnyObject]) {
        
        // Handle received remote notification
        if let notificationTitle = userInfo["title"] as? String {
            if notificationTitle == "Follower Notification" || notificationTitle == "Trade Idea New Notification" || notificationTitle == "Trade Idea Reply Notification" || notificationTitle == "Trade Idea Like Notification" || notificationTitle == "Trade Idea Reshare Notification" {
                self.tabBar.items?[3].badgeValue = "1"
            }
        }
    }
    
    func initializerSplash() {
        //Twitter style splash
        let stockswipeLaunchScreenLogoSize = UIImage(named: "stockswipe_logo")!.size
        let splashIcon: SKSplashIcon = SKSplashIcon(image: UIImage(named: "stockswipe_logo_large"), initialSize: stockswipeLaunchScreenLogoSize, animationType: .Bounce)
        let backgroundColor: UIColor = Constants.stockSwipeGreenColor
        self.splashView = SKSplashView(splashIcon: splashIcon, backgroundColor: backgroundColor, animationType: .None)
        //self.splashView.delegate = self
        splashView.animationDuration = 0.50
        self.view.addSubview(splashView)
    }
    
    func didFinishLoading() {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.splashView.startAnimationWithCompletion {
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
        })
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

// MARK: - SKSplashView Delegates
extension MainTabBarController {
    
    func splashView(splashView: SKSplashView, didBeginAnimatingWithDuration duration: Float) {
    }
    
    func splashViewDidEndAnimating(splashView: SKSplashView) {
    }
}
