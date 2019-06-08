//
//  MoreTableViewController.swift
//
//
//  Created by Ace Green on 2015-06-26.
//
//

import UIKit
import MessageUI
import Firebase
import Parse
//import FBSDKShareKit

class MoreTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, SegueHandlerType, CellType {
    
    enum SegueIdentifier: String {
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
        case FAQSegueIdentifier = "FAQSegueIdentifier"
        case TutorialPageViewControllerSegueIdentifier = "TutorialPageViewControllerSegueIdentifier"
        case ShareSegueIdentifier = "ShareSegueIdentifier"
    }
    
    enum CellIdentifier: String {
        case ProfileCell = "ProfileCell"
        case FAQCell = "FAQCell"
        case TutorialCell = "TutorialCell"
        case PublicationCell = "PublicationCell"
        case WriteReviewCell = "WriteReviewCell"
        case GiveFeedbackCell =  "GiveFeedbackCell"
        case ShareCell = "ShareCell"
    }
    
    @IBOutlet var profileAvatarImage: UIImageView!
    @IBOutlet var profileLabel: UILabel!
    
    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateProfile { }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateProfile(completion: @escaping () -> Void) {
        
        guard let currentUser = User.current(), currentUser.isAuthenticated else {
            self.profileAvatarImage.image = UIImage(assetIdentifier: .UserDummyImage)
            self.profileLabel.text = "My Profile"
            return
        }
        
        self.currentUser = currentUser
        currentUser.fetchIfNeededInBackground() { (user, error) in
            guard let user = user as? User else { return }
            self.currentUser = user
            DispatchQueue.main.async {
                self.profileLabel.text = user.full_name
            }

            currentUser.getAvatar { (avatar) in
                DispatchQueue.main.async {
                    self.profileAvatarImage.image = avatar
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let reuseIdentifier = reuseIdentifierForCell(tableView, indexPath: indexPath)
        
        switch reuseIdentifier {
            
        case .ProfileCell:
            
            guard Functions.isUserLoggedIn(presenting: self) else { return }
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: self)
            
        case .FAQCell:
            
            guard Functions.isConnectedToNetwork() else { return }
            
            self.performSegueWithIdentifier(.FAQSegueIdentifier, sender: self)
            
        case .TutorialCell:
            
            self.performSegueWithIdentifier(.TutorialPageViewControllerSegueIdentifier, sender: self)

        case .PublicationCell:
            
            guard Functions.isConnectedToNetwork() else { return }
            
            Functions.presentSafariBrowser(with: Constants.publicationURL)
            
        case .WriteReviewCell:
            
            guard Functions.isConnectedToNetwork() else {
                return
            }
            
            UIApplication.shared.open(Constants.appReviewURL)
            
        case .GiveFeedbackCell:
            
            guard Functions.isConnectedToNetwork() else { return }
            
            if MFMailComposeViewController.canSendMail() {
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                
                mc.mailComposeDelegate = self
                mc.setSubject(Constants.emailTitle)
                mc.setMessageBody(Constants.messageBody, isHTML: true)
                mc.setToRecipients(Constants.toReceipients)
                
                self.present(mc, animated: true, completion: nil)
                
            } else {
                
                Functions.showNotificationBanner(title: "No email account found", subtitle: "Please add an email acount in your mail app", style: .warning)
                
            }
            
        case .ShareCell:
            self.performSegueWithIdentifier(.ShareSegueIdentifier, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
        case .ProfileSegueIdentifier:
            
            if let currentUser = PFUser.current() {
                
                let profileContainerController = segue.destination as! ProfileContainerController
                profileContainerController.loginDelegate = self
                profileContainerController.profileChangeDelegate = self
                profileContainerController.user = self.currentUser
            }
            
        case .FAQSegueIdentifier, .TutorialPageViewControllerSegueIdentifier, .ShareSegueIdentifier:
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

extension MoreTableViewController: LoginDelegate, ProfileDetailTableViewControllerDelegate {
    
    // MARK: - LoginDelegate & ProfileDetailTableViewControllerDelegate
    
    func didLoginSuccessfully() {
        self.updateProfile {
            self.performSegueWithIdentifier(.ProfileSegueIdentifier, sender: self)
        }
    }
    
    func didLogoutSuccessfully() {
        updateProfile { }
    }
    
    func userProfileChanged() {
        updateProfile { }
    }
}

//extension MoreTableViewController: FBSDKAppInviteDialogDelegate {
//
//    //MARK: FBSDKAppInviteDialogDelegate
//
//    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable: Any]!) {
//        print("invitation made")
//
//        // log shared successfully
//        Analytics.logEvent(AnalyticsEventShare, parameters: [
//            AnalyticsParameterContent: "Facebook Invite",
//            AnalyticsParameterContentType: "Share",
//            "user": PFUser.current()?.username ?? "N/A",
//            "app_version": Constants.AppVersion
//        ])
//
//    }
//
//    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
//        print("error made")
//    }
//
//    func presentFacebookInvite() {
//        let content = FBSDKAppInviteContent()
//        content.appLinkURL = Constants.facebookAppLink
//        //optionally set previewImageURL
//        //content.appInvitePreviewImageURL = NSURL(string: "https://www.mydomain.com/my_invite_image.jpg")!
//        // Present the dialog. Assumes self is a view controller
//        // which implements the protocol `FBSDKAppInviteDialogDelegate`.
//        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)
//    }
//}
