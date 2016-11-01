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
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        
        let resourceSpecifier = (URL as NSURL).resourceSpecifier
        
        switch URL.scheme {
        case "cash"?:
            
            guard let resourceSpecifier = resourceSpecifier else { return false }
            
            let chartDetailTabBarController  = Constants.mainStoryboard.instantiateViewController(withIdentifier: "ChartDetailTabBarController") as! ChartDetailTabBarController
            
            QueryHelper.sharedInstance.queryStockObjectsFor(symbols: [resourceSpecifier]) { (result) in
                
                do {
                    
                    let stockObject = try result().first!
                    
                    let chart = Chart(parseObject: stockObject)
                    
                    chartDetailTabBarController.chart = chart
                    UIApplication.topViewController()?.present(chartDetailTabBarController, animated: true, completion: nil)
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
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
                        
                        let profileNavigationController = Constants.mainStoryboard.instantiateViewController(withIdentifier: "ProfileNavigationController") as! UINavigationController
                        let profileContainerController = profileNavigationController.topViewController as! ProfileContainerController
                        profileContainerController.user = User(userObject: userObject)
                        
                        UIApplication.topViewController()?.present(profileNavigationController, animated: true, completion: nil)

                    }
                    
                } catch {
                    
                    if let error = error as? Constants.Errors {
                        
                        DispatchQueue.main.async {
                            SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.warning)
                        }
                    }
                }
            })
            
        case "hash"?:
            SweetAlert().showAlert("Coming Soon!", subTitle: "hashtags will be supported soon", style: AlertStyle.warning)
            
        default:
            Functions.presentSafariBrowser(URL)
        }
        
        return false
    }
}
