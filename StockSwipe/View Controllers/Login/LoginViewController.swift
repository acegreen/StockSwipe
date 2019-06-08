//
//  LoginViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-27.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import Parse
import Firebase
import ChimpKit
import SwiftyJSON
import Branch

protocol LoginDelegate {
    func didLoginSuccessfully()
    func didLogoutSuccessfully()
}

class LoginViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    static let sharedInstance = LoginViewController()
    
    var loginDelegate: LoginDelegate?
    
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
        
        if PFUser.current() != nil {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    // Mark - Parse Login
    
    func logIn(_ viewController: UIViewController) {
        
        guard Functions.isConnectedToNetwork() else {
            Functions.showNotificationBanner(title: "No Internet Connection", subtitle: "Make sure your device is connected to the internet", style: .warning)
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
            Functions.showNotificationBanner(title: "No Action!", subtitle: "You are already Logged in", style: .none)
            viewController.dismiss(animated: false, completion: nil)
        }
    }
    
    func logOut() {
        
        guard Functions.isConnectedToNetwork() else {
            Functions.showNotificationBanner(title: "No Internet Connection", subtitle: "Make sure your device is connected to the internet", style: .warning)
            return
        }
        
        guard PFUser.current() != nil else { return }
        
        PFUser.logOutInBackground { (error) in
            
            if error == nil {
                Functions.showNotificationBanner(title: "Logged Out!", subtitle: "You are now logged out", style: .success)
                self.loginDelegate?.didLogoutSuccessfully()
                
                // logout user on Branch
                Branch.getInstance().logout()
            }
        }
    }
    
    func log(_ logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        
        guard Functions.isConnectedToNetwork() else {
            Functions.showNotificationBanner(title: "No Internet Connection", subtitle: "Make sure your device is connected to the internet.", style: .warning)
            return false
        }
        
        if !username.isEmpty && !password.isEmpty {
            return true
        } else {
            Functions.showNotificationBanner(title: "Missing Information", subtitle: "Please enter both your username & password", style: .warning)
            
            return false
        }
    }
    
    func log(_ logInController: PFLogInViewController, didLogIn user: PFUser) {
        
        if PFTwitterUtils.isLinked(with: user) {
            
            if user.isNew {
                
                let verify = URL(string: "https://api.twitter.com/1.1/account/verify_credentials.json?include_email=true&skip_status=true")
                let request = NSMutableURLRequest(url: verify!)
                PFTwitterUtils.twitter()!.sign(request)
                var response: URLResponse?
                
                do {
                    
                    let data = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
                    let result = try JSON(data: data)
                    
                    if let twitterUsername = PFTwitterUtils.twitter()?.screenName {
                        user.username = twitterUsername
                        user["username_lowercase"] = user.username!.lowercased()
                    }
                    
                    if let twitterName = result["name"].string {
                        user["full_name"] = twitterName
                        
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
                    
                    self.saveUser(user)
                    
                } catch let error as NSError {
                    
                    // failure
                    print("Fetch failed: \(error.localizedDescription)")
                }
                
            } else {
                // register user and dismiss
                self.registerUser(user: user)
                self.dismissVC(user: user)
            }
            
        } else if PFFacebookUtils.isLinked(with: user) {
            
            if user.isNew {
                
                if let accessToken = FBSDKAccessToken.current() {
                    
                    guard let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,id,name,first_name,last_name,picture,verified"], tokenString: accessToken.tokenString, version: nil, httpMethod: "GET") else { return }
                    
                    req.start(completionHandler: { (connection, object, error) in
                        
                        do {
                            
                            guard error == nil else {
                                print("Fetch failed: \(error!.localizedDescription)")
                                return
                            }
                                
                            guard object != nil else { return }
                            let result = try JSON(object)
                            
                            print(result)
                            
                            if let facebookNameFromName = result["name"].string {
                                
                                user.username = facebookNameFromName.replacingOccurrences(of: " ", with: "")
                                user["username_lowercase"] = user.username!.lowercased()
                                
                                user["full_name"] = facebookNameFromName
                                user["fullname_lowercase"] = (user["full_name"] as AnyObject).lowercased
                                
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
                            
                            self.saveUser(user)
                        } catch {
                            //TODO: handle error
                        }
                    })
                }
                
            } else {
                // register user and dismiss
                self.registerUser(user: user)
                self.dismissVC(user: user)
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
            user["follower_notification"] = true
            user["mention_notification"] = true
            user["newTradeIdea_notification"] = true
            user["replyTradeIdea_notification"] = true
            user["likeTradeIdea_notification"] = true
            user["reshareTradeIdea_notification"] = true
            user["swipe_addToWatchlist"] = false
            
            saveUser(user)
        }
    }
    
    func log(_ logInController: PFLogInViewController, didFailToLogInWithError error: Error?) {
        
        print(error?.localizedDescription)
        
        if !Functions.isConnectedToNetwork() {
            
            // Show Error Alert
            Functions.showNotificationBanner(title: "No Internet Connection", subtitle: "Make sure your device is connected to the internet", style: .warning)
            return
            
        } else {
            // Show Error Alert
            Functions.showNotificationBanner(title: "Logged Failed!", subtitle: error?.localizedDescription, style: .warning)
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
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didSignUp user: PFUser) {
        
        //        let dismissAlertAction = UIAlertAction(title: "Ok", style: .default, handler:{ (ACTION :UIAlertAction!) in
        //            signUpController.dismiss(animated: true, completion: nil)
        //        })
        //
        //        signUpController.present(Functions.displayAlert("Sign Up Complete!", message: "We have sent you a verification email - you must verify your email to continue.", Action1: dismissAlertAction, Action2: nil), animated: true, completion: nil)
        
        user["full_name"] = user.username
        user["follower_notification"] = true
        user["mention_notification"] = true
        user["newTradeIdea_notification"] = true
        user["replyTradeIdea_notification"] = true
        user["likeTradeIdea_notification"] = true
        user["reshareTradeIdea_notification"] = true
        user["swipe_addToWatchlist"] = false
        
        saveUser(user)
    }
    
    func signUpViewController(_ signUpController: PFSignUpViewController, didFailToSignUpWithError error: Error?) {
        print("Failed to sign up")
    }
    
    func signUpViewControllerDidCancelSignUp(_ signUpController: PFSignUpViewController) {
        print("User dismissed sign up")
    }
    
    func registerUserMailChimp(listID: String, firstname: String?, lastname: String?, username: String?, email: String?) {
        
        guard let username = username, let email = email else { return }
        
        let params:[String: Any] = ["id": listID, "email": ["email": email], "merge_vars": ["FNAME": firstname ?? "", "LNAME": lastname ?? "", "username": username], "double_optin": false]
        ChimpKit.shared().callApiMethod("lists/subscribe", withParams: params, andCompletionHandler: {(response, data, error) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                print("ChimpKit response:", httpResponse)
            }
        })
    }
    
    // MARK: User functions
    func saveUser(_ user: PFUser) {
        
        user.saveInBackground(block: { (success, error) in
            
            if success {
                
                // register user
                self.registerUser(user: user)
                
                // dismissVC
                self.dismissVC(user: user)
                
                // log Login
                Analytics.logEvent(AnalyticsEventLogin, parameters: [
                    "user": PFUser.current()?.username ?? "N/A",
                    "app_version": Constants.AppVersion
                ])
                
            } else {
                print(error?.localizedDescription)
                self.handleUserAlreadyExists(error: error!, user: user)
            }
        })
    }
    
    private func registerUser(user: PFUser) {
        // register current installation
        if let currentInstallation = PFInstallation.current() {
            currentInstallation["user"] = user
            currentInstallation.saveInBackground()
        }
        
        let firstname = (user as? User)?.full_name?.components(separatedBy: " ").first
        let lastname = (user as? User)?.full_name?.components(separatedBy: " ").last
        
        // register to Branch
        Branch.getInstance().setIdentity(user.objectId)
        
        // register to MailChimp
        self.registerUserMailChimp(listID: "4266807125", firstname: firstname, lastname: lastname, username: user.username, email: user.email)
    }
    
    func dismissVC(user: PFUser) {
    
        // send delegate info
        self.loginDelegate?.didLoginSuccessfully()
        
        DispatchQueue.main.async {
            self.signUpViewController.dismiss(animated: true, completion: nil)
            self.logInViewController.dismiss(animated: true, completion: { () -> Void in
                self.dismiss(animated: true, completion: nil)
                Functions.showNotificationBanner(title: "Logged In!", subtitle: "You are now Logged in", style: .success)
                
                NotificationCenter.default.post(name: Notification.Name("UserLoggedIn"), object: nil, userInfo: ["user": user])
            })
        }
    }
    
    func handleUserAlreadyExists(error: Error, user: PFUser) {
        let originalError = error
        
        PFCloud.callFunction(inBackground: "deleteUserWithObjectID", withParameters: ["objectID": user.objectId]) { (results, error) in }
        PFUser.logOutInBackground { (error) in
            if error == nil {
                DispatchQueue.main.async {
                    Functions.showNotificationBanner(title: "Login Clash!", subtitle: originalError.localizedDescription, style: .warning)
                }
                self.loginDelegate?.didLogoutSuccessfully()
            }
        }
    }
}

// Mark - UIPageViewController and delegate functions
