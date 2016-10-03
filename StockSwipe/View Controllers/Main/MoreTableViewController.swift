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
import FBSDKShareKit

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
        case InviteFacebookCell = "InviteFacebookCell"
        case ShareCell = "ShareCell"
    }
    
    @IBOutlet var profileAvatarImage: UIImageView!
    @IBOutlet var profileLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        updateProfile()
    }
    
    func updateProfile() {
        
        guard PFUser.current() != nil else {
            self.profileAvatarImage.image = UIImage(assetIdentifier: .UserDummyImage)
            self.profileLabel.text = "My Profile"
            return
        }
        
        guard let currentUser = PFUser.current() , currentUser.isAuthenticated else { return }
        
        if let profileImageURL = currentUser.object(forKey: "profile_image_url") as? String {
            
            QueryHelper.sharedInstance.queryWith(queryString: profileImageURL, completionHandler: { (result) in
                
                do {
                    
                    let imageData = try result()
                    
                    DispatchQueue.main.async {
                        let profileImage = UIImage(data: imageData)
                        self.profileAvatarImage.image = profileImage
                        
                        if let fullName = currentUser.object(forKey: "full_name") as? String {
                            self.profileLabel.text = fullName
                        }
                    }
                    
                } catch {
                    
                }
                
            })
        }
    }
    
    func presentFacebookInvite() {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = Constants.facebookAppLink as URL!
        //optionally set previewImageURL
        //content.appInvitePreviewImageURL = NSURL(string: "https://www.mydomain.com/my_invite_image.jpg")!
        // Present the dialog. Assumes self is a view controller
        // which implements the protocol `FBSDKAppInviteDialogDelegate`.
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
    }
    
    func didLoginSuccessfully() {
        self.updateProfile()
    }
    
    func didLogoutSuccessfully() {
        self.updateProfile()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let view = view as? UITableViewHeaderFooterView {
            
            view.textLabel!.textColor = UIColor.gray
            view.textLabel!.font = Constants.stockSwipeFont
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let reuseIdentifier = reuseIdentifierForCell(tableView, indexPath: indexPath)
        
        switch reuseIdentifier {
            
        case .ProfileCell:
            
            guard Functions.isUserLoggedIn(self) else { return }
            
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: self)
            
        case .FAQCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
                return
            }
            
            self.performSegueWithIdentifier(.FAQSegueIdentifier, sender: self)
            
        case .TutorialCell:
            
            let logInViewcontroller = LoginViewController.sharedInstance
            self.show(logInViewcontroller, sender: self)
            
        case .WriteReviewCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
                return
            }
            
            iRate.sharedInstance().openRatingsPageInAppStore()
            
        case .GiveFeedbackCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
                return
            }
            
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
            
        case .InviteFacebookCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
                return
            }
            
            presentFacebookInvite()
            
        case .ShareCell:
            
            guard Functions.isConnectedToNetwork() else {
                SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
                return
            }
            
            let textToShare: String = "Checkout StockSwipe, it's like Tinder for stocks!"
            
            let objectsToShare: NSArray = [textToShare, Constants.appLinkURL!]
            
            let excludedActivityTypesArray = [
                UIActivityType.postToWeibo,
                UIActivityType.addToReadingList,
                UIActivityType.assignToContact,
                UIActivityType.print,
                UIActivityType.saveToCameraRoll,
                UIActivityType.assignToContact,
                UIActivityType.airDrop,
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
                    
                    SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.success)
                    
                    // log shared successfully
                    Answers.logShare(withMethod: "\(activity!)",
                        contentName: "StockSwipe Shared",
                        contentType: "Share",
                        contentId: nil,
                        customAttributes: ["User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
                    
                } else if error != nil {
                    
                    SweetAlert().showAlert("Error!", subTitle: "That didn't go through", style: AlertStyle.error)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            if let currentUser = PFUser.current() {
                let profileViewController = segue.destination as! ProfileContainerController
                profileViewController.user = User(userObject: currentUser)
                
                // Just a workaround.. There should be a cleaner way to sort this out
                profileViewController.navigationItem.rightBarButtonItem = nil
            }
            
        case .FAQSegueIdentifier:
            break
        }
    }
    
    // MARK: - Email Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result.rawValue {
            
        case MFMailComposeResult.cancelled.rawValue:
            
            print("Mail Cancelled")
            
        case MFMailComposeResult.saved.rawValue:
            
            print("Mail Saved")
            
        case MFMailComposeResult.sent.rawValue:
            
            print("Mail Sent")
            
        case MFMailComposeResult.failed.rawValue:
            
            print("Mail Failed")
            
        default:
            
            return
            
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
}

extension MoreTableViewController: FBSDKAppInviteDialogDelegate {
    
    //MARK: FBSDKAppInviteDialogDelegate
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
        print("invitation made")
        
        // log shared successfully
        Answers.logShare(withMethod: "\("Facebook Invite")",
                                   contentName: "Facebook Invite Friends",
                                   contentType: "Share",
                                   contentId: nil,
                                   customAttributes: ["User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
        
    }
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        print("error made")
    }
}