//
//  CustomUnwindSegue.swift
//  StockSwipe
//
//  Created by PJ Vea on 7/27/15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class CustomUnwindSegue: UIStoryboardSegue {
    
    override func perform() {
        
        let sourceViewController: WebViewController = self.sourceViewController as! WebViewController
        
        let destinationViewController: CardsViewController = self.destinationViewController as! CardsViewController

        let frontView = destinationViewController.firstCardView
        
        sourceViewController.dismissViewControllerAnimated(true, completion: nil)
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            
            frontView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            
            }) { (finished) -> Void in
        }
    }
}
