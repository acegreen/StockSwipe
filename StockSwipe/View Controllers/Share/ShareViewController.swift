//
//  ShareViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 6/8/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import Firebase
import Branch
import UICountingLabel

class ShareViewController: UIViewController {
    
    @IBAction func dismissAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var creditsLabel: UICountingLabel!
    
    @IBAction func inviteFriendsAction(_ sender: UIButton) {
        self.presentShareSheet()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        creditsLabel.format = "%d"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCreditBalance()
    }
    
    private func updateCreditBalance() {
        Branch.getInstance().loadRewards { (changed, error) in
            if (error == nil) {
                let credits = Branch.getInstance().getCredits()
                self.creditsLabel.countFromZero(to: CGFloat(credits))
            }
        }
    }
    
    private func presentShareSheet() {
        
        guard Functions.isConnectedToNetwork() else { return }
        
        let textToShare: String = "Checkout StockSwipe! Discover trade ideas and trending stocks"
        let objectsToShare: NSArray = [textToShare, Constants.branchURL!]
        
        let excludedActivityTypesArray = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.airDrop,
        ]
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare as [AnyObject], applicationActivities: nil)
        activityVC.excludedActivityTypes = excludedActivityTypesArray
        
        activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
        
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2,width: 0,height: 0)
        
        self.present(activityVC, animated: true, completion: nil)
        
        activityVC.completionWithItemsHandler = { (activity, success, items, error) in
            print("Activity: \(activity) Success: \(success) Items: \(items) Error: \(error)")
            
            if success {
                
                Functions.showNotificationBanner(title: "Success!", subtitle: nil, style: .success)
                
                // log shared successfully
                Analytics.logEvent(AnalyticsEventShare, parameters: [
                    AnalyticsParameterContent: "StockSwipe shared",
                    AnalyticsParameterContentType: "Share",
                    "user": PFUser.current()?.username ?? "N/A",
                    "app_version": Constants.AppVersion
                    ])
                
            } else if error != nil {
                Functions.showNotificationBanner(title: "Error!", subtitle: "That didn't go through", style: .danger)
            }
        }
    }
}
