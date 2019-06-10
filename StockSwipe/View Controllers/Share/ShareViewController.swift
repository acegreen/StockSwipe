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
                DispatchQueue.main.async {
                    self.creditsLabel.countFromZero(to: CGFloat(credits))
                }
            }
        }
    }
    
    private func presentShareSheet() {
        
        guard Functions.isConnectedToNetwork() else { return }
        
        let textToShare: String = "Checkout StockSwipe! Discover trade ideas and trending stocks"
        let branchObject = BranchUniversalObject(title: "StockSwipe")
        branchObject.contentDescription = "StockSwipe lets you discover new stocks by swiping through cards. join traders who swiped and found some awesome trades #StockSwipe"
        branchObject.imageUrl = "https://www.dropbox.com/s/4v79q81wbddgm8j/Icon_512.png"
        branchObject.publiclyIndex = true
        branchObject.locallyIndex = true
        
        branchObject.showShareSheet(withShareText: textToShare) { (activityType, completed) in
            if completed {
                Functions.showNotificationBanner(title: "Success!", subtitle: nil, style: .success)
            }
        }
    }
}
