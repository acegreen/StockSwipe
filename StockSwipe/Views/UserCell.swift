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
    
    var user: User! {
        didSet {
            self.fullname.text = self.user.full_name
            self.username.text = user.usertag
            task?.resume()
            self.checkBlock(self.blockButton)
        }
    }
    fileprivate var task: URLSessionTask? {
        guard let profileImageURL = user.profileImageURL else { return nil }
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
    
    @IBOutlet fileprivate weak var userAvatar: UIImageView!
    
    @IBOutlet fileprivate weak var fullname: UILabel!
    
    @IBOutlet fileprivate weak var username: UILabel!
    
    @IBOutlet var blockButton: BlockButton!
    
    @IBAction func blockButton(_ sender: BlockButton) {
        registerBlock(sender)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        self.task?.cancel()
        self.clear()
    }
    
    private func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == username) {
            profileContainerController.user = self.user
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
    
    private func checkBlock(_ sender: BlockButton?) {
        
        guard let sender = sender else { return }
        
        guard let currentUser = PFUser.current() else { return }
        guard let user = self.user else { return }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] , blocked_users.find({ $0.objectId == user.objectId }) != nil {
            sender.buttonState = BlockButton.state.blocked
            return
        }
    }
    
    private func registerBlock(_ sender: BlockButton) {
        
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
    
    private func clear() {
        self.userAvatar.image = UIImage(named: "dummy_profile_male")!
        self.fullname.text = "John Doe"
        self.username.text = "@JohnDoe"
    }
}
