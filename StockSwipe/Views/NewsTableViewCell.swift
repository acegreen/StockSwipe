//
//  NewsTableViewCell.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet var newsImage: UIImageView!
    
    @IBOutlet var newsTitle: UILabel!
    
    @IBOutlet var newsPublisher: UILabel!
    
    @IBOutlet var newsReleaseDate: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            
            newsReleaseDate.textAlignment = NSTextAlignment.Right
            
        } else {
            
            newsReleaseDate.textAlignment = NSTextAlignment.Left
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
