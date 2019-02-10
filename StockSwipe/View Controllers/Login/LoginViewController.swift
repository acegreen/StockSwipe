//
//  LoginViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-27.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import Parse
import Crashlytics
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
    
    @IBAction func logInButtonPressed(_ sender: AnyObject) {
        self.logIn(self)
    }
    
    @IBAction func notNowButtonPressed(_ sender: AnyObject) {
        
        self.dismiss(animated: false, completion: nil)
    }
    
    override var shouldAutorotate : Bool {
        
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageImages = NSArray(objects: "page1", "page2", "page3", "page4", "page5")
        self.pageViewController = Constants.Storyboards.loginStoryboard.instantiateViewController(withIdentifier: "PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        
        let startVC = self.viewControllerAtIndex(0) as PageContentViewController
        
        let viewControllers = NSArray(object: startVC)
        self.pageViewController.setViewControllers(viewControllers as! [PageContentViewController], direction: .forward, animated: true, completion: nil)
        self.pageViewController.view.frame = CGRect(x: 0, y: 30, width: self.view.frame.width, height: self.view.frame.size.height * 0.80)
        
        self.addChild(self.pageViewController)
        
        self.view.addSubview(self.pageViewController.view)
        
        self.pageViewController.didMove(toParent: self)
        
        if PFUser.current() != nil {
            
            self.dismiss(animated: false, completion: nil)
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark - UIPageViewController and delegate functions
    
    func viewControllerAtIndex(_ index: Int) -> PageContentViewController {
        
        if ((self.pageImages.count == 0) || (index >= self.pageImages.count)) {
            return PageContentViewController()
        }
        
        let vc: PageContentViewController = Constants.Storyboards.loginStoryboard.instantiateViewController(withIdentifier: "PageContentViewController") as! PageContentViewController
        
        vc.imageFile = self.pageImages[index] as? String
        vc.pageIndex = index
        
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! PageContentViewController
        
        var index = vc.pageIndex as Int
        
        if (index == 0 || index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
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
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pageImages.count
    }
    
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0        
    }
    
    // Mark - Parse Login
    
    func logIn(_ viewController: UIViewController) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
            return
        }
        
        if PFUser.current() == nil {
            
            self.logInViewController = PFLogInViewController()
            self.signUpViewController = PFSignUpViewController()
            
            let logInLogoLabel: UILabel = UILabel()
            logInLogoLabel.text = "Log In"
            logInLogoLabel.textColor = Constants.SSColors.grey
            logInLogoLabel.font = Constants.SSFonts.xl
            
            let signUpLogoLabel: UILabel = UILabel()
            signUpLogoLabel.text = "Sign Up"
            signUpLogoLabel.textColor = Constants.SSColors.grey
            signUpLogoLabel.font = Constants.SSFonts.xl
            
            // PFLogInFields.passwordForgotten
            self.logInViewController.fields = [PFLogInFields.usernameAndPassword, PFLogInFields.logInButton, PFLogInFields.signUpButton, PFLogInFields.twitter, PFLogInFields.facebook, PFLogInFields.dismissButton]
            
            let facebookPermission = ["public_profile", "email"]
            self.logInViewController.facebookPermissions = facebookPermission
            
            self.logInViewController.logInView?.logo = logInLogoLabel
            self.signUpViewController.signUpView?.logo = signUpLogoLabel
            
            self.logInViewController.delegate = self
            self.signUpViewController.delegate = self
            self.logInViewController.signUpController = self.signUpViewController
            
            viewController.present(self.logInViewController, animated: true, completion: nil)
            
        } else {
            
            LaunchKit.sharedInstance().setUserIdentifier(nil, email: nil, name: nil)
            SweetAlert().showAlert("No Action!", subTitle: "You are already Logged in", style: AlertStyle.none)
            
            viewController.dismiss(animated: false, completion: nil)
        }
    }
    
    func logOut() {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
            return
        }
        
        guard PFUser.current() != nil else { return }
        
        PFUser.logOutInBackground { (error) in
            
            if error == nil {
                // register to LaunchKit
                LaunchKit.sharedInstance().setUserIdentifier(nil, email: nil, name: nil)
                SweetAlert().showAlert("Logged Out!", subTitle: "You are now logged out", style: AlertStyle.success)
                
                self.loginDelegate?.didLogoutSuccessfully()
            }
        }
    }
    
    func log(_ logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet.", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            return false
        }
        
        if !username.isEmpty && !password.isEmpty {
            return true
        } else {
            SweetAlert().showAlert("Missing Information", subTitle: "Please enter both your username & password", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
            }
            
            return false
            
        }
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        
        if PFTwitterUtils.isLinked(with: user) {
            
            let verify = URL(string: "https://api.twitter.com/1.1/account/verify_credentials.json?include_email=true&skip_status=true")
            let request = NSMutableURLRequest(url: verify!)
            PFTwitterUtils.twitter()!.sign(request)
            var response: URLResponse?
            
            do {
                
                let data = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
                let result = try JSON(data: data)
                
                var firstName: String?
                var lastName: String?
                
                if let twitterUsername = PFTwitterUtils.twitter()?.screenName {
                    user.username = twitterUsername
                    user["username_lowercase"] = user.username!.lowercased()
                }
                
                if let twitterName = result["name"].string {
                    user["full_name"] = twitterName
                    
                    firstName = twitterName.components(separatedBy: " ").first
                    lastName = twitterName.components(separatedBy: " ").last
                    
                } else {
                    user["full_name"] = PFTwitterUtils.twitter()?.screenName
                }
                user["fullname_lowercase"] = (user["full_name"] as AnyObject).lowercased
                
                if let twitterEmail = result["email"].string {
                    user.email = twitterEmail
                }
                
                //                if let twitterID = result["id_str"].string {
                //                    user["twitter_id"] = twitterID
                //                }
                
                if let location = result["location"].string {
                    user["location"] = location
                }
                
                if let profilePictureURL = result["profile_image_url_https"].url?.absoluteString {
                    user["profile_image_url"] = profilePictureURL.replacingOccurrences(of: "_normal", with: "")
                }
                
                if let profileBannerURL = result["profile_banner_url"].url?.absoluteString {
                    user["profile_banner_url"] = profileBannerURL
                }
                
                if let website = result["entities"]["url"]["urls"][0]["expanded_url"].url?.absoluteString {
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
                user["mention_notification"] = true
                user["newTradeIdea_notification"] = true
                user["replyTradeIdea_notification"] = true
                user["likeTradeIdea_notification"] = true
                user["reshareTradeIdea_notification"] = true
                user["swipe_addToWatchlist"] = false
                
                self.saveUser(user, firstName: firstName, lastName: lastName)
                
            } catch let error as NSError {
                
                // failure
                print("Fetch failed: \(error.localizedDescription)")
            }
            
        } else if PFFacebookUtils.isLinked(with: user) {
            
            // Get user email
            if let accessToken = FBSDKAccessToken.current() {
                
                let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,id,name,first_name,last_name,picture,verified"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET")
                
                req?.start(completionHandler: { (connection, object, error) in
                    
                    do {
                        
                        var firstName: String?
                        var lastName: String?
                        
                        if error == nil {
                            
                            let result = try JSON(object)
                            guard result != nil else { return }
                            
                            print(result)
                            
                            if let facebookNameFromName = result["name"].string {
                                
                                user.username = facebookNameFromName.replacingOccurrences(of: " ", with: "")
                                user["username_lowercase"] = user.username!.lowercased()
                                
                                user["full_name"] = facebookNameFromName
                                user["fullname_lowercase"] = (user["full_name"] as AnyObject).lowercased
                                
                                firstName = facebookNameFromName.components(separatedBy: " ").first
                                lastName = facebookNameFromName.components(separatedBy: " ").last
                                
                            } else if let facebookNameFromEmail = result["email"].string {
                                
                                user.username = facebookNameFromEmail.components(separatedBy: "@").first?.replacingOccurrences(of: " ", with: "")
                                user["username_lowercase"] = user.username!.lowercased()
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
                            
                            if let pictureURL = result["picture"]["data"]["url"].url?.absoluteString {
                                user["profile_image_url"] = pictureURL
                            }
                            
                            if let profileBannerURL = result["cover"]["source"].url?.absoluteString {
                                user["profile_banner_url"] = profileBannerURL
                            }
                            
                            if let website = result["website"].string {
                                user["website"] = website.components(separatedBy: "\n").first
                                user["website_raw"] = website.components(separatedBy: "\n")
                            }
                            
                            if let bio = result["bio"].string {
                                user["bio"] = bio
                            }
                            
                            if let socialmedia_verified = result["verified"].bool {
                                user["socialmedia_verified"] = socialmedia_verified
                            }
                            
                            user["follower_notification"] = true
                            user["mention_notification"] = true
                            user["newTradeIdea_notification"] = true
                            user["replyTradeIdea_notification"] = true
                            user["likeTradeIdea_notification"] = true
                            user["reshareTradeIdea_notification"] = true
                            user["swipe_addToWatchlist"] = false
                            
                            self.saveUser(user, firstName: firstName, lastName: lastName)
                            
                        } else {
                            // failure
                            print("Fetch failed: \(error?.localizedDescription)")
                        }
                    } catch {
                        //TODO: handle error
                    }
                })
            }
            
//        } else if user.value(forKey: "emailVerified") as? Bool == true {
//
//            self.logInViewController.dismiss(animated: true, completion: { () -> Void in
//
//                self.dismissViewControllerAnimated(false, completion: nil)
//
//            })
//
//        }
            
        } else {
            
            user["full_name"] = user.username
            saveUser(user, firstName: nil, lastName: nil)
        }
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        
        print(error?.localizedDescription)
        
        if !Functions.isConnectedToNetwork() {
            
            // Show Error Alert
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
            return
            
        } else {
            
            // Show Error Alert
            SweetAlert().showAlert("Logged Failed!", subTitle: error?.localizedDescription, style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Ok", buttonColor:UIColor(rgbValue: 0xD0D0D0) , otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                
            }
        }
    }
    
    // Mark - Parse Signup
    
    func signUpViewController(_ signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool {
        
        let dismissAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!) in
            signUpController.dismiss(animated: true, completion: nil)
        })
        
        if Functions.isConnectedToNetwork() == false {
            
            signUpController.present(Functions.displayAlert("No Internet Connection", message: "Make sure your device is connected to the internet", Action1: dismissAlertAction, Action2: nil), animated: true, completion: nil)
            
            return false
            
        } else {
            
            var usernameField: String!
            var passwordField: String!
            var emailField: String!
            
            for _ in info {
                
                usernameField = info["username"]
                passwordField = info["password"]
                emailField = info["email"]
            }
            
            if usernameField?.isEmpty == true || passwordField?.isEmpty == true || emailField?.isEmpty == true {
                
                signUpController.present(Functions.displayAlert("Missing Information", message: "Please fill in all the fields", Action1: dismissAlertAction, Action2: nil), animated: true, completion: nil)
                
                return false
                
            }
            
            return true
        }
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        
        let dismissAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!) in
            signUpController.dismiss(animated: true, completion: nil)
        })
        
        self.logInViewController.dismiss(animated: true, completion: { () -> Void in
            
            self.dismiss(animated: true, completion: nil)
            
            signUpController.present(Functions.displayAlert("Sign Up Complete!", message: "We have sent you a verification email - you must verify your email to continue.", Action1: dismissAlertAction, Action2: nil), animated: true, completion: nil)
        })
        
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        
        print("Failed to sign up")
        
    }
    
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController) {
        
        print("User dismissed sign up")
    }
    
    func registerUserMailChimp(listID: String, firstName: String?, lastName: String?, username: String?, email: String?) {
        
        guard let username = username, let email = email else { return }
        
        let params:[String: Any] = ["id": listID, "email": ["email": email], "merge_vars": ["FNAME": firstName ?? "", "LNAME": lastName ?? "", "username": username], "double_optin": false]
        ChimpKit.shared().callApiMethod("lists/subscribe", withParams: params, andCompletionHandler: {(response, data, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                print("ChimpKit response:", httpResponse)
            }
        })
    }
    
    // MARK: User functions
    func saveUser(_ user: PFUser, firstName: String?, lastName: String?) {
        
        user.saveInBackground(block: { (success, error) in
            
            if success {
                
                // register current installation
                if let currentInstallation = PFInstallation.current() {
                    currentInstallation["user"] = user
                    currentInstallation.saveInBackground()
                }
                
                // register to LaunchKit
                LaunchKit.sharedInstance().setUserIdentifier(user.objectId, email: user.email, name: user.username)
                
                // register to MailChimp
                self.registerUserMailChimp(listID: "4266807125", firstName: firstName, lastName: lastName, username: user.username, email: user.email)
                
                // send delegate info
                self.loginDelegate?.didLoginSuccessfully()
                
                // Log Login
                Answers.logLogin(withMethod: ACAccountStore().accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter).accountTypeDescription, success: 1, customAttributes: ["User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
                
            }
            
            self.logInViewController.dismiss(animated: true, completion: { () -> Void in
                self.dismiss(animated: true, completion: nil)
                SweetAlert().showAlert("Logged In!", subTitle: "You are now Logged in", style: AlertStyle.success)
            })
        })
    }
}
