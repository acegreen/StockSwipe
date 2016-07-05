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
    func ideaDeleted(with parseObject: PFObject)
}

class IdeaPostViewController: UIViewController, UITextViewDelegate {
    
    var originalSize: CGSize!
    var prefillText: String!
    var tradeIdeaPostCharacterLimit = 199 {
        didSet{
            self.textCountLabel.text = String(self.tradeIdeaPostCharacterLimit - self.ideaTextView.text.characters.count)
        }
    }
    
    var stockObject: PFObject!
    var replyTradeIdea: TradeIdea!
    var reshareTradeIdea: TradeIdea!
    
    var delegate: IdeaPostDelegate!
    
    @IBOutlet var textViewBottomConstraint: NSLayoutConstraint!
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBOutlet var ideaTextView: UITextView!
    
    @IBOutlet var textCountLabel: UILabel!
    
    @IBOutlet var postButton: UIButton!
    
    @IBAction func postButttonPressed(sender: AnyObject) {
        
        guard Functions.isConnectedToNetwork() else {
            SweetAlert().showAlert("No Internet Connection", subTitle: "Make sure your device is connected to the internet", style: AlertStyle.Warning)
            return
        }
        guard Functions.isUserLoggedIn(self) else { return }
        guard self.ideaTextView.text != nil && (self.ideaTextView.text.characters.filter{ $0 != " " }.count <= self.tradeIdeaPostCharacterLimit) && self.ideaTextView.textColor != UIColor.lightGrayColor() else {
            return
        }
        
        let tradeIdeaObject = PFObject(className: "TradeIdea")
        tradeIdeaObject["user"] = PFUser.currentUser()
        tradeIdeaObject["description"] = self.ideaTextView.text
        
        var tradeIdeaType: Constants.TradeIdeaType = .New
        
        if let tradeIdea = self.stockObject {
            tradeIdeaObject["stock"] = tradeIdea
            tradeIdeaType = .New
        } else if let tradeIdea = self.replyTradeIdea {
            tradeIdeaObject["stock"] = tradeIdea.stock
            tradeIdeaObject["reply_to"] = tradeIdea.parseObject
            tradeIdeaType = .Reply
        } else if let tradeIdea = self.reshareTradeIdea {
            tradeIdeaObject["stock"] = tradeIdea.stock
            tradeIdeaObject["reshare_of"] = tradeIdea.parseObject
            tradeIdeaType = .Reshare
        }
        
        tradeIdeaObject.saveEventually({ (success, error) in
            
            if success {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.delegate.ideaPosted(with: tradeIdea, tradeIdeaTyp: tradeIdeaType)
                    
                    // log trade idea
                    Answers.logCustomEventWithName("Trade Idea", customAttributes: ["Symbol/User":self.prefillText,"User": PFUser.currentUser()?.username ?? "N/A","Description": self.ideaTextView.text,"Installation ID":PFInstallation.currentInstallation().installationId, "App Version": Constants.AppVersion])
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                    
                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                })
            }
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
        if let tradeIdea = self.stockObject {
            self.prefillText = "$" + (tradeIdea.objectForKey("Symbol") as! String)
        } else if let tradeIdea = self.replyTradeIdea {
            self.prefillText = "@" + (tradeIdea.user.objectForKey("username") as! String)
        } else if let tradeIdea = self.reshareTradeIdea {
            self.prefillText = "$" + (tradeIdea.stock.objectForKey("Symbol") as! String)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if !self.prefillText.isEmpty {
            self.ideaTextView.text = "\(self.prefillText) "
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
        
        var currentText:NSString = textView.text
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
