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
        
        let sourceViewController: WebViewController = self.source as! WebViewController
        
        let destinationViewController: CardsViewController = self.destination as! CardsViewController

        let frontView = destinationViewController.firstCardView
        
        sourceViewController.dismiss(animated: true, completion: nil)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIViewAnimationOptions(), animations: { () -> Void in
            
            frontView?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            }) { (finished) -> Void in
        }
    }
}
