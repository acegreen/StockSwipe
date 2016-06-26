//
//  ReplyIdeaCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class ReplyIdeaCell: UITableViewCell {
    
    var tradeIdea: TradeIdea!
    
    @IBOutlet private weak var userAvatar: CircularImageView!
    
    @IBOutlet private weak var userName: UILabel!
    
    @IBOutlet private weak var ideaDescription: UITextView!
    
    var user: PFUser!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var contentViewFrame: CGRect = self.contentView.frame
        contentViewFrame.size.width = 320
        self.contentView.frame = contentViewFrame
    }
    
    func configureIdeaCell(tradeIdea: TradeIdea?) {
        
        guard let tradeIdea = tradeIdea else { return }
        self.tradeIdea = tradeIdea
        
        user = tradeIdea.user
        
        self.ideaDescription.text = tradeIdea.description
        
        self.userName.text = user.username
        
        guard let avatarURL = user.objectForKey("profile_image_url") as? String else { return }
        
        QueryHelper.sharedInstance.queryWith(avatarURL, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userAvatar.image = UIImage(data: avatarData)
                })
                
            } catch {
                // TODO: Handle error
            }
        })
    }
}
