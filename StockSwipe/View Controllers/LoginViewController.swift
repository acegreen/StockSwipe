//
//  LoginViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-27.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import ParseTwitterUtils
import ParseFacebookUtilsV4
import LaunchKit
import ChimpKit
import SwiftyJSON

protocol LoginDelegate {
    func didLoginSuccessfully()
    func didLogoutSuccessfully()
}

class LoginViewController: UIViewController, UIPageViewControllerDataSource, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    static let sharedInstance = LoginViewController()
    
    var loginDelegate: LoginDelegate?
    
    var pageViewController: UIPageViewController!
    var pageImages: NSArray!
    
    var logInViewController: PFLogInViewController!
    var signUpViewController: PFSignUpViewController!
    
    @IBAction func logInButtonPressed(sender: AnyObject) {
        self.logIn(self)
    }
    
    @IBAction func notNowButtonPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func shouldAutorotate() -> Bool {
        
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageImages = NSArray(objects: "page1", "page2", "page3", "page4", "page5")
        self.pageViewController = Constants.storyboard.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        
        let startVC = self.viewControllerAtIndex(0) as PageContentViewController
        
        let viewControllers = NSArray(object: startVC)
        self.pageViewController.setViewControllers(viewControllers as! [PageContentViewController], direction: .Forward, animated: true, completion: nil)
        self.pageViewController.view.frame = CGRectMake(0, 30, self.view.frame.width, self.view.frame.size.height * 0.80)
        
        self.addChildViewController(self.pageViewController)
        
        self.view.addSubview(self.pageViewController.view)
        
        self.pageViewController.didMoveToParentViewController(self)
        
        if PFUser.currentUser() != nil {
            
            self.dismissViewControllerAnimated(false, completion: nil)
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark - UIPageViewController and delegate functions
    
    func viewControllerAtIndex(index: Int) -> PageContentViewController {
        
        if ((self.pageImages.count == 0) || (index >= self.pageImages.count)) {
            
            return PageContentViewController()
            
        }
        
        let vc: PageContentViewController = Constants.storyboard.instantiateViewControllerWithIdentifier("PageContentViewController") as! PageContentViewController
        
        vc.imageFile = self.pageImages[index] as! String
        vc.pageIndex = index
        
        return vc
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! PageContentViewController
        
        var index = vc.pageIndex as Int
        
        if (index == 0 || index == NSNotFound) {
            
            return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! PageContentViewController
        
        var index = vc.pageIndex as Int
        
        if (index == NSNotFound) {
            return nil
        }
        
        index += 1
        
        if (index == self.pageImages.count) {
            
            return nil
        }
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        
        return self.pageImages.count
        
    }
    
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        
        return 0
        
    }
    
    // Mark - Parse Login
    
    func logIn(viewController: UIViewController) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
            return
        }
        
        if PFUser.currentUser() == nil {
            
            self.logInViewController = PFLogInViewController()
            //self.signUpViewController = PFSignUpViewController()
            
            let logInLogoLabel: UILabel = UILabel()
            logInLogoLabel.text = "Log In"
            logInLogoLabel.textColor = Constants.stockSwipeFontColor
            logInLogoLabel.font = UIFont(name: "HelveticaNeue", size: 45.0)
            
            // PFLogInFields.UsernameAndPassword, PFLogInFields.LogInButton, PFLogInFields.SignUpButton, PFLogInFields.PasswordForgotten
            
            self.logInViewController.fields = [PFLogInFields.Twitter, PFLogInFields.Facebook, PFLogInFields.DismissButton]
            
            let facebookPermission = ["public_profile", "user_about_me", "user_website"]
            self.logInViewController.facebookPermissions = facebookPermission
            
            self.logInViewController.logInView?.logo = logInLogoLabel
            //            self.signUpViewController.signUpView?.logo = signUpLogoLabel
            
            self.logInViewController.delegate = self
            //            self.signUpViewController.delegate = self
            //            self.logInViewController.signUpController = self.signUpViewController
            
            viewController.presentViewController(self.logInViewController, animated: true, completion: nil)
            
        } else {
            
            LaunchKit.sharedInstance().setUserIdentifier(nil, email: nil, name: nil)
            SweetAlert().showAlert("No Action!", subTitle: "You are already Logged in", style: AlertStyle.None)
            
            viewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func logOut() {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
            return
        }
        
        guard PFUser.currentUser() != nil else { return }
        
        PFUser.logOutInBackgroundWithBlock { (error) in
            
            if error == nil {
                
                // register to LaunchKit
                LaunchKit.sharedInstance().setUserIdentifier(nil, email: nil, name: nil)
                
                SweetAlert().showAlert("Logged Out!", subTitle: "You are now logged out", style: AlertStyle.Success)
                
                self.loginDelegate?.didLogoutSuccessfully()
            }
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        
        guard Functions.isConnectedToNetwork() else {
            
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet.", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
            
            return false
        }
        
        if !username.isEmpty && !password.isEmpty {
            
            return true
            
        } else {
            
            SweetAlert().showAlert("Missing Information", subTitle: "Please enter both your username & password", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
            
            return false
            
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        if PFTwitterUtils.isLinkedWithUser(user) {
            
            let verify = NSURL(string: "https://api.twitter.com/1.1/account/verify_credentials.json?include_email=true&skip_status=true")
            let request = NSMutableURLRequest(URL: verify!)
            PFTwitterUtils.twitter()!.signRequest(request)
            var response: NSURLResponse?
            
            do {
                
                let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
                
                let result = JSON(data: data)
                
                print(result)
                
                var firstName: String?
                var lastName: String?
                
                if let twitterUsername = PFTwitterUtils.twitter()?.screenName {
                    user.username = twitterUsername
                    user["username_lowercase"] = user.username!.lowercaseString
                }
                
                if let twitterName = result["name"].string {
                    user["full_name"] = twitterName
                    
                    firstName = twitterName.componentsSeparatedByString(" ").first
                    lastName = twitterName.componentsSeparatedByString(" ").last
                    
                } else {
                    user["full_name"] = PFTwitterUtils.twitter()?.screenName
                }
                user["fullname_lowercase"] = user["full_name"].lowercaseString
                
                if let twitterEmail = result["email"].string {
                    user.email = twitterEmail
                }
                
//                if let twitterID = result["id_str"].string {
//                    user["twitter_id"] = twitterID
//                }
                
                if let location = result["location"].string {
                    user["location"] = location
                }
                
                if let profilePictureURL = result["profile_image_url_https"].URL?.absoluteString {
                    user["profile_image_url"] = profilePictureURL.stringByReplacingOccurrencesOfString("_normal", withString: "")
                }
                
                if let profileBannerURL = result["profile_banner_url"].URL?.absoluteString {
                    user["profile_banner_url"] = profileBannerURL
                }
                
                if let website = result["entities"]["url"]["urls"][0]["expanded_url"].URL?.absoluteString {
                    user["website"] = website
                }
                
                if let website_raw = result["url"].string {
                    user["website_raw"] = [website_raw]
                }
                
                if let bio = result["description"].string {
                    user["bio"] = bio
                }
                
                if let socialmedia_verified = result["verified"].bool {
                    user["socialmedia_verified"] = socialmedia_verified
                }
                
                user["follower_notification"] = true
                user["newTradeIdea_notification"] = true
                user["replyTradeIdea_notification"] = true
                user["likeTradeIdea_notification"] = true
                user["reshareTradeIdea_notification"] = true
                
                user.saveInBackgroundWithBlock({ (success, error) in
                    
                    if success {
                        
                        // register current installation
                        let currentInstallation = PFInstallation.currentInstallation()
                        currentInstallation["user"] = user
                        currentInstallation.saveInBackground()
                        
                        // register to LaunchKit
                        LaunchKit.sharedInstance().setUserIdentifier(user.objectId, email: user.email, name: user.username)
                        
                        // register to MailChimp
                        self.registerUserMailChimp("4266807125", firstName: firstName, lastName: lastName, username: user.username, email: user.email)
                        
                        // send delegate info
                        self.loginDelegate?.didLoginSuccessfully()
                        
                        //            if let authData = user.performSelector(Selector("authData")).takeUnretainedValue() {
                        //
                        //                print(authData["twitter"]!!["id"])
                        //
                        //            }
                        
                    }
                    
                    self.logInViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
                        
                        self.dismissViewControllerAnimated(true, completion: nil)
                        
                        SweetAlert().showAlert("Logged In!", subTitle: "You are now Logged in", style: AlertStyle.Success)
                    })
                })
                
            } catch let error as NSError {
                
                // failure
                print("Fetch failed: \(error.localizedDescription)")
            }
            
        } else if PFFacebookUtils.isLinkedWithUser(user) {
            
            // Get user email
            let accessToken = FBSDKAccessToken.currentAccessToken()
            
            if accessToken != nil {
                
                let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name,about,bio,location,picture.type(large),cover,website,verified"], tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
                
                req.startWithCompletionHandler({ (connection, object, error) in
                    
                    var firstName: String?
                    var lastName: String?
                    
                    if error == nil {
                        
                        let result = JSON(object)
                        
                        guard result != nil else { return }
                        
                        print(result)
                        
                        if let facebookNameFromName = result["name"].string {
                            
                            user.username = facebookNameFromName.stringByReplacingOccurrencesOfString(" ", withString: "")
                            user["username_lowercase"] = user.username!.lowercaseString
                            
                            user["full_name"] = facebookNameFromName
                            user["fullname_lowercase"] = user["full_name"].lowercaseString
                            
                            firstName = facebookNameFromName.componentsSeparatedByString(" ").first
                            lastName = facebookNameFromName.componentsSeparatedByString(" ").last
                            
                        } else if let facebookNameFromEmail = result["email"].string {
                            
                            user.username = facebookNameFromEmail.componentsSeparatedByString("@").first?.stringByReplacingOccurrencesOfString(" ", withString: "")
                            user["username_lowercase"] = user.username!.lowercaseString
                        }
                        
                        if let facebookEmail = result["email"].string {
                            user.email = facebookEmail
                        }
                        
//                        if let facebookID = result["id"].string {
//                            user["facebook_id"] = facebookID
//                        }
                        
                        if let location = result["location"]["name"].string {
                            user["location"] = location
                            user["location_id"] = result["location"]["id"].string
                        } 
                        
                        if let pictureURL = result["picture"]["data"]["url"].URL?.absoluteString {
                            user["profile_image_url"] = pictureURL
                        }
                        
                        if let profileBannerURL = result["cover"]["source"].URL?.absoluteString {
                            user["profile_banner_url"] = profileBannerURL
                        }
                        
                        if let website = result["website"].string {
                            user["website"] = website.componentsSeparatedByString("\n").first
                            user["website_raw"] = website.componentsSeparatedByString("\n")
                        }
                        
                        if let bio = result["bio"].string {
                            user["bio"] = bio
                        }
                        
                        if let socialmedia_verified = result["verified"].bool {
                            user["socialmedia_verified"] = socialmedia_verified
                        }
                        
                        user["follower_notification"] = true
                        user["newTradeIdea_notification"] = true
                        user["replyTradeIdea_notification"] = true
                        user["likeTradeIdea_notification"] = true
                        user["reshareTradeIdea_notification"] = true
                        
                        user.saveInBackgroundWithBlock({ (success, error) in
                            
                            if success {
                                // register current installation
                                let currentInstallation = PFInstallation.currentInstallation()
                                currentInstallation["user"] = user
                                currentInstallation.saveInBackground()
                                
                                // register to LaunchKit
                                LaunchKit.sharedInstance().setUserIdentifier(user.objectId, email: user.email, name: user.username)
                                
                                // register to MailChimp
                                self.registerUserMailChimp("4266807125", firstName: firstName, lastName: lastName, username: user.username, email: user.email)
                                
                                // send delegate info
                                self.loginDelegate?.didLoginSuccessfully()
                                
                            }
                            
                            self.logInViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
                                
                                self.dismissViewControllerAnimated(true, completion: nil)
                                
                                SweetAlert().showAlert("Logged In!", subTitle: "You are now Logged in", style: AlertStyle.Success)
                            })
                        })
                        
                    } else {
                        // failure
                        print("Fetch failed: \(error.localizedDescription)")
                    }
                })
            }
            
        } else {
            
            SweetAlert().showAlert("Email Verification Required", subTitle: "Please verify your email first using the email sent to you", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
            
            self.logOut()
        }
        
        //        else if user.valueForKey("emailVerified") as? Bool == true {
        //
        //            self.logInViewController.dismissViewControllerAnimated(true, completion: { () -> Void in
        //
        //                self.dismissViewControllerAnimated(false, completion: nil)
        //
        //            })
        //
        //        }
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        
        if !Functions.isConnectedToNetwork() {
            
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
            return
            
        } else if !ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter).accessGranted {
            
            SweetAlert().showAlert("No Authorization", subTitle: "Go to Settings -> Twitter -> Allow These Apps To Use Your Account -> StockSwipe", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Cancel", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: "Settings", otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    UIApplication.sharedApplication().openURL(Constants.settingsURL!)
                }
            }
            
        } else if !ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook).accessGranted {
            
            SweetAlert().showAlert("No Authorization", subTitle: "Go to Settings -> Facebook -> Allow These Apps To Use Your Account -> StockSwipe", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Cancel", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: "Settings", otherButtonColor: UIColor.colorFromRGB(0xAEDEF4)) { (isOtherButton) -> Void in
                
                if !isOtherButton {
                    
                    UIApplication.sharedApplication().openURL(Constants.settingsURL!)
                }
            }
            
        } else {
            
            SweetAlert().showAlert("Logged Failed!", subTitle: error?.localizedDescription, style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor.colorFromRGB(0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
        }
    }
    
    // Mark - Parse Signup
    
    //    func signUpViewController(signUpController: PFSignUpViewController, shouldBeginSignUp info: [NSObject : AnyObject]) -> Bool {
    //
    //        if Functions.isConnectedToNetwork() == false {
    //
    //            signUpController.presentViewController(Functions.displayAlert("No Internet Connection", message: "Make sure your device is connected to the internet", Action1: okAlertAction, Action2: nil), animated: true, completion: nil)
    //
    //            return false
    //
    //        } else {
    //
    //            var usernameField: String!
    //            var passwordField: String!
    //            var emailField: String!
    //
    //            for _ in info {
    //
    //                usernameField = info["username"] as? String
    //                passwordField = info["password"] as? String
    //                emailField = info["email"] as? String
    //            }
    //
    //            if usernameField?.isEmpty == true || passwordField?.isEmpty == true || emailField?.isEmpty == true {
    //
    //                signUpController.presentViewController(Functions.displayAlert("Missing Information", message: "Please fill in all the fields", Action1: okAlertAction, Action2: nil), animated: true, completion: nil)
    //
    //                return false
    //
    //            }
    //
    //            return true
    //        }
    //    }
    //
    //    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
    //
    //        let dismissAlertAction = UIAlertAction(title: "Ok", style: .Default, handler:{ (ACTION :UIAlertAction!) in
    //
    //            signUpController.dismissViewControllerAnimated(true, completion: nil)
    //
    //        })
    //
    //        signUpController.presentViewController(Functions.displayAlert("Sign Up Complete!", message: "We have sent you a verification email - you must verify your email to continue.", Action1: dismissAlertAction, Action2: nil), animated: true, completion: nil)
    //
    //    }
    //
    //    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
    //
    //        print("Failed to sign up")
    //
    //    }
    //
    //    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController) {
    //
    //        print("User dismissed sign up")
    //    }
    
    func registerUserMailChimp(listID: String, firstName:String?, lastName:String?, username: String?, email: String?) {
        
        guard username != nil else { return }
        guard email != nil else { return }
        
        let params:[NSObject : AnyObject] = ["id": listID, "email": ["email": email!], "merge_vars": ["FNAME": firstName ?? "", "LNAME": lastName ?? "","username": username!], "double_optin": false]
        ChimpKit.sharedKit().callApiMethod("lists/subscribe", withParams: params, andCompletionHandler: {(response, data, error) -> Void in
            if let httpResponse = response as? NSHTTPURLResponse {
                print("ChimpKit response:", httpResponse)
            }
        })
    }
    
}
