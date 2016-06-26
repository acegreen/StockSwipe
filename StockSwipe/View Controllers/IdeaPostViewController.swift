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

class IdeaPostViewController: UIViewController, ChartDetailDelegate, UITextViewDelegate {
    
    var symbol: String!
    var companyName: String!
    
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
        tradeIdeaObject["stock"] = stockObject
        tradeIdeaObject["description"] = self.ideaTextView.text
        
        if let tradeIdeaParseObject = self.replyTradeIdea?.parseObject {
            tradeIdeaObject["reply_to"] = tradeIdeaParseObject
        } else if let tradeIdeaParseObject = self.reshareTradeIdea?.parseObject {
            tradeIdeaObject["reshare_of"] = tradeIdeaParseObject
        }
        
        tradeIdeaObject.saveInBackgroundWithBlock({ (success, error) in
            
            if success {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.delegate.ideaPosted(with: tradeIdea)
                    
                    // log trade idea
                    Answers.logCustomEventWithName("Trade Idea", customAttributes: ["Symbol":self.symbol,"User": PFUser.currentUser()?.username ?? "N/A","Description": self.ideaTextView.text,"Installation ID":PFInstallation.currentInstallation().installationId, "App Version": Constants.AppVersion])
                    
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
        
        let parentViewController = self.parentViewController as! UINavigationController
        let parentOfParentViewController  = parentViewController.presentingViewController as! ChartDetailTabBarController
        
        symbol = parentOfParentViewController.symbol
        companyName = parentOfParentViewController.companyName
        stockObject = parentOfParentViewController.chart.parseObject
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if symbol != nil {
            self.ideaTextView.text = "$\(self.symbol) "
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
            
            if symbol != nil {
                ideaTextView.text = "Share an idea on $\(self.symbol)"
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
