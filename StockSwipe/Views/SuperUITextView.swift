//
//  SuperUITextView.swift
//  StockSwipe
//
//  Created by Ace Green on 6/21/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class SuperUITextView: UITextView, UITextViewDelegate, DetectTags {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }

    override var text: String? {
        didSet {
            self.resolveTags()
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top
        
        // find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length - 1 {
            // if the character is a link, handle the tap as UITextView normally would
            if (self.textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                return self
            }
        }
        
        // otherwise return nil so the tap goes on to the next receiver
        return nil
    }
    
    // TextView Delegates
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        
        let resourceSpecifier = (URL as NSURL).resourceSpecifier
        
        switch URL.scheme {
        case "cash"?:
            
            guard let resourceSpecifier = resourceSpecifier else { return false }
            
            Functions.makeCard(for: resourceSpecifier) { card in
                do {
                    let card = try card()
                    
                    let cardDetailViewController  = Constants.Storyboards.cardDetailStoryboard.instantiateViewController(withIdentifier: "CardDetailViewController") as! CardDetailViewController
                    cardDetailViewController.card = card
                    cardDetailViewController.forceDisableDragDownToDismiss = true
                    
                    DispatchQueue.main.async {
                        UIApplication.topViewController()?.present(cardDetailViewController, animated: true, completion: nil)
                    }
                } catch {
                    if let error = error as? QueryHelper.QueryError {
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
            }
            
        case "mention"?:
            
            guard let resourceSpecifier = resourceSpecifier else { return false }
            
            QueryHelper.sharedInstance.queryUserObjectsFor(usernames: [resourceSpecifier], completion: { (result) in
                
                do {
                    let userObject = try result().first
                    if let userObject = userObject {
                        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
                        profileContainerController.user = User(userObject: userObject)
                        
                        UIApplication.topViewController()?.show(profileContainerController, sender: self)
                    }
                    
                } catch {
                    if let error = error as? QueryHelper.QueryError {
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
            })
            
        case "hash"?:
            SweetAlert().showAlert("Coming Soon!", subTitle: "hashtags will be supported soon", style: AlertStyle.warning)
            
        default:
            Functions.presentSafariBrowser(with: URL)
        }
        
        return false
    }
}
