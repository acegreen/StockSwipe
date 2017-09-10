//
//  FeedbackMainViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 9/10/17.
//  Copyright © 2017 StockSwipe. All rights reserved.
//

import UIKit
import StoreKit

class FeedbackMainViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func reviewAction() {
        self.dismiss(animated: true) {
            
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                Functions.markFeedbackGiven()
            } else {
                iRate.sharedInstance().openRatingsPageInAppStore()
            }
        }
    }
}
