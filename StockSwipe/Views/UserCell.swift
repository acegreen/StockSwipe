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
    
    var user: PFUser!
    
    @IBOutlet private weak var userAvatar: UIImageView!
    
    @IBOutlet private weak var fullname: UILabel!
    
    @IBOutlet private weak var username: UILabel!
    
    @IBOutlet var blockButton: BlockButton!
    
    @IBAction func blockButton(sender: BlockButton) {
        registerBlock(sender)
    }

    func configureCell(user: PFUser?) {
        
        guard let user = user else { return }
        self.user = user
        
        user.fetchIfNeededInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            if let fullname = user["full_name"] as? String {
                self.fullname.text = fullname
            }
            
            if let username = user.username {
                 self.username.text = "@\(username)"
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
            
            self.checkBlock(self.blockButton)
        })
    }
    
    func handleGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == username) {
            profileContainerController.user = User(userObject: self.user)
        }
        
        profileContainerController.navigationItem.rightBarButtonItem = nil
        
        UIApplication.topViewController()?.showViewController(profileContainerController, sender: self)
    }
    
    func checkBlock(sender: BlockButton?) {
        
        guard let sender = sender else { return }
        
        guard let currentUser = PFUser.currentUser() else { return }
        guard let user = self.user else { return }
        
        print(currentUser["blocked_users"] as? [PFUser])
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] where blocked_users.find({ $0.objectId == user.objectId }) != nil {
            sender.buttonState = BlockButton.state.Blocked
            return
        }
    }
    
    func registerBlock(sender: BlockButton) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == user.objectId })   {
            
            currentUser.removeObject(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                sender.buttonState = BlockButton.state.Unblocked
            })
            return
        }
        
        if currentUser.objectForKey("blocked_users") != nil {
            
            currentUser.addUniqueObject(user, forKey: "blocked_users")
            
        } else {
            
            currentUser.setObject([user], forKey: "blocked_users")
        }
        
        currentUser.saveEventually { (success, error) in
            
            if success {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Blocked", subTitle: "", style: AlertStyle.Success)
                })
                
                sender.buttonState = .Blocked
                
                QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: self.user, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: nil, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
                QueryHelper.sharedInstance.queryActivityFor(self.user, toUser: currentUser, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: nil, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObject = try result()
                        activityObject.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                })
            }
        }
    }
}
