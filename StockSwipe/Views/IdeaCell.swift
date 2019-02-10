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
    var nestedTradeIdea: TradeIdea?
    
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
    
    @IBAction func likeButton(_ sender: UIButton) {
        registerLike(on: sender)
    }
    
    @IBAction func replyButton(_ sender: AnyObject) {
        
        let tradeIdeaPostNavigationController = Constants.Storyboards.mainStoryboard.instantiateViewController(withIdentifier: "TradeIdeaPostNavigationController") as! UINavigationController
        let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
        
        ideaPostViewController.originalTradeIdea = self.tradeIdea
        ideaPostViewController.tradeIdeaType = .reply
        ideaPostViewController.delegate =  self
        
        tradeIdeaPostNavigationController.modalPresentationStyle = .formSheet
        UIApplication.topViewController()?.present(tradeIdeaPostNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func reshareButton(_ sender: UIButton) {
        
        if !sender.isSelected == true {
            
            let tradeIdeaPostNavigationController = Constants.Storyboards.mainStoryboard.instantiateViewController(withIdentifier: "TradeIdeaPostNavigationController") as! UINavigationController
            let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.originalTradeIdea = self.tradeIdea
            ideaPostViewController.tradeIdeaType = .reshare
            ideaPostViewController.delegate =  self
            
            tradeIdeaPostNavigationController.modalPresentationStyle = .formSheet
            UIApplication.topViewController()?.present(tradeIdeaPostNavigationController, animated: true, completion: nil)
            
        } else {
            registerUnshare(sender: sender)
        }
    }
    
    @IBAction func threeDotsButton(_ sender: AnyObject) {
        
        guard let viewRect = sender as? UIView else {
            return
        }
        
        let threeDotsAlert = UIAlertController()
        threeDotsAlert.modalPresentationStyle = .popover
        
        if let currentUser = PFUser.current() , self.tradeIdea.user.objectId != currentUser.objectId  {
            threeDotsAlert.addAction(blockAction(self.tradeIdea.user.userObject))
            
            let reportIdea = UIAlertAction(title: "Report", style: .default) { action in
                
                SweetAlert().showAlert("Report \(self.tradeIdea.user.username!)?", subTitle: "", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor(rgbValue: 0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.SSColors.green) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(self.tradeIdea.user.userObject, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_idea"] = self.tradeIdea.parseObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async {
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.success)
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                                }
                            }
                        })
                        
                    } else {
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_idea"] = self.tradeIdea.parseObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async {
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.success)
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                                }
                            }
                        })
                    }
                }
            }
            threeDotsAlert.addAction(reportIdea)
        }
        
        if let user = PFUser.current() , self.tradeIdea.user.objectId == user.objectId  {
            let deleteIdea = UIAlertAction(title: "Delete Idea", style: .default) { action in
                
                QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self.tradeIdea.parseObject, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue, Constants.ActivityType.TradeIdeaLike.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.Mention.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                    
                    do {
                        
                        let activityObjects = try result()
                        PFObject.deleteAll(inBackground: activityObjects)
                        
                    } catch {
                        //TODO: handle error
                    }
                })
                
                self.tradeIdea.parseObject.deleteEventually()
                self.delegate?.ideaDeleted(with: self.tradeIdea.parseObject)
            }
            threeDotsAlert.addAction(deleteIdea)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
        }
        
        threeDotsAlert.addAction(cancel)
        
        if let presenter = threeDotsAlert.popoverPresentationController {
            presenter.sourceView = viewRect;
            presenter.sourceRect = viewRect.bounds;
        }
        
        UIApplication.topViewController()?.present(threeDotsAlert, animated: true, completion: nil)
        threeDotsAlert.view.tintColor = Constants.SSColors.green
    }
    
    @objc func handleProfileGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == userName) {
            profileContainerController.user = self.tradeIdea.user
        } else if (tapGestureRecognizer.view == nestedUserAvatar || tapGestureRecognizer.view == nestedUsername ) {
            profileContainerController.user = self.nestedTradeIdea?.user
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
    
    @objc func handleTradeIdeaGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let tradeIdeaDetailTableViewController = Constants.Storyboards.tradeIdeaStoryboard.instantiateViewController(withIdentifier: "TradeIdeaDetailTableViewController") as! TradeIdeaDetailTableViewController
        tradeIdeaDetailTableViewController.tradeIdea = self.nestedTradeIdea
        
        UIApplication.topViewController()?.show(tradeIdeaDetailTableViewController, sender: self)
    }
    
    func configureCell(with tradeIdea: TradeIdea, timeFormat: Constants.TimeFormat) {
        
        self.tradeIdea = tradeIdea
        self.configureMain(tradeIdea, timeFormat: timeFormat)
        
        self.nestedTradeIdea = self.tradeIdea.nestedTradeIdea
        self.configureNested(self.nestedTradeIdea)
        
        self.checkLike(self.tradeIdea, sender: self.likeButton)
        self.checkReshare(self.tradeIdea, sender: self.reshareButton)
        self.checkMore()
    }
    
    func configureMain(_ tradeIdea: TradeIdea!, timeFormat: Constants.TimeFormat) {
        
        if !tradeIdea.ideaDescription.isEmpty {
            self.ideaDescription.text = tradeIdea.ideaDescription
        } else {
            self.ideaDescription = nil
        }
        
        let nsPublishedDate = tradeIdea.createdAt as NSDate
        switch timeFormat {
        case .short:
            self.ideaTime.text = nsPublishedDate.formattedAsTimeAgoShort()
        case .long:
            self.ideaTime.text = nsPublishedDate.formattedAsTimeAgo()
        }
        
        tradeIdea.user.fetchUserIfNeeded { (user) in
            
            self.userName.text = tradeIdea.user.fullname
            
            if self.userTag != nil {
                self.userTag.text = tradeIdea.user.username
            }
            
            tradeIdea.user.getAvatar({ (image) in
                DispatchQueue.main.async {
                    self.userAvatar.image = image
                }
            })
            
            // Add Gesture Recognizers
            let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleProfileGestureRecognizer))
            self.userAvatar.addGestureRecognizer(tapGestureRecognizerMainAvatar)
            
            let tapGestureRecognizerMainUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleProfileGestureRecognizer))
            self.userName.addGestureRecognizer(tapGestureRecognizerMainUsername)
        }
    }
    
    func configureNested(_ nestedTradeIdea: TradeIdea?) {
        
        guard nestedTradeIdeaStack != nil else { return }
        
        guard let nestedTradeIdea = nestedTradeIdea else {
            self.nestedTradeIdeaStack.isHidden = true
            return
        }
        
        self.nestedTradeIdeaStack.isHidden = false
        
        if !nestedTradeIdea.ideaDescription.isEmpty {
            self.nestedIdeaDescription.text = nestedTradeIdea.ideaDescription
        } else {
            self.nestedIdeaDescription = nil
        }
        
        nestedTradeIdea.user.fetchUserIfNeeded { (user) in
            
            self.nestedUsername.text = nestedTradeIdea.user.fullname
            
            if self.nestedUserTag != nil {
                self.nestedUserTag.text = nestedTradeIdea.user.username
            }
            
            nestedTradeIdea.user.getAvatar({ (image) in
                DispatchQueue.main.async {
                    self.nestedUserAvatar.image = image
                }
            })
            
            let tapGestureRecognizerNestedUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleTradeIdeaGestureRecognizer(_:)))
            self.nestedTradeIdeaStack.addGestureRecognizer(tapGestureRecognizerNestedUsername)
        }
    }
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .reshare {
            registerReshare(on: self.reshareButton)
        }
        
        guard let currentUser = PFUser.current() , currentUser.objectId != self.tradeIdea.user.objectId else { return }
        
        // Send push
        switch tradeIdeaTyp {
        case .new:
            
            return
            
        case .reply:
            
            #if DEBUG
                print("send push didn't happen in debug")
            #else
                Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.tradeIdea.user.objectId!, "tradeIdeaObjectId":tradeIdea.parseObject.objectId!, "checkSetting": "replyTradeIdea_notification", "title": "Trade Idea Reply Notification", "message": "@\(currentUser.username!) replied:\n" + tradeIdea.ideaDescription])
            #endif
            
        case .reshare:
            
            #if DEBUG
                print("send push didn't happen in debug")
            #else
                Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.tradeIdea.user.objectId!, "tradeIdeaObjectId":self.tradeIdea.parseObject.objectId!, "checkSetting": "reshareTradeIdea_notification", "title": "Trade Idea Reshare Notification", "message": "@\(currentUser.username!) reshared:\n" + self.tradeIdea.ideaDescription])
            #endif
        }
        
        self.delegate?.ideaPosted(with: tradeIdea, tradeIdeaTyp: tradeIdeaTyp)
    }
    
    func ideaDeleted(with tradeIdeaObject: PFObject) {
        print("ideaDeleted")
        
        self.delegate?.ideaDeleted(with: tradeIdeaObject)
    }
    
    func ideaUpdated(with tradeIdea: TradeIdea) {
        print("ideaModified")
        
        self.delegate?.ideaUpdated(with: tradeIdea)
    }
    
    func checkMore() {
        guard let _ = PFUser.current() else {
            
            if threeDotsStack != nil && threeDotsStack.isDescendant(of: self) {
                threeDotsStack.isHidden = true
            }
            return
        }
    }
    
    func checkLike(_ tradeIdea: TradeIdea, sender: UIButton?) {
        
        guard let sender = sender else { return }
        
        tradeIdea.checkNumberOfLikes { (likes) in
            if likes > 0 {
                self.likeCountLabel.text = String(likes.suffixNumber())
                self.likeCountLabel.isHidden = false
            } else {
                self.likeCountLabel.isHidden = true
            }
            
            sender.isSelected = tradeIdea.isLikedByCurrentUser
        }
    }
    
    func registerLike(on sender: UIButton) {
        
        guard let currentUser = PFUser.current() else {
            Functions.isUserLoggedIn(presenting: UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }

        sender.isEnabled = false
        
        if let tradeIdeaObject = tradeIdea.parseObject {
            
            QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: tradeIdeaObject, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                
                do {
                    
                    let activityObject = try result().first
                    
                    if activityObject != nil {
                        
                        activityObject?.deleteInBackground(block: { (success, error) in
                            
                            if self.tradeIdea.likeCount > 1 {
                                self.tradeIdea.likeCount -= 1
                            }
                            self.tradeIdea.isLikedByCurrentUser = false
                            self.updateLike(sender: sender)
                        })
                        
                    } else {
                        
                        let activityObject = PFObject(className: "Activity")
                        activityObject["fromUser"] = currentUser
                        activityObject["toUser"] = self.tradeIdea.user.userObject
                        activityObject["tradeIdea"] = tradeIdeaObject
                        activityObject["activityType"] = Constants.ActivityType.TradeIdeaLike.rawValue
                        activityObject.saveEventually({ (success, error) in
                            
                            if success {
                                self.tradeIdea.likeCount += 1
                                self.tradeIdea.isLikedByCurrentUser = true
                                
                                self.updateLike(sender: sender)
                                
                                // Send push
                                if currentUser.objectId != self.tradeIdea.user.objectId {
                                    
                                    #if DEBUG
                                        print("send push didn't happen in debug")
                                    #else
                                        Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId":self.tradeIdea.user.objectId!, "tradeIdeaObjectId":self.tradeIdea.parseObject.objectId!, "checkSetting": "likeTradeIdea_notification", "title": "Trade Idea Like Notification", "message": "@\(currentUser.username!) liked:\n" + self.tradeIdea.ideaDescription])
                                    #endif
                                }
                            }
                        })
                    }
                    
                } catch {
                    //TODO: handle error
                }
            })
        }
    }
    
    func updateLike(sender: UIButton) {
        
        DispatchQueue.main.async {
            if self.tradeIdea.likeCount > 0 {
                self.likeCountLabel.text = String(self.tradeIdea.likeCount)
                self.likeCountLabel.isHidden = false
            } else {
                self.likeCountLabel.isHidden = true
            }
            
            sender.isEnabled = true
            sender.isSelected = self.tradeIdea.isLikedByCurrentUser
            
            self.delegate?.ideaUpdated(with: self.tradeIdea)
        }
    }
    
    func checkReshare(_ tradeIdea: TradeIdea, sender: UIButton?) {
        
        guard let sender = sender else { return }
        
        tradeIdea.checkNumberOfReshares { (reshares) in
            
            if reshares > 0 {
                self.reshareCountLabel.text = String(reshares.suffixNumber())
                self.reshareCountLabel.isHidden = false
            } else {
                self.reshareCountLabel.isHidden = true
            }
            
            sender.isSelected = tradeIdea.isResharedByCurrentUser
        }
    }
    
    func registerReshare(on sender: UIButton) {
        
        guard self.tradeIdea != nil else { return }
        
        self.tradeIdea.reshareCount += 1
        self.tradeIdea.isResharedByCurrentUser = true

        self.updateReshare(sender: sender)
    }
    
    func registerUnshare(sender: UIButton) {
        
        guard let currentUser = PFUser.current() else {
            Functions.isUserLoggedIn(presenting: UIApplication.topViewController()!)
            return
        }
        
        guard self.tradeIdea != nil else { return }
        
        sender.isEnabled = false
        
        if let tradeIdeaObject = tradeIdea.parseObject {
            
            QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: self.tradeIdea.user.userObject, originalTradeIdea: self.tradeIdea.parseObject, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
                
                do {
                    
                    let activityObject = try result().first
                    
                    if activityObject != nil {
                        activityObject?.deleteInBackground(block: { (success, error) in
                            
                            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "reshare_of", object: tradeIdeaObject, skip: 0, limit: 1) { (result) in
                                
                                do {
                                    
                                    let tradeIdeasObjects = try result().first
                                    
                                    tradeIdeasObjects?.deleteInBackground(block: { (success, error) in
                                        
                                        if success {
                                            
                                            self.delegate?.ideaDeleted(with: tradeIdeasObjects!)
                                            return
                                        }
                                    })
                                    
                                } catch {
                                    //TODO: Show sweet alert with Error.message()
                                }
                            }
                            
                            if self.tradeIdea.reshareCount > 1 {
                                self.tradeIdea.reshareCount -= 1
                            }
                            self.tradeIdea.isResharedByCurrentUser = false
                            self.updateReshare(sender: sender)
                        })
                    }
                    
                } catch {
                    //TODO: handle error
                }
            })
        }
    }
    
    func updateReshare(sender: UIButton) {
    
        DispatchQueue.main.async {
            if let reshareCount = self.tradeIdea?.reshareCount , reshareCount > 0 {
                self.reshareCountLabel.text = String(reshareCount)
                self.reshareCountLabel.isHidden = false
            } else {
                self.reshareCountLabel.isHidden = true
            }
            
            sender.isSelected = self.tradeIdea.isResharedByCurrentUser
            
            self.delegate?.ideaUpdated(with: self.tradeIdea)
        }
    }
    
    func blockAction(_ user: PFUser) -> UIAlertAction {
        
        let currentUser = PFUser.current()
        
        if let blocked_users = currentUser!["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == user.objectId }) {
            
            let unblockUser = UIAlertAction(title: "Unblock", style: .default) { action in
                
                currentUser!.remove(blockedUser, forKey: "blocked_users")
                
                currentUser!.saveEventually()
            }
            
            return unblockUser
            
        } else {
            
            let blockUser = UIAlertAction(title: "Block", style: .default) { action in
                
                SweetAlert().showAlert("Block @\(self.tradeIdea.user.username!)?", subTitle: "@\(self.tradeIdea.user.username!) will not be able to follow or view your ideas, and you will not see anything from @\(self.tradeIdea.user.username!)", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.SSColors.green, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                    if isOtherButton {
                        Functions.blockUser(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
}

