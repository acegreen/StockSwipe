//
//  CloudInfoPopoverViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-03.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class CloudInfoPopoverViewController: UIViewController {

    @IBAction func xButtonPressed(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
