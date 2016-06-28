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
    
    @IBOutlet private weak var userAvatar: CircularImageView!
    
    @IBOutlet private weak var userName: UILabel!
    
    @IBOutlet private weak var ideaDescription: UITextView!
    
    @IBOutlet private weak var ideaTime: TimeFormattedLabel!
    
    @IBOutlet var nestedTradeIdeaStack: UIStackView!
    
    @IBOutlet var buttonsStack: UIStackView!
    
    @IBOutlet var nestedUserAvatar: CircularImageView!
    
    @IBOutlet var nestedUsername: UILabel!
    
    @IBOutlet var nestedIdeaDescription: SuperUITextView!
    
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
        Functions.findTopViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func reshareButton(sender: UIButton) {
    
        if !sender.selected == true {
            
            let tradeIdeaPostNavigationController = Constants.storyboard.instantiateViewControllerWithIdentifier("TradeIdeaPostNavigationController") as! UINavigationController
            let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.reshareTradeIdea = self.tradeIdea
            ideaPostViewController.delegate =  self

            tradeIdeaPostNavigationController.modalPresentationStyle = .FormSheet
            Functions.findTopViewController()?.presentViewController(tradeIdeaPostNavigationController, animated: true, completion: nil)
        } else {
            registerReshare(sender: sender)
        }
    }
    
    func handleGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.storyboard.instantiateViewControllerWithIdentifier("ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar) {
            profileContainerController.user = self.tradeIdea.user
        } else if (tapGestureRecognizer.view == nestedUserAvatar) {
            profileContainerController.user = self.nestedTradeIdea.user
        }
        
        Functions.findTopViewController()?.showViewController(profileContainerController, sender: self)
    }
    
    func configureIdeaCell(tradeIdea: TradeIdea?) {
        
        guard let tradeIdea = tradeIdea else { return }
        self.tradeIdea = tradeIdea
        
        let user = tradeIdea.user
        self.userName.text = user.username
        
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
        
        checkLike(tradeIdea, sender: self.likeButton)
        checkReshare(tradeIdea, sender: self.reshareButton)
        
        configureNestedTradeIdea(tradeIdea)
        
        // Add Gesture Recognizers
        let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.userAvatar.addGestureRecognizer(tapGestureRecognizerMainAvatar)
        
        let tapGestureRecognizerNestedAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleGestureRecognizer))
        self.nestedUserAvatar.addGestureRecognizer(tapGestureRecognizerNestedAvatar)
    }
    
    func configureNestedTradeIdea(tradeIdea: TradeIdea!) {
        
        guard let object = tradeIdea?.parseObject else { return }
            
        guard let nestedTradeIdeaObject = object.objectForKey("reshare_of") as? PFObject else {
            self.nestedTradeIdeaStack.hidden = true
            return
        }
        
        self.nestedTradeIdeaStack.hidden = false
        
        let user = nestedTradeIdeaObject["user"] as? PFUser
        user?.fetchInBackgroundWithBlock({ (user, error) in
            
            guard let user = user as? PFUser else { return }
            
            self.nestedUsername.text = user.username
            
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
        
        let description = nestedTradeIdeaObject["description"] as! String
        self.nestedIdeaDescription.text = description
        
        self.nestedTradeIdea = TradeIdea(user: nestedTradeIdeaObject["user"] as! PFUser, stock: nestedTradeIdeaObject["stock"] as! PFObject, description: nestedTradeIdeaObject["description"] as! String, likeCount: nestedTradeIdeaObject["liked_by"]?.count, reshareCount: nestedTradeIdeaObject["reshared_by"]?.count, publishedDate: nestedTradeIdeaObject.createdAt, parseObject: nestedTradeIdeaObject)
    }
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        if tradeIdeaTyp == .Reshare {
            self.registerReshare(sender: self.reshareButton)
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        print("ideaDeleted")
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
        
        guard (PFUser.currentUser() != nil) else {
            Functions.isUserLoggedIn(Functions.findTopViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        if let object = tradeIdea.parseObject {
            
            if let liked_by = object["liked_by"] as? [PFUser] {
                if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                    object.removeObject(PFUser.currentUser()!, forKey: "liked_by")
                } else {
                    object.addUniqueObject(PFUser.currentUser()!, forKey: "liked_by")
                }
            } else {
                object.setObject([PFUser.currentUser()!], forKey: "liked_by")
            }
            
            object.saveEventually({ (success, error) -> Void in
                
                self.tradeIdea.likeCount = object["liked_by"]?.count
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let liked_by = object["liked_by"] as? [PFUser] {
                        if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                            sender.selected = true
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
            Functions.isUserLoggedIn(Functions.findTopViewController()!)
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
}

