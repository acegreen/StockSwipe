//
//  ideaCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class LikedIdeaCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet private weak var userAvatar: CircularImageView!
    
    @IBOutlet private weak var ideaUser: UILabel!
    
    @IBOutlet private weak var ideaDescription: UITextView!
    
    @IBOutlet private weak var ideaTime: TimeFormattedLabel!
    
    func configureIdeaCell(tradeIdea: TradeIdea!) {
        
        let user = tradeIdea.user
        
        self.ideaDescription.text = tradeIdea.description
        self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgo()
        
        self.ideaUser.text = user.username!
        
        let avatarURL = user.objectForKey("profile_image_url") as! String
        
        QueryHelper.sharedInstance.queryWith(avatarURL, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userAvatar.image = UIImage(data: avatarData)
                })
                
            } catch {
                
                // Handle error and show sweet alert with error.message()
                
            }
        })
    }
}
