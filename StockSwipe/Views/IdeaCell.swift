//
//  ideaCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class IdeaCell: UITableViewCell, IdeaPostDelegate, SegueHandlerType {
    
    enum SegueIdentifier: String {
        case PostReplySegueIdentifier = "PostReplySegueIdentifier"
        case PostReshareSegueIdentifier = "PostReshareSegueIdentifier"
    }
    
    var delegate: IdeaPostDelegate!
    
    var tradeIdea: TradeIdea!
    var nestedTradeIdea: TradeIdea!
    
    @IBOutlet var userAvatar: UIImageView!
    
    @IBOutlet var userName: UILabel!
    
    @IBOutlet var userTag: UILabel!
    
    @IBOutlet var ideaDescription: UITextView!
    
    @IBOutlet var ideaTime: UILabel!
    
    @IBOutlet var nestedTradeIdeaStack: UIStackView!
    
    @IBOutlet var nestedUserAvatar: UIImageView!
    
    @IBOutlet var nestedUsername: UILabel!
    
    @IBOutlet var nestedUserTag: UILabel!
    
    @IBOutlet var nestedIdeaDescription: SuperUITextView!
    
    @IBOutlet var threeDotsStack: UIStackView!
    
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var likeCountLabel: UILabel!
    
    @IBOutlet var reshareButton: UIButton!
    @IBOutlet var reshareCountLabel: UILabel!
    
    @IBAction func likeButton(sender: UIButton) {
        registerLike(sender: sender)
    }
    
    @IBAction func replyButton(sender: AnyObject) {
        
        let tradeIdeaPostNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("TradeIdeaPostNavigationController") as! UINavigationController
        let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
        
        ideaPostViewController.tradeIdea = self.tradeIdea
        ideaPostViewController.tradeIdeaType = .Reply
        ideaPostViewController.delegate =  self
        
        tradeIdeaPostNavigationController.modalPresentationStyle = .FormSheet
        UIApplication.topViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func reshareButton(sender: UIButton) {
        
        if !sender.selected == true {
            
            let tradeIdeaPostNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("TradeIdeaPostNavigationController") as! UINavigationController
            let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.tradeIdea = self.tradeIdea
            ideaPostViewController.tradeIdeaType = .Reshare
            ideaPostViewController.delegate =  self
            
            tradeIdeaPostNavigationController.modalPresentationStyle = .FormSheet
            UIApplication.topViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
            
        } else {
            registerUnshare(sender: sender)
        }
    }
    
    @IBAction func threeDotsButton(sender: AnyObject) {
        
        guard let viewRect = sender as? UIView else {
            return
        }
        
        let threeDotsAlert = UIAlertController()
        threeDotsAlert.modalPresentationStyle = .Popover
        
        if let currentUser = PFUser.currentUser() where self.tradeIdea.user.objectId != currentUser.objectId  {
            threeDotsAlert.addAction(blockAction(self.tradeIdea.user))
            
            let reportIdea = UIAlertAction(title: "Report", style: .Default) { action in
                
                SweetAlert().showAlert("Report \(self.tradeIdea.user.username!)?", subTitle: "", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor.colorFromRGB(0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(self.tradeIdea.user, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_idea"] = self.tradeIdea.parseObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.Success)
                                })
                                
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                                })
                            }
                        })
                        
                    } else {
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_idea"] = self.tradeIdea.parseObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.Success)
                                })
                                
                            } else {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                                })
                            }
                        })
                    }
                }
            }
            threeDotsAlert.addAction(reportIdea)
        }
        
        if let user = PFUser.currentUser() where self.tradeIdea.user.objectId == user.objectId  {
            let deleteIdea = UIAlertAction(title: "Delete Idea", style: .Default) { action in
                
                QueryHelper.sharedInstance.queryActivityFor(user, toUser: nil, originalTradeIdea: nil, tradeIdea: self.tradeIdea.parseObject, stock: nil, activityType: nil, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObjects = try result()
                        PFObject.deleteAllInBackground(activityObjects)
                        
                    } catch {
                        
                    }
                    
                })
                
                self.tradeIdea.parseObject.deleteEventually()
                self.delegate?.ideaDeleted(with: self.tradeIdea.parseObject)
            }
            threeDotsAlert.addAction(deleteIdea)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { action in
        }
        
        threeDotsAlert.addAction(cancel)
        
        if let presenter = threeDotsAlert.popoverPresentationController {
            presenter.sourceView = viewRect;
            presenter.sourceRect = viewRect.bounds;
        }
        
        UIApplication.topViewController()?.presentViewController(threeDotsAlert, animated: true, completion: nil)
        threeDotsAlert.view.tintColor = Constants.stockSwipeGreenColor
        
    }
    
    func handleGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == userName) {
            profileContainerController.user = User(userObject: self.tradeIdea.user)
        } else if (tapGestureRecognizer.view == nestedUserAvatar || tapGestureRecognizer.view == nestedUsername ) {
            profileContainerController.user = User(userObject: self.nestedTradeIdea.user)
        }
        
        profileContainerController.navigationItem.rightBarButtonItem = nil
        
        UIApplication.topViewController()?.showViewController(profileContainerController, sender: self)
    }
    
    func configureCell(tradeIdea: TradeIdea, timeFormat: Constants.TimeFormat) {
        
        self.tradeIdea = tradeIdea
        
        if let nestedTradeIdeaObject = tradeIdea.parseObject.objectForKey("reshare_of") as? PFObject {
            
            self.nestedTradeIdea = TradeIdea(user: nestedTradeIdeaObject["user"] as! PFUser, description: nestedTradeIdeaObject["description"] as! String, likeCount: nestedTradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: nestedTradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: nestedTradeIdeaObject.createdAt, parseObject: nestedTradeIdeaObject)
        } else {
            self.nestedTradeIdea = nil
        }
        
        configureMainTradeIdea(self.tradeIdea, timeFormat: timeFormat)
        configureNestedTradeIdea(self.nestedTradeIdea)
        
        checkLike(tradeIdea, sender: self.likeButton)
        checkReshare(tradeIdea, sender: self.reshareButton)
        checkMore()
        
        // Add Gesture Recognizers
        let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.userAvatar.addGestureRecognizer(tapGestureRecognizerMainAvatar)
        
        let tapGestureRecognizerMainUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.userName.addGestureRecognizer(tapGestureRecognizerMainUsername)
    }
    
    func configureMainTradeIdea(tradeIdea: TradeIdea!, timeFormat: Constants.TimeFormat) {
        
        let user = tradeIdea.user
        
        user?.fetchIfNeededInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            self.userName.text = user["full_name"] as? String
            self.userTag.text = "@\(user.username!)"
            
            self.ideaDescription.text = tradeIdea.description
            
            switch timeFormat {
            case .Short:
                self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgoShort()
            case .Long:
                self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgo()
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
        })
    }
    
    func configureNestedTradeIdea(nestedTradeIdea: TradeIdea?) {
        
        guard nestedTradeIdeaStack != nil else { return }
        
        guard let nestedTradeIdea = nestedTradeIdea else {
            self.nestedTradeIdeaStack.hidden = true
            return
        }
        
        self.nestedTradeIdeaStack.hidden = false
        
        let user = nestedTradeIdea.user
        user?.fetchIfNeededInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            self.nestedUsername.text = user["full_name"] as? String
            self.nestedUserTag.text = "@\(user.username!)"
            
            if let avatarURL = user.objectForKey("profile_image_url") as? String  {
                
                QueryHelper.sharedInstance.queryWith(avatarURL, completionHandler: { (result) in
                    
                    do {
                        
                        let avatarData  = try result()
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.nestedUserAvatar.image = UIImage(data: avatarData)
                        })
                        
                    } catch {
                        // TODO: Handle error
                    }
                })
            }
        })
        
        self.nestedIdeaDescription.text = nestedTradeIdea.description
        
        let tapGestureRecognizerNestedAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.nestedUserAvatar.addGestureRecognizer(tapGestureRecognizerNestedAvatar)
        
        let tapGestureRecognizerNestedUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.nestedUsername.addGestureRecognizer(tapGestureRecognizerNestedUsername)
    }
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .Reshare {
            self.registerReshare(sender: self.reshareButton)
        }
        
        self.delegate.ideaPosted(with: tradeIdea, tradeIdeaTyp: tradeIdeaTyp)
        
        guard let currentUser = PFUser.currentUser() where currentUser.objectId != self.tradeIdea.user.objectId else { return }
        
        // Send push
        switch tradeIdeaTyp {
        case .New:
            return
            
        case .Reply:
            
            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.tradeIdea.user.objectId!, "tradeIdeaObjectId":tradeIdea.parseObject.objectId!, "checkSetting": "replyTradeIdea_notification", "title": "Trade Idea Reply Notification", "message": "@\(currentUser.username!) replied:\n\(tradeIdea.description)"])
            
        case .Reshare:
            
            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.tradeIdea.user.objectId!, "tradeIdeaObjectId":self.tradeIdea.parseObject.objectId!, "checkSetting": "reshareTradeIdea_notification", "title": "Trade Idea Reshare Notification", "message": "@\(currentUser.username!) reshared:\n\(self.tradeIdea.description)"])
        }
    }
    
    func ideaDeleted(with tradeIdeaObject: PFObject) {
        print("ideaDeleted")
    }
    
    func checkMore() {
        guard let _ = PFUser.currentUser() else {
            
            if threeDotsStack != nil && threeDotsStack.isDescendantOfView(self) {
                threeDotsStack.hidden = true
            }
            return
        }
    }
    
    func checkLike(tradeIdea: TradeIdea!, sender: UIButton?) {
        
        guard let sender = sender else { return }
        guard let currentUser = PFUser.currentUser() else { return }
        
        if let likeCount = self.tradeIdea?.likeCount where likeCount > 0 {
            self.likeCountLabel.text = String(likeCount)
            self.likeCountLabel.hidden = false
        } else {
            self.likeCountLabel.hidden = true
        }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: tradeIdea.parseObject, stock: nil, activityType: Constants.ActivityType.TradeIdeaLike.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result().first
                
                if activityObject != nil {
                    sender.selected = true
                } else {
                    sender.selected = false
                }
                
            } catch {
            }
        })
    }
    
    func registerLike(sender sender: UIButton) {
        
        guard let currentUser = PFUser.currentUser() else {
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        if let tradeIdeaObject = tradeIdea.parseObject {
            
            QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: tradeIdeaObject, stock: nil, activityType: Constants.ActivityType.TradeIdeaLike.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                
                do {
                    
                    let activityObject = try result().first
                    
                    if activityObject != nil {
                        activityObject?.deleteEventually()
                        
                        self.tradeIdea.likeCount -= 1
                        sender.selected = false
                        
                    } else {
                        
                        let activityObject = PFObject(className: "Activity")
                        activityObject["fromUser"] = currentUser
                        activityObject["toUser"] = self.tradeIdea.user
                        activityObject["tradeIdea"] = tradeIdeaObject
                        activityObject["activityType"] = Constants.ActivityType.TradeIdeaLike.rawValue
                        activityObject.saveEventually()
                        
                        self.tradeIdea.likeCount += 1
                        sender.selected = true
                        
                        // Send push
                        if currentUser.objectId != self.tradeIdea.user.objectId {
                            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId":self.tradeIdea.user.objectId!, "tradeIdeaObjectId":self.tradeIdea.parseObject.objectId!, "checkSetting": "likeTradeIdea_notification", "title": "Trade Idea Like Notification", "message": "@\(currentUser.username!) liked:\n\(self.tradeIdea.description)"])
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let likeCount = self.tradeIdea?.likeCount where likeCount > 0 {
                            self.likeCountLabel.text = String(likeCount)
                            self.likeCountLabel.hidden = false
                        } else {
                            self.likeCountLabel.hidden = true
                        }
                    })
                    
                } catch {
                    
                }
            })
        }
    }
    
    func checkReshare(tradeIdea: TradeIdea!, sender: UIButton?) {
        
        guard let sender = sender else { return }
        guard let currentUser = PFUser.currentUser() else { return }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: tradeIdea.parseObject, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.TradeIdeaReshare.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result().first
                
                if activityObject != nil {
                    sender.selected = true
                } else {
                    sender.selected = false
                }
                
            } catch {
                
            }
        })
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                self.reshareCountLabel.text = String(reshareCount)
                self.reshareCountLabel.hidden = false
            } else {
                self.reshareCountLabel.hidden = true
            }
        })
    }
    
    func registerReshare(sender sender: UIButton) {
        
        guard self.tradeIdea != nil else { return }
        
        self.tradeIdea.reshareCount += 1
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            sender.selected = true
            if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                self.reshareCountLabel.text = String(reshareCount)
                self.reshareCountLabel.hidden = false
            } else {
                self.reshareCountLabel.hidden = true
            }
        })
    }
    
    func registerUnshare(sender sender: UIButton) {
        
        guard let currentUser = PFUser.currentUser() else {
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        if let tradeIdeaObject = tradeIdea.parseObject {
            
            QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: self.tradeIdea.user, originalTradeIdea: self.tradeIdea.parseObject, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.TradeIdeaReshare.rawValue, skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                
                do {
                    
                    let activityObject = try result().first
                    
                    if activityObject != nil {
                        activityObject?.deleteEventually()
                        
                        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("reshare_of", object: tradeIdeaObject, skip: 0, limit: 1) { (result) in
                            
                            do {
                                
                                let tradeIdeasObjects = try result().first
                                
                                tradeIdeasObjects?.deleteInBackgroundWithBlock({ (success, error) in
                                    
                                    if success {
                                        
                                        self.delegate?.ideaDeleted(with: tradeIdeasObjects!)
                                        return
                                    }
                                })
                                
                            } catch {
                                
                                // TO-DO: Show sweet alert with Error.message()
                            }
                        }
                        
                        self.tradeIdea.reshareCount -= 1
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            sender.selected = false
                            if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                                self.reshareCountLabel.text = String(reshareCount)
                                self.reshareCountLabel.hidden = false
                            } else {
                                self.reshareCountLabel.hidden = true
                            }
                        })
                        
                    }
                    
                } catch {
                    
                }
            })
        }
    }
    
    func blockAction(user: PFUser) -> UIAlertAction {
        
        let currentUser = PFUser.currentUser()
        
        if let blocked_users = currentUser!["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == user.objectId }) {
            
            let unblockUser = UIAlertAction(title: "Unblock", style: .Default) { action in
                
                currentUser!.removeObject(blockedUser, forKey: "blocked_users")
                
                currentUser!.saveEventually()
            }
            
            return unblockUser
            
        } else {
            
            let blockUser = UIAlertAction(title: "Block", style: .Default) { action in
                
                SweetAlert().showAlert("Block @\(self.tradeIdea.user.username!)?", subTitle: "@\(self.tradeIdea.user.username!) will not be able to follow or view your ideas, and you will not see anything from @\(self.tradeIdea.user.username!)", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.stockSwipeGreenColor, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                    if isOtherButton {
                        Functions.blockUser(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
}

