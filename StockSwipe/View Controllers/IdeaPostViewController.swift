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

class IdeaPostViewController: UIViewController, UITextViewDelegate {
    
    var prefillText: String!
    
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
    
    @IBOutlet var postButton: CorneredBorderedUIButton!
    
    @IBAction func postButttonPressed(sender: AnyObject) {
        
        guard Functions.isUserLoggedIn(self) else { return }
        guard self.ideaTextView.text != nil else { return }
        
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
        
        tradeIdeaObject.saveInBackgroundWithBlock({ (success, error) in
            
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
        
        // Keep track of keyboard movement and adjust view
        observeKeyboardNotifications()
        
        // flexible height
        self.view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
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
        
        if !prefillText.isEmpty {
            self.ideaTextView.text = "\(self.prefillText) "
            self.textCountLabel.text = "6"
        } else {
            ideaTextView.text = "Share an idea\n(use $ before ticker: e.g. $AAPL)"
            ideaTextView.textColor = UIColor.lightGrayColor()
            ideaTextView.selectedTextRange = ideaTextView.textRangeFromPosition(ideaTextView.beginningOfDocument, toPosition: ideaTextView.beginningOfDocument)
        }
        ideaTextView.becomeFirstResponder()

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
            
            let keyboardSize = keyboardRect.size
            let keyboardHeight = keyboardSize.height
            let intersectionFrame = CGRectIntersection(self.view.frame, keyboardRect)
            
            print(self.view.frame)
            print(keyboardRect)
            print(intersectionFrame)
            
            UIView.animateWithDuration(n.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue, animations: {() -> Void in
                
                if self.isBeingPresentedInFormSheet() {
                    self.textViewBottomConstraint.constant = -(intersectionFrame.height + 20)
                } else {
                    self.textViewBottomConstraint.constant = -keyboardHeight
                }
            })
        }
    }
    
    func keyboardWillHide(n: NSNotification) {
        
        UIView.animateWithDuration(n.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue, animations: {() -> Void in
            self.textViewBottomConstraint.constant = 0
        })
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        var currentText:NSString = textView.text
        var updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
        
        if updatedText.isEmpty {
            
            postButton.enabled = false
            
            // Keep track of character count and update label
            self.textCountLabel.text = "0"
            
            if !prefillText.isEmpty {
                ideaTextView.text = "\(self.prefillText)"
            } else {
                ideaTextView.text = "Share an idea\n(use $ before ticker: e.g. $AAPL)"
            }
            textView.textColor = UIColor.lightGrayColor()
            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            
            return false
            
        } else if textView.textColor == UIColor.lightGrayColor() && !text.isEmpty {
            
            postButton.enabled = true
            
            textView.text = nil
            textView.textColor = Constants.stockSwipeFontColor
            
        }
    
        if textView.textColor != UIColor.lightGrayColor() {
            
            // Keep track of character count and update label
            currentText = textView.text
            updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
            self.textCountLabel.text = String(updatedText.characters.count)
        }
        
        return true
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGrayColor() {
                textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            }
        }
    }
}
