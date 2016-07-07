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
        
        ideaPostViewController.replyTradeIdea = self.tradeIdea
        ideaPostViewController.delegate =  self
        
        tradeIdeaPostNavigationController.modalPresentationStyle = .FormSheet
        UIApplication.topViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func reshareButton(sender: UIButton) {
        
        if !sender.selected == true {
            
            let tradeIdeaPostNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("TradeIdeaPostNavigationController") as! UINavigationController
            let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.reshareTradeIdea = self.tradeIdea
            ideaPostViewController.delegate =  self
            
            tradeIdeaPostNavigationController.modalPresentationStyle = .FormSheet
            UIApplication.topViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
        } else {
            registerReshare(sender: sender)
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
                        
                        self.handleBlock(self.tradeIdea.user, postAlert: false)
                        
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

                if let resharedOf = self.tradeIdea.parseObject.objectForKey("reshare_of") as? PFObject {
                    
                    if let reshared_by = resharedOf["reshared_by"] as? [PFUser] {
                        if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                            resharedOf.removeObject(PFUser.currentUser()!, forKey: "reshared_by")
                            resharedOf.saveEventually()
                        }
                    }
                }
                
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
    
    func configureCell(tradeIdea: TradeIdea) {
        
        self.tradeIdea = tradeIdea
    
        if let nestedTradeIdeaObject = self.tradeIdea.parseObject.objectForKey("reshare_of") as? PFObject {
            
            self.nestedTradeIdea = TradeIdea(user: nestedTradeIdeaObject["user"] as! PFUser, stock: nestedTradeIdeaObject["stock"] as! PFObject, description: nestedTradeIdeaObject["description"] as! String, likeCount: nestedTradeIdeaObject["liked_by"]?.count, reshareCount: nestedTradeIdeaObject["reshared_by"]?.count, publishedDate: nestedTradeIdeaObject.createdAt, parseObject: nestedTradeIdeaObject)
        }
        
        configureMainTradeIdea(self.tradeIdea)
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
    
    func configureMainTradeIdea(tradeIdea: TradeIdea!) {
        
        let user = tradeIdea.user
        
        user?.fetchIfNeededInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            self.userName.text = user["full_name"] as? String
            self.userTag.text = "@\(user.username!)"
            
            self.ideaDescription.text = tradeIdea.description
            self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgo()
            
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
            
            PFCloud.callFunctionInBackground("pushNotificationToUser", withParameters: ["userObjectId":self.tradeIdea.user.objectId!, "checkSetting": "replyTradeIdea_notification", "title": "Trade Idea Reply", "message": "@\(currentUser.username!) replied to a trade idea you posted"]) { (results, error) -> Void in
            }
            
        case .Reshare:
            
            PFCloud.callFunctionInBackground("pushNotificationToUser", withParameters: ["userObjectId":self.tradeIdea.user.objectId!, "checkSetting": "reshareTradeIdea_notification", "title": "Trade Idea Reshare:", "message": "@\(currentUser.username!) reshared your trade idea for $\(self.tradeIdea.stock["Symbol"])"]) { (results, error) -> Void in
            }
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
        
        if let object = tradeIdea?.parseObject {
            if let liked_by = object["liked_by"] as? [PFUser] {
                if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                    sender.selected = true
                } else {
                    sender.selected = false
                }
            } else {
                sender.selected = false
            }
            
            if let likeCount = tradeIdea?.likeCount where likeCount > 0 {
                self.likeCountLabel.text = String(likeCount)
                self.likeCountLabel.hidden = false
            } else {
                self.likeCountLabel.hidden = true
            }
        }
    }
    
    func registerLike(sender sender: UIButton) {
        
        guard let currentUser = PFUser.currentUser() else {
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        if let object = tradeIdea.parseObject {
            
            if let liked_by = object["liked_by"] as? [PFUser] {
                if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                    object.removeObject(currentUser, forKey: "liked_by")
                } else {
                    object.addUniqueObject(currentUser, forKey: "liked_by")
                }
            } else {
                object.setObject([currentUser], forKey: "liked_by")
            }
            
            object.saveEventually({ (success, error) -> Void in
                
                self.tradeIdea.likeCount = object["liked_by"]?.count
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let liked_by = object["liked_by"] as? [PFUser] {
                        if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                            sender.selected = true
                            
                            // Send push
                            if currentUser.objectId != self.tradeIdea.user.objectId {
                                PFCloud.callFunctionInBackground("pushNotificationToUser", withParameters: ["userObjectId":self.tradeIdea.user.objectId!, "checkSetting": "likeTradeIdea_notification", "title": "Trade Idea Reply", "message": "@\(currentUser.username!) liked a trade idea you posted"]) { (results, error) -> Void in
                                }
                            }
                        } else {
                            sender.selected = false
                        }
                    } else {
                        sender.selected = false
                    }
                    
                    if let likeCount = self.tradeIdea?.likeCount where likeCount > 0 {
                        self.likeCountLabel.text = String(likeCount)
                        self.likeCountLabel.hidden = false
                    } else {
                        self.likeCountLabel.hidden = true
                    }
                })
            })
        }
    }
    
    func checkReshare(tradeIdea: TradeIdea!, sender: UIButton?) {
        
        guard let sender = sender else { return }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let object = tradeIdea?.parseObject {
                if let reshared_by = object["reshared_by"] as? [PFUser] {
                    if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                        sender.selected = true
                    } else {
                        sender.selected = false
                    }
                } else {
                    sender.selected = false
                }
                
                if let reshareCount = tradeIdea?.reshareCount where reshareCount > 0 {
                    self.reshareCountLabel.text = String(reshareCount)
                    self.reshareCountLabel.hidden = false
                } else {
                    self.reshareCountLabel.hidden = true
                }
            }
        })
    }
    
    func registerReshare(sender sender: UIButton) {
        
        guard (PFUser.currentUser() != nil) else {
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        if let object = tradeIdea.parseObject {
            
            if let reshared_by = object["reshared_by"] as? [PFUser] {
                if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                    
                    QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("reshare_of", object: object, skip: 0, limit: 1) { (result) in
                        
                        do {
                            
                            let tradeIdeasObjects = try result().first
                            
                            tradeIdeasObjects?.deleteInBackgroundWithBlock({ (success, error) in
                                
                                if success {
                                    object.removeObject(PFUser.currentUser()!, forKey: "reshared_by")
                                    
                                    object.saveEventually({ (success, error) -> Void in
                                        
                                        self.tradeIdea.reshareCount = object["reshared_by"]?.count
                                        
                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                            
                                            if let reshared_by = object["reshared_by"] as? [PFUser] {
                                                if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                                                    sender.selected = true
                                                } else {
                                                    sender.selected = false
                                                }
                                            } else {
                                                sender.selected = false
                                            }
                                            
                                            if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                                                self.reshareCountLabel.text = String(reshareCount)
                                                self.reshareCountLabel.hidden = false
                                            } else {
                                                self.reshareCountLabel.hidden = true
                                            }
                                        })
                                    })
                                    
                                    self.delegate?.ideaDeleted(with: tradeIdeasObjects!)
                                    return
                                }
                            })
                            
                        } catch {
                            
                            // TO-DO: Show sweet alert with Error.message()
                        }
                    }
                } else {
                    object.addUniqueObject(PFUser.currentUser()!, forKey: "reshared_by")
                }
            } else {
                object.setObject([PFUser.currentUser()!], forKey: "reshared_by")
            }
            
            object.saveEventually({ (success, error) -> Void in
                
                self.tradeIdea.reshareCount = object["reshared_by"]?.count
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let reshared_by = object["reshared_by"] as? [PFUser] {
                        if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                            sender.selected = true
                        } else {
                            sender.selected = false
                        }
                    } else {
                        sender.selected = false
                    }
                    
                    if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                        self.reshareCountLabel.text = String(reshareCount)
                        self.reshareCountLabel.hidden = false
                    } else {
                        self.reshareCountLabel.hidden = true
                    }
                })
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
                        self.handleBlock(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
    
    func handleBlock(user: PFUser, postAlert: Bool) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        
        if currentUser.objectForKey("blocked_users") != nil {
            
            currentUser.addUniqueObject(user, forKey: "blocked_users")
            
        } else {
            
            currentUser.setObject([user], forKey: "blocked_users")
        }
        
        currentUser.saveEventually { (success, error) in
            
            if success {
                
                if postAlert == true {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        SweetAlert().showAlert("Blocked", subTitle: "", style: AlertStyle.Success)
                    })
                }
                
                QueryHelper.sharedInstance.queryUserActivityFor(currentUser, toUser: user) { (result) in
                    
                    do {
                        
                        let userActivityObject = try result()
                        
                        userActivityObject?.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                }
                
                QueryHelper.sharedInstance.queryUserActivityFor(user, toUser: currentUser) { (result) in
                    
                    do {
                        
                        let userActivityObject = try result()
                        
                        userActivityObject?.first?.deleteEventually()
                        
                    } catch {
                        
                        // TO-DO: handle error
                        
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.Warning)
                })
            }
        }
    }
}

