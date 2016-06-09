//
//  TimeFormattedLabel.swift
//  StockSwipe
//
//  Created by Ace Green on 4/5/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import Foundation

class TimeFormattedLabel: UILabel {
    
    override func drawTextInRect(rect: CGRect) {
        
        super.drawTextInRect(rect)
        
        if let timeText = self.text  {
            
            let publishedDateFormatter = NSDateFormatter()
            publishedDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" //EEE, dd MMM yyyy HH:mm:ss z"
            
            if let formattedDate: NSDate = publishedDateFormatter.dateFromString(timeText) {
                self.text = formattedDate.formattedAsTimeAgo()
            }
        }
    }

}
