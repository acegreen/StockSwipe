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

        negativeButton.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    @IBAction func reviewAction() {
        self.dismissViewControllerAnimated(true) {
            iRate.sharedInstance().openRatingsPageInAppStore()
        }
    }
    
    @IBAction func negativeAction() {
        self.dismissViewControllerAnimated(true) {}
    }

    @IBAction func contactAction() {

        if MFMailComposeViewController.canSendMail() {
            
            let mc: MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            mc.setSubject(Constants.emailTitle)
            mc.setMessageBody(Constants.messageBody, isHTML: true)
            mc.setToRecipients(Constants.toReceipients)
            
            self.presentViewController(mc, animated: true, completion: nil)
            
        } else {
            
            SweetAlert().showAlert("No email account found", subTitle: "Please add an email acount in your mail app", style: AlertStyle.Warning)
            
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResultCancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResultSaved.rawValue, MFMailComposeResultSent.rawValue:
        
            Functions.markFeedbackGiven()
            
        case MFMailComposeResultFailed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
    }
}
