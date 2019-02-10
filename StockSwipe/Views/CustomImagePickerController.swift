//
//  CustomImagePickerController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/18/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class CustomImagePickerController: UIImagePickerController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        
        switch UIDevice.current.userInterfaceIdiom {
            
        case .pad:
            return .landscape
        default:
            return .portrait
        }
    }
}
