//
//  TutorialContentViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-10-10.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class TutorialContentViewController: UIViewController {
    
    var pageIndex: Int!
    var imageFile: String!

    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = UIImage(named: self.imageFile)
    }
}
