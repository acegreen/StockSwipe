//
//  IdeaPostViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 4/5/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import Crashlytics

protocol IdeaPostDelegate {
    func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType)
    func ideaDeleted(with activity: Activity)
    func ideaUpdated(with activity: Activity)
}

class IdeaPostViewController: UIViewController, UITextViewDelegate {
    
    var originalSize: CGSize!
    var prefillText = String()
    var textToPost = String()
    
    var tradeIdeaPostCharacterLimit = 199 {
        didSet{
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit - self.ideaTextView.text.count)
        }
    }
    
    var stockObject: PFObject?
    var activity: Activity?
    var tradeIdeaType: Constants.TradeIdeaType = .new
    
    var delegate: IdeaPostDelegate!
    
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var ideaTextView: IdeaPostUITextView!
    
    @IBOutlet var textCountLabel: UILabel!
    
    @IBOutlet var postButton: UIButton!
    
    @IBAction func postButttonPressed(_ sender: AnyObject) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.warning)
            return
        }
        guard let currentUser = PFUser.current() else {
            Functions.isUserLoggedIn(presenting: self)
            return
        }
        
        guard (self.ideaTextView.text.filter{ $0 != " " }.count <= self.tradeIdeaPostCharacterLimit) else {
            return
        }
        
        let (cashtags, mentions, hashtags) = self.ideaTextView.detectTags()
        
        let tradeIdeaObject = TradeIdea()
        tradeIdeaObject["user"] = currentUser
        tradeIdeaObject["ideaDescription"] = self.textToPost
        
        let activityObject = Activity()
        activityObject["fromUser"] = currentUser
        activityObject["tradeIdea"] = tradeIdeaObject
        
        if tradeIdeaType == .reply, let originalTradeIdea = self.activity?.tradeIdea {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaReply.rawValue
            activityObject["toUser"] = self.activity?.fromUser
            activityObject["originalTradeIdea"] = originalTradeIdea
            tradeIdeaObject["reply_to"] = originalTradeIdea
        } else if tradeIdeaType == .reshare, let originalTradeIdea = self.activity?.tradeIdea {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaReshare.rawValue
            activityObject["toUser"] = self.activity?.fromUser
            activityObject["originalTradeIdea"] = originalTradeIdea
            tradeIdeaObject["reshare_of"] = originalTradeIdea
        } else {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaNew.rawValue
        }
        
        activityObject.saveEventually()
        
        // query all the Stocks mentioned & add them to tradeIdeaObject
        QueryHelper.sharedInstance.queryStockObjectsFor(symbols: cashtags, completion: { (result) in
            
            do {
                
                let stockObjects = try result()
                tradeIdeaObject["stocks"] = stockObjects
                
                for stockObject in stockObjects {
                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["tradeIdea"] = tradeIdeaObject
                    activityObject["stock"] = stockObject
                    activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
                    activityObject.saveEventually()
                }
                
            } catch {
                //TODO: handle error
            }
        })
        
        // query all the users mentioned & add them to tradIdeaObject
        QueryHelper.sharedInstance.queryUserObjectsFor(usernames: mentions, completion: { (result) in
            
            do {
                
                let userObjects = try result()
                
                tradeIdeaObject["users"] = userObjects
                
                for userObject in userObjects {
                    
                    // Avoid creating an activity when self is mentioned
                    guard userObject.objectId != self.activity?.fromUser.objectId else {
                        continue
                    }
                    
                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["tradeIdea"] = tradeIdeaObject
                    activityObject["toUser"] = userObject
                    activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
                    activityObject.saveEventually()
                    
                    #if DEBUG
                        print("send push didn't happen in debug")
                    #else
                        Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": userObject.objectId!, "tradeIdeaObjectId": tradeIdeaObject.objectId!, "checkSetting": "mention_notification", "title": "Trade Idea Mention Notification", "message": "@\(currentUser.username!) mentioned you in a trade idea"])
                    #endif
                }
            } catch {
                //TODO: handle error
            }
        })
        
        // record all hashtag
        for hashtag in hashtags {
            
            let activityObject = Activity()
            activityObject["fromUser"] = currentUser
            activityObject["tradeIdea"] = tradeIdeaObject
            activityObject["hashtag"] = hashtag
            activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
            activityObject.saveEventually()
        }
        
        tradeIdeaObject["hashtags"] = hashtags
        tradeIdeaObject.saveEventually({ (success, error) in
            
            if success {
                
                // log trade idea
                Answers.logCustomEvent(withName: "Trade Idea", customAttributes: ["Symbol/User":self.prefillText, "User": User.current()?.username ?? "N/A", "Description": self.ideaTextView.text, "Activity Type": activityObject["activityType"],"App Version": Constants.AppVersion])
                
                self.delegate?.ideaPosted(with: activityObject, tradeIdeaTyp: self.tradeIdeaType)
                
                if self.tradeIdeaType == .new {
                    #if DEBUG
                        print("send push didn't happen in debug")
                    #else
                        Functions.sendPush(Constants.PushType.ToFollowers, parameters: ["userObjectId": currentUser.objectId!, "tradeIdeaObjectId": tradeIdeaObject.objectId!, "checkSetting": "newTradeIdea_notification", "title": "Trade Idea New Notification", "message": "@\(currentUser.username!) posted:\n" + tradeIdeaObject.ideaDescription])
                    #endif
                }
                
            } else {
                DispatchQueue.main.async {
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                }
            }
        })
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    deinit {
        stopObservingKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set original size for later
        originalSize = self.view.bounds.size
        
        // Keep track of keyboard movement and adjust view
        observeKeyboardNotifications()
        
        // flexible height
        self.view.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
        
        // Setup config parameters
        Functions.setupConfigParameter("TRADEIDEAPOSTCHARACTERLIMIT") { (parameterValue) -> Void in
            self.tradeIdeaPostCharacterLimit = parameterValue as? Int ?? 199
        }
        
        // prefill text
        if tradeIdeaType == .new, let stockObject = self.stockObject {
            self.prefillText = "$" + (stockObject.object(forKey: "Symbol") as! String)
        } else if tradeIdeaType == .reply, let originalTradeIdea = self.activity?.tradeIdea {
            self.prefillText = self.activity?.fromUser.usertag ?? ""
        } else if tradeIdeaType == .reshare && self.activity?.tradeIdea != nil {
            
        }
        
        if self.prefillText.isEmpty {
            postButton.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if !self.prefillText.isEmpty {
            self.ideaTextView.text = "\(self.prefillText) "
            self.textToPost = self.prefillText
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit - self.ideaTextView.text.count)
        } else {
            self.ideaTextView.text = "Share an idea\n(use $ before ticker: e.g. $AAPL)"
            self.ideaTextView.textColor = UIColor.lightGray
            self.ideaTextView.selectedTextRange = self.ideaTextView.textRange(from: self.ideaTextView.beginningOfDocument, to: self.ideaTextView.beginningOfDocument)
        }
        
        self.ideaTextView.becomeFirstResponder()
    }
    
    func observeKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(IdeaPostViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(IdeaPostViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func stopObservingKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ n: Notification) {
        
        if let keyboardRect = ((n as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {

            let intersectionFrame = self.view.frame.intersection(keyboardRect)
            
            print("self.view.frame: ", self.view.frame)
            print("keyboardRect: ", keyboardRect)
            print("intersectionFrame:", intersectionFrame)
            
//            if self.isBeingPresentedInFormSheet() {
//                if UIDevice.currentDevice().orientation.isLandscape {
//                    self.preferredContentSize = CGSize(width: self.originalSize.width, height: self.originalSize.height - intersectionFrame.height)
//                } else if UIDevice.currentDevice().orientation.isPortrait {
//                    self.preferredContentSize = CGSize(width: self.originalSize.width, height: self.originalSize.height - intersectionFrame.height)
//                }
//            }
//            
//            UIView.animateWithDuration(n.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue, animations: {() -> Void in
//                self.presentationController?.containerView?.setNeedsLayout()
//                self.presentationController?.containerView?.layoutIfNeeded()
//            })
        }
    }
    
    @objc func keyboardWillHide(_ n: Notification) {
        
//        if self.isBeingPresentedInFormSheet() {
//            self.preferredContentSize = CGSize(width: self.originalSize.width, height: self.originalSize.height)
//        }
//        
//        UIView.animateWithDuration(n.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue, animations: {() -> Void in
//            self.presentationController?.containerView?.setNeedsLayout()
//            self.presentationController?.containerView?.layoutIfNeeded()
//        })
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        var currentText: NSString = textView.text as NSString
        var updatedText = currentText.replacingCharacters(in: range, with:text)
        
        if updatedText.isEmpty {
            
            postButton.isEnabled = false            
            
            // Set label to 0
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit)
            
            if !prefillText.isEmpty {
                ideaTextView.text = "Share a idea on \(self.prefillText)"
            } else {
                ideaTextView.text = "Share a idea\n(use $ before ticker: e.g. $AAPL)"
            }
            textView.textColor = UIColor.lightGray
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            
            textToPost = ""
            
            return false
            
        } else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            
            textView.text = nil
            textView.textColor = UIColor.black
            
        }
        
        if textView.textColor != UIColor.lightGray {
            
            // Keep track of character count and update label
            currentText = textView.text as NSString
            updatedText = currentText.replacingCharacters(in: range, with:text)
            self.textCountLabel.text = String(tradeIdeaPostCharacterLimit - updatedText.count)
            self.textToPost = updatedText
            
            if tradeIdeaPostCharacterLimit - updatedText.count < 0 {
                self.textCountLabel.textColor = UIColor.red
                postButton.isEnabled = false
            } else {
                self.textCountLabel.textColor = Constants.SSColors.grey
                
                if (updatedText.filter{$0 != " "}.count > 0) {
                    postButton.isEnabled = true
                }
            }
        }
        
        return true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
    }
}
