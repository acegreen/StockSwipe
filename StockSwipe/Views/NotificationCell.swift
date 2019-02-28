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
    
    var activity: Activity! {
        didSet {
            self.fullname.text = activity.fromUser.full_name
            self.notificationDesc.text = stringForActivityType(activity.activityType)
            self.notificationTime.text = (activity.createdAt as NSDate?)?.formattedAsTimeAgoShort()
            task?.resume()
        }
    }
    fileprivate var task: URLSessionTask? {
        guard let profileImageURL = activity.fromUser.profileImageURL else { return nil }
        return URLSession.shared.dataTask(with: profileImageURL) { (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.userAvatar.image = image
                } else {
                    self.userAvatar.image = UIImage(named: "dummy_profile_male")!
                }
            }
        }
    }
    
    @IBOutlet var userAvatar: UIImageView!
    @IBOutlet var fullname: UILabel!
    @IBOutlet var notificationDesc: SuperUITextView!
    @IBOutlet var notificationTime: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        self.task?.cancel()
        self.clear()
    }
    
    private func stringForActivityType(_ activityType: String) -> String? {
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
    
    private func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == fullname) {
            profileContainerController.user = activity.fromUser
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
    
    private func clear() {
        self.userAvatar.image = UIImage(named: "dummy_profile_male")!
        self.fullname.text = "John Doe"
        self.notificationDesc.text = "Notification Description"
        self.notificationTime.text = "Just now"
    }
}
