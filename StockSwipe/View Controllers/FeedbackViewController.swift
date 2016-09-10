//
//  FeedbackViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-15.
//  Copyright (c) 2015 Ace Green. All rights reserved.
//

import UIKit
import MessageUI

class FeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var negativeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        negativeButton.layer.borderColor = UIColor.white.cgColor
    }
    
    @IBAction func reviewAction() {
        self.dismiss(animated: true) {
            iRate.sharedInstance().openRatingsPageInAppStore()
        }
    }
    
    @IBAction func negativeAction() {
        self.dismiss(animated: true) {}
    }

    @IBAction func contactAction() {

        if MFMailComposeViewController.canSendMail() {
            
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            mc.setSubject(Constants.emailTitle)
            mc.setMessageBody(Constants.messageBody, isHTML: true)
            mc.setToRecipients(Constants.toReceipients)
            
            self.present(mc, animated: true, completion: nil)
            
        } else {
            
            SweetAlert().showAlert("No email account found", subTitle: "Please add an email acount in your mail app", style: AlertStyle.warning)
            
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result.rawValue {
            
        case MFMailComposeResult.cancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResult.saved.rawValue, MFMailComposeResult.sent.rawValue:
        
            Functions.markFeedbackGiven()
            
        case MFMailComposeResult.failed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismiss(animated: true) { () -> Void in
            
            self.dismiss(animated: true, completion: nil)
            
        }
    }
}
