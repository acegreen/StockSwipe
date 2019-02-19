//
//  NotificationCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class NotificationCell: UITableViewCell {
    
    var activity: Activity!
    
    @IBOutlet var userAvatar: UIImageView!
    @IBOutlet var fullname: UILabel!
    @IBOutlet var notificationDesc: SuperUITextView!
    @IBOutlet var notificationTime: UILabel!
    
    func configureCell(_ activity: Activity?) {
        
        guard let activity = activity else { return }
        self.activity = activity
        
        self.notificationDesc.text = stringForActivityType(activity.activityType)
        self.notificationTime.text = (activity.createdAt as NSDate?)?.formattedAsTimeAgoShort()
        
        guard let user = activity.fromUser as? User else { return }
        self.fullname.text = user.full_name
        
        user.getAvatar { (avatar) in
            DispatchQueue.main.async {
                self.fullname.text = user.full_name
                self.userAvatar.image = avatar
            }
        }
    }
    
    func stringForActivityType(_ activityType: String) -> String? {
        if (activityType == Constants.ActivityType.Follow.rawValue) {
            return "started following you"
        } else if (activityType == Constants.ActivityType.TradeIdeaNew.rawValue) {
            return "shared a new trade idea"
        } else if (activityType == Constants.ActivityType.TradeIdeaLike.rawValue) {
            return "liked your trade idea"
        } else if (activityType == Constants.ActivityType.TradeIdeaReply.rawValue) {
            return "replied to your trade idea"
        } else if (activityType == Constants.ActivityType.TradeIdeaReshare.rawValue) {
            return "reshared on your trade idea"
        } else if (activityType == Constants.ActivityType.Mention.rawValue) {
            return "mentioned you in a trade idea"
        } else {
            return nil
        }
    }
    
    func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == fullname) {
            profileContainerController.user = activity.fromUser
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
}
