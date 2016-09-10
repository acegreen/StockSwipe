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
    
    // TextView Delegates
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        
        switch URL.scheme {
        case "cash":
            
            let chartDetailTabBarController  = Constants.storyboard.instantiateViewControllerWithIdentifier("ChartDetailTabBarController") as! ChartDetailTabBarController
            
            QueryHelper.sharedInstance.queryStockObjectsFor([URL.resourceSpecifier]) { (result) in
                
                do {
                    
                    let stockObject = try result().first!
                    
                    let chart = Chart(parseObject: stockObject)
                    
                    chartDetailTabBarController.chart = chart
                    UIApplication.topViewController()?.presentViewController(chartDetailTabBarController, animated: true, completion: nil)
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                        })
                    }
                }
            }
            
        case "mention":
            
            QueryHelper.sharedInstance.queryUserObjectsFor([URL.resourceSpecifier], completion: { (result) in
                
                do {
                    
                    let userObject = try result().first
                    
                    if let userObject = userObject {
                        
                        let profileNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileNavigationController") as! UINavigationController
                        let profileContainerController = profileNavigationController.topViewController as! ProfileContainerController
                        profileContainerController.user = User(userObject: userObject)
                        
                        UIApplication.topViewController()?.presentViewController(profileNavigationController, animated: true, completion: nil)
                    }
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                        })
                    }
                }
            })
            
        case "hash":
            SweetAlert().showAlert("Coming Soon!", subTitle: "hashtags will be supported soon", style: AlertStyle.Warning)
            
        default:
            Functions.presentSafariBrowser(URL)
        }
        
        return false
    }
}
