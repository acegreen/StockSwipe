//
//  CustomSegue.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-07-24.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class CustomSegue: UIStoryboardSegue {
    
    override func perform() {
        
        let sourceViewController: CardsViewController = self.source as! CardsViewController
        
        let frontView = sourceViewController.firstCardView
        
        let destinationViewController: WebViewController = self.destination as! WebViewController
        
        let scaleX = sourceViewController.view.frame.width / (frontView?.frame.width)!
        
        let scaleY = sourceViewController.view.frame.height / (frontView?.frame.height)!
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
            
                frontView?.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            
            }) { (finished) -> Void in
                
                sourceViewController.present(destinationViewController as WebViewController, animated: false, completion: nil)
        }
    }
}
