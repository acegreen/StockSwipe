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
    
    var user: User!
    
    @IBOutlet fileprivate weak var userAvatar: UIImageView!
    
    @IBOutlet fileprivate weak var fullname: UILabel!
    
    @IBOutlet fileprivate weak var username: UILabel!
    
    @IBOutlet var blockButton: BlockButton!
    
    @IBAction func blockButton(_ sender: BlockButton) {
        registerBlock(sender)
    }

    func configureCell(with user: User) {
        
        self.user = user
        self.user.getAvatar({ (image) in
            DispatchQueue.main.async {
                self.fullname.text = self.user.full_name
                self.username.text = self.user.username
                self.userAvatar.image = image
            }
        })
        
        self.checkBlock(self.blockButton)
    }
    
    func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == username) {
            profileContainerController.user = self.user
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
    
    func checkBlock(_ sender: BlockButton?) {
        
        guard let sender = sender else { return }
        
        guard let currentUser = PFUser.current() else { return }
        guard let user = self.user else { return }
        
        print(currentUser["blocked_users"] as? [PFUser])
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] , blocked_users.find({ $0.objectId == user.objectId }) != nil {
            sender.buttonState = BlockButton.state.blocked
            return
        }
    }
    
    func registerBlock(_ sender: BlockButton) {
        
        guard let currentUser = PFUser.current() else { return }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == user.objectId })   {
            
            currentUser.remove(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                sender.buttonState = BlockButton.state.unblocked
            })
            return
        }
    
        Functions.blockUser(self.user, postAlert: true)
    }
}
