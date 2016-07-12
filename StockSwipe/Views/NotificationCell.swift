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
    
    var activity: PFObject!
    
    @IBOutlet var userAvatar: UIImageView!
    @IBOutlet var fullname: UILabel!
    @IBOutlet var notificationDesc: SuperUITextView!
    @IBOutlet var notificationTime: UILabel!
    
    func configureCell(activity: PFObject?) {
        
        guard let activity = activity else { return }
        self.activity = activity
        
        self.notificationDesc.text = stringForActivityType(activity.objectForKey("activityType") as! String)
        self.notificationTime.text = activity.createdAt?.formattedAsTimeAgoShort()
        
        let user = activity.objectForKey("fromUser") as! PFUser
        user.fetchIfNeededInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            if let fullname = user["full_name"] as? String {
                self.fullname.text = fullname
            }
            
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
            
            // Add Gesture Recognizers
            let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(UserCell.handleGestureRecognizer))
            self.userAvatar.addGestureRecognizer(tapGestureRecognizerMainAvatar)
            
            let tapGestureRecognizerMainUsername = UITapGestureRecognizer(target: self, action: #selector(UserCell.handleGestureRecognizer))
            self.fullname.addGestureRecognizer(tapGestureRecognizerMainUsername)
        })
    }
    
    func stringForActivityType(activityType: String) -> String? {
        if (activityType == Constants.ActivityType.Follow.rawValue) {
            return "started following you"
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
    
    func handleGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == fullname) {
            profileContainerController.user = User(userObject: self.activity.objectForKey("fromUser") as! PFUser)
        }
        
        profileContainerController.navigationItem.rightBarButtonItem = nil
        
        UIApplication.topViewController()?.showViewController(profileContainerController, sender: self)
    }
}
