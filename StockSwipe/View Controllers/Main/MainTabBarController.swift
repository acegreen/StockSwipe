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
        let navigationVC = self.viewControllers!.first as! UINavigationController
        let overviewVC = navigationVC.viewControllers.first as! OverviewViewController
        overviewVC.animationDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "FeedbackSegueIdentifier" {
            let controller = segue.destination
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .custom
        }
    }
    
    func didReceivePushNotification(_ userInfo: [AnyHashable: Any]) {
        
        // Handle received remote notification
        if let notificationTitle = userInfo["title"] as? String {
            if notificationTitle == "Follower Notification" || notificationTitle == "Trade Idea Reply Notification" || notificationTitle == "Trade Idea Like Notification" || notificationTitle == "Trade Idea Reshare Notification" {
                self.tabBar.items?[3].badgeValue = "1"
            }
        }
    }
    
    func initializerSplash() {
        //Twitter style splash
        let stockswipeLaunchScreenLogoSize = UIImage(named: "stockswipe_logo")!.size
        let splashIcon: SKSplashIcon = SKSplashIcon(image: UIImage(named: "stockswipe_logo"), initialSize: stockswipeLaunchScreenLogoSize, animationType: .bounce)
        let backgroundColor: UIColor = Constants.stockSwipeGreenColor
        self.splashView = SKSplashView(splashIcon: splashIcon, backgroundColor: backgroundColor, animationType: .none)
        //self.splashView.delegate = self
        splashView.animationDuration = 0.50
        self.view.addSubview(splashView)
    }
    
    func didFinishLoading() {
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.splashView.startAnimation {
                if PFUser.current() == nil && Constants.userDefaults.bool(forKey: "TUTORIAL_SHOWN") == false {
                    
                    let logInViewcontroller = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    self.present(logInViewcontroller, animated: true, completion: {
                        Constants.userDefaults.set(true, forKey: "TUTORIAL_SHOWN")
                    })
                    
                } else if SARate.sharedInstance().eventCount >= SARate.sharedInstance().eventsUntilPrompt && Constants.userDefaults.bool(forKey: "FEEDBACK_GIVEN") == false {
                    
                    self.performSegue(withIdentifier: "FeedbackSegueIdentifier", sender: self)
                    SARate.sharedInstance().eventCount = 0
                    
                } else {
                    
                    // Release notes on update
                    LaunchKit.sharedInstance().presentAppReleaseNotesIfNeeded(from: self, completion: { (didPresent) -> Void in
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
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = Constants.stockSwipeGoldColor
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = UIColor.whiteColor()
        return transition
    }
}

// MARK: - SKSplashView Delegates
extension MainTabBarController {
    
    func splashView(_ splashView: SKSplashView, didBeginAnimatingWithDuration duration: Float) {
    }
    
    func splashViewDidEndAnimating(_ splashView: SKSplashView) {
    }
}
