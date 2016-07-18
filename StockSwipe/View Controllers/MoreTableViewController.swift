//
//  MoreTableViewController.swift
//
//
//  Created by Ace Green on 2015-06-26.
//
//

import UIKit
import MessageUI
import Crashlytics
import Parse

class MoreTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, SegueHandlerType, CellType, LoginDelegate {
    
    enum SegueIdentifier: String {
        
        case FAQSegueIdentifier = "FAQSegueIdentifier"
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
    }
    
    enum CellIdentifier: String {
        case ProfileCell = "ProfileCell"
        case FAQCell = "FAQCell"
        case TutorialCell = "TutorialCell"
        case WriteReviewCell = "WriteReviewCell"
        case GiveFeedbackCell =  "GiveFeedbackCell"
        case ShareCell = "ShareCell"
    }
    
    @IBOutlet var profileAvatarImage: UIImageView!
    @IBOutlet var profileLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        updateProfile()
    }
    
    func updateProfile() {
        
        guard PFUser.currentUser() != nil else {
            self.profileAvatarImage.image = UIImage(assetIdentifier: .UserDummyImage)
            self.profileLabel.text = "My Profile"
            return
        }
        
        guard let currentUser = PFUser.currentUser() where currentUser.authenticated else { return }
        
        if let profileImageURL = currentUser.objectForKey("profile_image_url") as? String {
            
            QueryHelper.sharedInstance.queryWith(profileImageURL, completionHandler: { (result) in
                
                do {
                    
                    let imageData = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let profileImage = UIImage(data: imageData)
                        self.profileAvatarImage.image = profileImage
                        
                        if let fullName = currentUser.objectForKey("full_name") as? String {
                            self.profileLabel.text = fullName
                        }
                    })
                    
                } catch {
                    
                }
                
            })
        }
    }
    
    func didLoginSuccessfully() {
        self.updateProfile()
    }
    
    func didLogoutSuccessfully() {
        self.updateProfile()
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.grayColor()
            view.textLabel!.font = Constants.stockSwipeFont
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let reuseIdentifier = reuseIdentifierForCell(tableView, indexPath: indexPath)
        
        switch reuseIdentifier {
            
        case .ProfileCell:
            
            guard Functions.isUserLoggedIn(self) else { return }
            
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: self)
            
        case .FAQCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
                return
            }
            
            self.performSegueWithIdentifier(.FAQSegueIdentifier, sender: self)
            
        case .TutorialCell:
            
            let logInViewcontroller = LoginViewController.sharedInstance
            self.showViewController(logInViewcontroller, sender: self)
            
        case .WriteReviewCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
                return
            }
            
            iRate.sharedInstance().openRatingsPageInAppStore()
            
        case .GiveFeedbackCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
                return
            }
            
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
            
        case .ShareCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
                return
            }
            
            let textToShare: String = "Checkout StockSwipe, it's like Tinder for stocks!"
            
            let objectsToShare: NSArray = [textToShare, Constants.appLinkURL!]
            
            let excludedActivityTypesArray: NSArray = [
                UIActivityTypePostToWeibo,
                UIActivityTypeAddToReadingList,
                UIActivityTypeAssignToContact,
                UIActivityTypePrint,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAssignToContact,
                UIActivityTypeAirDrop,
            ]
            
            let activityVC = UIActivityViewController(activityItems: objectsToShare as [AnyObject], applicationActivities: nil)
            activityVC.excludedActivityTypes = excludedActivityTypesArray as? [String]
            
            activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Unknown
            
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.width / 2, self.view.bounds.height / 2,0,0)
            
            self.presentViewController(activityVC, animated: true, completion: nil)
            
            activityVC.completionWithItemsHandler = { (activity, success, items, error) in
                print("Activity: \(activity) Success: \(success) Items: \(items) Error: \(error)")
                
                if success {
                    
                    SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.Success)
                    
                    // log shared successfully
                    Answers.logShareWithMethod("\(activity!)",
                        contentName: "StockSwipe shared",
                        contentType: "share",
                        contentId: nil,
                        customAttributes: ["App Version": Constants.AppVersion])
                    
                } else if error != nil {
                    
                    SweetAlert().showAlert("Error!", subTitle: "That didn't go through", style: AlertStyle.Error)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            let profileViewController = segue.destinationViewController as! ProfileContainerController
            profileViewController.user = User(userObject: PFUser.currentUser())
            
            // Just a workaround.. There should be a cleaner way to sort this out
            profileViewController.navigationItem.rightBarButtonItem = nil
            
        case .FAQSegueIdentifier:
            break
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
            
        case MFMailComposeResultCancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResultSaved.rawValue:
            
            print("Mail Saved")
            
        case MFMailComposeResultSent.rawValue:
            
            print("Mail Sent")
            
        case MFMailComposeResultFailed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func dismissSettings(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
