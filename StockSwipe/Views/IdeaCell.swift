//
//  ideaCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class IdeaCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet private weak var userAvatar: CircularImageView!
    
    @IBOutlet private weak var userName: UILabel!
    
    @IBOutlet private weak var ideaDescription: UITextView!
    
    @IBOutlet private weak var ideaTime: TimeFormattedLabel!
    
    var user: PFUser!
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        
//        ideaDescription.delegate = self
//    }
    
    func configureIdeaCell(tradeIdea: TradeIdea?) {
        
        guard let tradeIdea = tradeIdea else { return }
        
        user = tradeIdea.user
        
        self.ideaDescription.text = tradeIdea.description
        self.ideaDescription.resolveTags()
        
        self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgo()
        
        self.userName.text = user.username
        
        guard let avatarURL = user.objectForKey("profile_image_url") as? String else { return }
        
        QueryHelper.sharedInstance.queryWith(avatarURL, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userAvatar.image = UIImage(data: avatarData)
                })
                
            } catch {
                
                // Handle error and show sweet alert with error.message()
                
            }
        })
    }
    
    // TextView Delegates
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        
        switch URL.scheme {
        case "cash" :
            
            let chartDetailTabBarController  = Constants.storyboard.instantiateViewControllerWithIdentifier("ChartDetailTabBarController") as! ChartDetailTabBarController
            
            chartDetailTabBarController.symbol = URL.resourceSpecifier
            
            Functions.findTopViewController()?.presentViewController(chartDetailTabBarController, animated: true, completion: nil)
            
        case "mention" :
            
            QueryHelper.sharedInstance.queryUserObjectFor(URL.resourceSpecifier, completion: { (result) in
                
                do {
                    
                    let userObject = try result()
                    
                    let profileNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileNavigationController") as! UINavigationController
                    let profileContainerController = profileNavigationController.topViewController as! ProfileContainerController
                    profileContainerController.user = userObject
                                        
                    Functions.findTopViewController()?.presentViewController(profileNavigationController, animated: true, completion: nil)
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                        })
                    }
                }
            })
        
        default:
            Functions.presentSafariBrowser(URL)
        }
        
        return false
    }
}
