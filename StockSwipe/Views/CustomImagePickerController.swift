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

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        switch UIDevice.currentDevice().userInterfaceIdiom {
            
        case .Pad:
            return .Landscape
        default:
            return .Portrait
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
