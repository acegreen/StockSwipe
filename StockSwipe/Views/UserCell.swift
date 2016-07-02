//
//  UserCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class UserCell: UITableViewCell {
    
    @IBOutlet private weak var userAvatar: UIImageView!
    
    @IBOutlet private weak var username: UILabel!
    
    @IBOutlet private weak var userLocation: UILabel!
    
    var user:PFUser!

    func configureCell(user: PFUser?) {
        
        guard let user = user else { return }
        self.user = user
        
        user.fetchInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            self.username.text = user.username
            
            if let location = user["location"] as? String {
                self.userLocation.text = location
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
            self.username.addGestureRecognizer(tapGestureRecognizerMainUsername)
        })
    }
    
    func handleGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == username) {
            profileContainerController.user = self.user
        }
        
        profileContainerController.navigationItem.rightBarButtonItem = nil
        
        UIApplication.topViewController()?.showViewController(profileContainerController, sender: self)
    }
    
}
