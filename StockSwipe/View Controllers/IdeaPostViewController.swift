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
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType)
    func ideaDeleted(with tradeIdeaObject: PFObject)
}

class IdeaPostViewController: UIViewController, UITextViewDelegate {
    
    var originalSize: CGSize!
    var prefillText = String()
    var textToPost = String()
    
    var tradeIdeaPostCharacterLimit = 199 {
        didSet{
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit - self.ideaTextView.text.characters.count)
        }
    }
    
    var stockObject: PFObject?
    var originalTradeIdea: TradeIdea?
    var tradeIdeaType: Constants.TradeIdeaType = .New
    
    var delegate: IdeaPostDelegate!
    
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet var ideaTextView: IdeaPostUITextView!
    
    @IBOutlet var textCountLabel: UILabel!
    
    @IBOutlet var postButton: UIButton!
    
    @IBAction func postButttonPressed(sender: AnyObject) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
            return
        }
        guard let currentUser = PFUser.currentUser() else {
            Functions.isUserLoggedIn(self)
            return
        }
        
        guard (self.ideaTextView.text.characters.filter{ $0 != " " }.count <= self.tradeIdeaPostCharacterLimit) else {
            return
        }
        
        let (cashtags, mentions, hashtags) = self.ideaTextView.detectTags()
        
        let tradeIdeaObject = PFObject(className: "TradeIdea")
        tradeIdeaObject["user"] = currentUser
        tradeIdeaObject["description"] = self.textToPost
        
        let activityObject = PFObject(className: "Activity")
        activityObject["fromUser"] = currentUser
        activityObject["tradeIdea"] = tradeIdeaObject
        
        if tradeIdeaType == .Reply, let originalTradeIdea = self.originalTradeIdea {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaReply.rawValue
            activityObject["toUser"] = originalTradeIdea.user.userObject
            activityObject["originalTradeIdea"] = originalTradeIdea.parseObject
            tradeIdeaObject["reply_to"] = originalTradeIdea.parseObject
        } else if tradeIdeaType == .Reshare, let originalTradeIdea = self.originalTradeIdea {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaReshare.rawValue
            activityObject["toUser"] = originalTradeIdea.user.userObject
            activityObject["originalTradeIdea"] = originalTradeIdea.parseObject
            tradeIdeaObject["reshare_of"] = originalTradeIdea.parseObject
        } else {
            activityObject["activityType"] = Constants.ActivityType.TradeIdeaNew.rawValue
        }
        
        activityObject.saveEventually()
        
        tradeIdeaObject.saveEventually({ (success, error) in
            
            if success {
                
                let newtradeIdea = TradeIdea(parseObject: tradeIdeaObject, completion: { (newtradeIdea) in
                    if let newtradeIdea = newtradeIdea {
                        self.delegate?.ideaPosted(with: newtradeIdea, tradeIdeaTyp: self.tradeIdeaType)
                    }
                })
                
                switch self.tradeIdeaType {
                case .New:
                    
                    Functions.sendPush(Constants.PushType.ToFollowers, parameters: ["userObjectId":currentUser.objectId!, "tradeIdeaObjectId":newtradeIdea.parseObject.objectId!, "checkSetting": "newTradeIdea_notification", "title": "Trade Idea New Notification", "message": "@\(currentUser.username!) posted:\n\(newtradeIdea.description)"])
                    
                case .Reply, .Reshare: break   
                }
                
                // log trade idea
                Answers.logCustomEventWithName("Trade Idea", customAttributes: ["Symbol/User":self.prefillText,"User": PFUser.currentUser()?.username ?? "N/A","Description": self.ideaTextView.text, "App Version": Constants.AppVersion])
                
                // query all the Stocks mentioned & add them to tradIdeaObject
                QueryHelper.sharedInstance.queryStockObjectsFor(cashtags, completion: { (result) in
                    
                    do {
                        
                        let stockObjects = try result()
                        
                        tradeIdeaObject["stocks"] = stockObjects
                        
                        for stockObject in stockObjects {
                            let activityObject = PFObject(className: "Activity")
                            activityObject["fromUser"] = currentUser
                            activityObject["tradeIdea"] = tradeIdeaObject
                            activityObject["stock"] = stockObject
                            activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
                            activityObject.saveEventually()
                        }
                        
                    } catch {
                        
                    }
                    
                })
                
                // query all the users mentioned & add them to tradIdeaObject
                QueryHelper.sharedInstance.queryUserObjectsFor(mentions, completion: { (result) in
                    
                    do {
                        
                        let userObjects = try result()
                        
                        tradeIdeaObject["users"] = userObjects
                        
                        for userObject in userObjects {
                            
                            guard userObject.objectId != self.originalTradeIdea?.user.objectId else {
                                continue
                            }
                            
                            let activityObject = PFObject(className: "Activity")
                            activityObject["fromUser"] = currentUser
                            activityObject["tradeIdea"] = tradeIdeaObject
                            activityObject["toUser"] = userObject
                            activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
                            activityObject.saveEventually()
                        }
                        
                    } catch {
                        
                    }
                })
                
                // record all hashtag
                for hashtag in hashtags {
                    
                    let activityObject = PFObject(className: "Activity")
                    activityObject["fromUser"] = currentUser
                    activityObject["tradeIdea"] = tradeIdeaObject
                    activityObject["hashtag"] = hashtag
                    activityObject["activityType"] = Constants.ActivityType.Mention.rawValue
                    activityObject.saveEventually()
                }
                
                tradeIdeaObject["hashtags"] = hashtags
                
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                })
            }
        })
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
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
        self.view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
        // Setup config parameters
        Functions.setupConfigParameter("TRADEIDEAPOSTCHARACTERLIMIT") { (parameterValue) -> Void in
            self.tradeIdeaPostCharacterLimit = parameterValue as? Int ?? 199
        }
        
        // prefill text
        if tradeIdeaType == .New, let stockObject = self.stockObject {
            self.prefillText = "$" + (stockObject.objectForKey("Symbol") as! String)
        } else if tradeIdeaType == .Reply, let originalTradeIdea = self.originalTradeIdea {
            self.prefillText = "@" + (originalTradeIdea.user.username)
        } else if tradeIdeaType == .Reshare && self.originalTradeIdea != nil {
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if !self.prefillText.isEmpty {
            self.ideaTextView.text = "\(self.prefillText) "
            self.textToPost = self.prefillText
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit - self.ideaTextView.text.characters.count)
        } else {
            self.ideaTextView.text = "Share an idea\n(use $ before ticker: e.g. $AAPL)"
            self.ideaTextView.textColor = UIColor.lightGrayColor()
            self.ideaTextView.selectedTextRange = self.ideaTextView.textRangeFromPosition(self.ideaTextView.beginningOfDocument, toPosition: self.ideaTextView.beginningOfDocument)
        }
        
        self.ideaTextView.becomeFirstResponder()
    }
    
    func observeKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IdeaPostViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IdeaPostViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func stopObservingKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(n: NSNotification) {
        
        if let keyboardRect = n.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {

            let intersectionFrame = CGRectIntersection(self.view.frame, keyboardRect)
            
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
    
    func keyboardWillHide(n: NSNotification) {
        
//        if self.isBeingPresentedInFormSheet() {
//            self.preferredContentSize = CGSize(width: self.originalSize.width, height: self.originalSize.height)
//        }
//        
//        UIView.animateWithDuration(n.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue, animations: {() -> Void in
//            self.presentationController?.containerView?.setNeedsLayout()
//            self.presentationController?.containerView?.layoutIfNeeded()
//        })
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        var currentText: NSString = textView.text
        var updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
        
        if updatedText.isEmpty {
            
            postButton.enabled = false            
            
            // Set label to 0
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit)
            
            if !prefillText.isEmpty {
                ideaTextView.text = "Share a idea on \(self.prefillText)"
            } else {
                ideaTextView.text = "Share a idea\n(use $ before ticker: e.g. $AAPL)"
            }
            textView.textColor = UIColor.lightGrayColor()
            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            
            textToPost = ""
            
            return false
            
        } else if textView.textColor == UIColor.lightGrayColor() && !text.isEmpty {
            
            textView.text = nil
            textView.textColor = UIColor.blackColor()
            
        }
        
        if textView.textColor != UIColor.lightGrayColor() {
            
            // Keep track of character count and update label
            currentText = textView.text
            updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
            self.textCountLabel.text = String(tradeIdeaPostCharacterLimit - updatedText.characters.count)
            self.textToPost = updatedText
            
            if tradeIdeaPostCharacterLimit - updatedText.characters.count < 0 {
                self.textCountLabel.textColor = UIColor.redColor()
                postButton.enabled = false
            } else {
                self.textCountLabel.textColor = Constants.stockSwipeFontColor
                
                if (updatedText.characters.filter{$0 != " "}.count > 0) {
                    postButton.enabled = true
                }
            }
        }
        
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
        }
    }
}
