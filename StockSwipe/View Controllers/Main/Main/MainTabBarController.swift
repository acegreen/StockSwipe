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
import SKSplashView

protocol SplashAnimationDelegate {
    func didFinishLoading()
}

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
        
        if let alert = userInfo["alert"] as? [String: Any], let notificationTitle = alert["title"] as? String, let notificationBody = alert["body"] as? String {
            self.tabBar.items?[3].badgeValue = "1"
            Functions.showNotificationBanner(title: notificationTitle, subtitle: notificationBody, style: .info)
        }
    }
    
    func initializerSplash() {
        //Twitter style splash
        let stockswipeLaunchScreenLogoSize = UIImage(named: "stockswipe_logo")!.size
        let splashIcon: SKSplashIcon = SKSplashIcon(image: UIImage(named: "stockswipe_logo"), initialSize: stockswipeLaunchScreenLogoSize, animationType: .bounce)
        let backgroundColor: UIColor = Constants.SSColors.green
        self.splashView = SKSplashView(splashIcon: splashIcon, backgroundColor: backgroundColor, animationType: .none)
        //self.splashView.delegate = self
        self.splashView.tintColor = UIColor.white
        splashView.animationDuration = 0.50
        self.view.addSubview(splashView)
    }
    
    func didFinishLoading() {
        
        DispatchQueue.main.async {
            self.splashView.startAnimation {
                if PFUser.current() == nil && Constants.userDefaults.bool(forKey: "TUTORIAL_SHOWN") == false {
                    let logInViewcontroller = Constants.Storyboards.loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    self.present(logInViewcontroller, animated: true, completion: {
                        Constants.userDefaults.set(true, forKey: "TUTORIAL_SHOWN")
                    })
                } else {
                    SKStoreReviewController.requestReview()
                }
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MainTabBarController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .present
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = Constants.SSColors.gold
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        let center = self.view.center
        transition.startingPoint = center
        transition.bubbleColor = UIColor.white
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
