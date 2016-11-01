//
//  NewsTableViewCell.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-05.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit

class NewsCell: UITableViewCell {
    
    @IBOutlet var newsImage: UIImageView!
    
    @IBOutlet var newsTitle: UILabel!
    
    @IBOutlet var newsPublisher: UILabel!
    
    @IBOutlet var newsReleaseDate: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            newsReleaseDate.textAlignment = NSTextAlignment.right
            
        } else {
            
            newsReleaseDate.textAlignment = NSTextAlignment.left
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
