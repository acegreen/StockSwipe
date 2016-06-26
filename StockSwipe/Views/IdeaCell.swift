//
//  ideaCell.swift
//  StockSwipe
//
//  Created by Ace Green on 4/4/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

class IdeaCell: UITableViewCell, IdeaPostDelegate {
    
    var delegate: IdeaPostDelegate!
    
    var tradeIdea: TradeIdea!
    
    @IBOutlet private weak var userAvatar: CircularImageView!
    
    @IBOutlet private weak var userName: UILabel!
    
    @IBOutlet private weak var ideaDescription: UITextView!
    
    @IBOutlet private weak var ideaTime: TimeFormattedLabel!
    
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var likeCountLabel: UILabel!
    
    @IBOutlet var reshareButton: UIButton!
    @IBOutlet var reshareCountLabel: UILabel!
    
    @IBAction func likeButton(sender: UIButton) {
        
        registerLike(sender: sender)
        
    }
    
    @IBAction func reshareButton(sender: UIButton) {
        registerReshare(sender: sender)
    }
    
    var user: PFUser!
    
    //    required init?(coder aDecoder: NSCoder) {
    //        super.init(coder: aDecoder)
    //
    //        ideaDescription.delegate = self
    //    }
    
    func configureIdeaCell(tradeIdea: TradeIdea?) {
        
        guard let tradeIdea = tradeIdea else { return }
        self.tradeIdea = tradeIdea
        
        user = tradeIdea.user
        
        self.ideaDescription.text = tradeIdea.description
        self.ideaTime.text = tradeIdea.publishedDate.formattedAsTimeAgo()
        
        checkLike(tradeIdea, sender: self.likeButton)
        checkReshare(tradeIdea, sender: self.reshareButton)
        
        self.userName.text = user.username
        
        guard let avatarURL = user.objectForKey("profile_image_url") as? String else { return }
        
        QueryHelper.sharedInstance.queryWith(avatarURL, completionHandler: { (result) in
            
            do {
                
                let avatarData  = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.userAvatar.image = UIImage(data: avatarData)
                })
                
            } catch {
                
                // Handle error and show sweet alert with error.message()
                
            }
        })
    }
    
    func ideaPosted(with tradeIdea: TradeIdea) {
        print("ideaPosted")
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
                }
            }
            
            if let likeCount = tradeIdea?.likeCount where likeCount > 0 {
                self.likeCountLabel.text = String(likeCount)
                self.likeCountLabel.hidden = false
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
                
                if let liked_by = object["liked_by"] as? [PFUser] {
                    if let _ = liked_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                        sender.selected = true
                    } else {
                        sender.selected = false
                    }
                }
                
                if let likeCount = self.tradeIdea?.likeCount where likeCount > 0 {
                    self.likeCountLabel.text = String(likeCount)
                    self.likeCountLabel.hidden = false
                } else {
                    self.likeCountLabel.hidden = true
                }
            })
        }
        
    }
    
    func checkReshare(tradeIdea: TradeIdea!, sender: UIButton?) {
        
        guard let sender = sender else { return }
        
        if let object = tradeIdea?.parseObject {
            if let reshared_by = object["reshared_by"] as? [PFUser] {
                if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                    sender.selected = true
                }
            }
            
            if let reshareCount = tradeIdea?.reshareCount where reshareCount > 0 {
                self.reshareCountLabel.text = String(reshareCount)
                self.reshareCountLabel.hidden = false
            }
        }
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
                    
                    QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("reshare_of", object: object, skip: 0) { (result) in
                        
                        do {
                            
                            let tradeIdeasObjects = try result().first
                            
                            tradeIdeasObjects?.deleteInBackgroundWithBlock({ (success, error) in
                                
                                if success {
                                    object.removeObject(PFUser.currentUser()!, forKey: "reshared_by")
                                    
                                    object.saveEventually({ (success, error) -> Void in
                                        
                                        self.tradeIdea.reshareCount = object["reshared_by"]?.count
                                        
                                        if let reshared_by = object["reshared_by"] as? [PFUser] {
                                            if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                                                sender.selected = true
                                            } else {
                                                sender.selected = false
                                            }
                                        }
                                        
                                        if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                                            self.reshareCountLabel.text = String(reshareCount)
                                            self.reshareCountLabel.hidden = false
                                        } else {
                                            self.reshareCountLabel.hidden = true
                                        }
                                    })
                                    
                                    self.delegate.ideaDeleted(with: tradeIdeasObjects!)
                                    
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
                
                if let reshared_by = object["reshared_by"] as? [PFUser] {
                    if let _ = reshared_by.find({ $0.objectId == PFUser.currentUser()?.objectId }) {
                        sender.selected = true
                    } else {
                        sender.selected = false
                    }
                }
                
                if let reshareCount = self.tradeIdea?.reshareCount where reshareCount > 0 {
                    self.reshareCountLabel.text = String(reshareCount)
                    self.reshareCountLabel.hidden = false
                } else {
                    self.reshareCountLabel.hidden = true
                }
            })
        }
        
    }
}
