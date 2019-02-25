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
    
    var activity: Activity!
    
    @IBOutlet var userAvatar: UIImageView!
    
    @IBOutlet var userName: UILabel!
    
    @IBOutlet var userTag: UILabel!
    
    @IBOutlet var ideaDescription: UITextView!
    
    @IBOutlet var ideaTime: UILabel!
    
    @IBOutlet var nestedTradeIdeaView: UIView!
    
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
        
        ideaPostViewController.activity = self.activity
        ideaPostViewController.tradeIdeaType = .reply
        ideaPostViewController.delegate =  self
        
        tradeIdeaPostNavigationController.modalPresentationStyle = .formSheet
        UIApplication.topViewController()?.present(tradeIdeaPostNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func reshareButton(_ sender: UIButton) {
        
        if !sender.isSelected == true {
            
            let tradeIdeaPostNavigationController = Constants.Storyboards.mainStoryboard.instantiateViewController(withIdentifier: "TradeIdeaPostNavigationController") as! UINavigationController
            let ideaPostViewController = tradeIdeaPostNavigationController.viewControllers.first as! IdeaPostViewController
            
            ideaPostViewController.activity = self.activity
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
        
        guard let activity = activity else { return }
        
        let threeDotsAlert = UIAlertController()
        threeDotsAlert.modalPresentationStyle = .popover
        
        if let currentUser = User.current() , activity.fromUser.objectId != currentUser.objectId  {
            threeDotsAlert.addAction(blockAction(activity.fromUser))
            
            let reportIdea = UIAlertAction(title: "Report", style: .default) { action in
                
                SweetAlert().showAlert("Report \(activity.fromUser.username!)?", subTitle: "", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor(rgbValue: 0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.SSColors.green) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(self.activity.fromUser, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_idea"] = self.activity
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
                        spamObject["reported_idea"] = self.activity.tradeIdea
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
        
        if let user = User.current(), self.activity.fromUser.objectId == user.objectId  {
            let deleteIdea = UIAlertAction(title: "Delete Idea", style: .default) { action in
                
//                QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self.activity.tradeIdea, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue, Constants.ActivityType.TradeIdeaLike.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.Mention.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
//                    
//                    do {
//                        
//                        let activityObjects = try result()
//                        PFObject.deleteAll(inBackground: activityObjects)
//                        
//                    } catch {
//                        //TODO: handle error
//                    }
//                })
                
                self.activity.deleteEventually()
                self.activity.tradeIdea?.deleteEventually()
                self.delegate?.ideaDeleted(with: self.activity)
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
    
    func configureCell(with activity: Activity, timeFormat: Constants.TimeFormat) {
        
        self.activity = activity
        self.configureMain(activity.tradeIdea, user: activity.fromUser, timeFormat: timeFormat)
        self.configureNested(activity.originalTradeIdea)
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        self.checkLike(tradeIdea, sender: self.likeButton)
        self.checkReshare(tradeIdea, sender: self.reshareButton)
        self.checkMore()
    }
    
    func configureMain(_ tradeIdea: TradeIdea?, user: User?, timeFormat: Constants.TimeFormat) {
        
        guard let tradeIdea = tradeIdea else { return }
        
        if !tradeIdea.ideaDescription.isEmpty {
            self.ideaDescription.text = tradeIdea.ideaDescription
        } else {
            self.ideaDescription.text = nil
        }
        
        let nsPublishedDate = tradeIdea.createdAt as! NSDate
        switch timeFormat {
        case .short:
            self.ideaTime.text = nsPublishedDate.formattedAsTimeAgoShort()
        case .long:
            self.ideaTime.text = nsPublishedDate.formattedAsTimeAgo()
        }
        
        guard let user =  user else {
            return
        }
        DispatchQueue.main.async {
            self.userName.text = user.full_name
            if self.userTag != nil {
                self.userTag.text = user.usertag
            }
        }
        user.getAvatar({ (avatar) in
            DispatchQueue.main.async {
                self.userAvatar.image = avatar
            }
        })
        
        // Add Gesture Recognizers
        let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleProfileGestureRecognizer))
        self.userAvatar.addGestureRecognizer(tapGestureRecognizerMainAvatar)

        let tapGestureRecognizerUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleProfileGestureRecognizer))
        self.userName.addGestureRecognizer(tapGestureRecognizerUsername)
    }
    
    func configureNested(_ nestedTradeIdea: TradeIdea?) {
        
        guard nestedTradeIdeaView != nil else { return }
        
        guard let nestedTradeIdea = nestedTradeIdea, Constants.ActivityType(rawValue: activity.activityType) != .TradeIdeaReply else {
            self.nestedTradeIdeaView.isHidden = true
            return
        }
        
        self.nestedTradeIdeaView.isHidden = false
        
        if !nestedTradeIdea.ideaDescription.isEmpty {
            self.nestedIdeaDescription.text = nestedTradeIdea.ideaDescription
        } else {
            self.nestedIdeaDescription = nil
        }
        
        nestedTradeIdea.user.fetchIfNeededInBackground { (user, error) in
            guard let user = user as? User else { return }
            DispatchQueue.main.async {
                self.nestedUsername.text = nestedTradeIdea.user.full_name
                if self.nestedUserTag != nil {
                    self.nestedUserTag.text = nestedTradeIdea.user.username
                }
            }
            user.getAvatar({ (avatar) in
                DispatchQueue.main.async {
                    self.nestedUserAvatar.image = avatar
                }
            })
            
            let tapGestureRecognizerNestedUsername = UITapGestureRecognizer(target: self, action: #selector(IdeaCell.handleTradeIdeaGestureRecognizer(_:)))
            self.nestedTradeIdeaView.addGestureRecognizer(tapGestureRecognizerNestedUsername)
        }
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
        
        tradeIdea.checkNumberOfLikes { likeCount in
            DispatchQueue.main.async {
                guard let sender = sender else { return }
                
                if tradeIdea.likeCount > 0 {
                    self.likeCountLabel.text = String(tradeIdea.likeCount.suffixNumber())
                    self.likeCountLabel.isHidden = false
                } else {
                    self.likeCountLabel.isHidden = true
                }
                
                sender.isSelected = tradeIdea.isLikedByCurrentUser
            }
        }
    }
    
    func registerLike(on sender: UIButton) {
        
        guard let currentUser = PFUser.current() else {
            Functions.isUserLoggedIn(presenting: UIApplication.topViewController()!)
            return
        }
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        sender.isEnabled = false
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdeas: nil, tradeIdeas: [tradeIdea], stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result().first
                
                if activityObject != nil {
                    
                    activityObject?.deleteInBackground(block: { (success, error) in
                        self.activity.tradeIdea?.likeCount -= 1
                        self.activity.tradeIdea?.isLikedByCurrentUser = false
                        self.updateLike(sender: sender)
                    })
                    
                } else {
                    
                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["toUser"] = self.activity.fromUser
                    activityObject["tradeIdea"] = self.activity.tradeIdea
                    activityObject["activityType"] = Constants.ActivityType.TradeIdeaLike.rawValue
                    activityObject.saveEventually({ (success, error) in
                        
                        if success {
                            self.activity.tradeIdea?.likeCount += 1
                            self.activity.tradeIdea?.isLikedByCurrentUser = true
                            self.updateLike(sender: sender)
                            
                            guard let tradeIdea = self.activity.tradeIdea else { return }
                            
                            // Send push
                            if currentUser.objectId != self.activity.fromUser.objectId {
                                
                                #if DEBUG
                                print("send push didn't happen in debug")
                                #else
                                Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.activity.fromUser.objectId!, "tradeIdeaObjectId": tradeIdea.objectId!, "checkSetting": "likeTradeIdea_notification", "title": "Trade Idea Like Notification", "message": "@\(currentUser.username!) liked:\n" + tradeIdea.ideaDescription])
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
    
    func updateLike(sender: UIButton) {
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        
        DispatchQueue.main.async {
            if tradeIdea.likeCount > 0 {
                self.likeCountLabel.text = String(tradeIdea.likeCount.suffixNumber())
                self.likeCountLabel.isHidden = false
            } else {
                self.likeCountLabel.isHidden = true
            }
            
            sender.isEnabled = true
            sender.isSelected = tradeIdea.isLikedByCurrentUser
            
            self.delegate?.ideaUpdated(with: self.activity)
        }
    }
    
    func checkReshare(_ tradeIdea: TradeIdea, sender: UIButton?) {
        
        tradeIdea.checkNumberOfReshares { (reshares) in
            DispatchQueue.main.async {
                if reshares > 0 {
                    self.reshareCountLabel.text = String(reshares.suffixNumber())
                    self.reshareCountLabel.isHidden = false
                } else {
                    self.reshareCountLabel.isHidden = true
                }
                
                sender?.isSelected = tradeIdea.isResharedByCurrentUser
            }
        }
    }
    
    func registerReshare(on sender: UIButton) {
        
        self.activity.tradeIdea?.reshareCount += 1
        self.activity.tradeIdea?.isResharedByCurrentUser = true
        
        self.updateReshare(sender: sender)
    }
    
    func registerUnshare(sender: UIButton) {
        
        guard let currentUser = User.current() else {
            Functions.isUserLoggedIn(presenting: UIApplication.topViewController()!)
            return
        }
        
        guard let tradeIdea = self.activity.tradeIdea else { return }
        sender.isEnabled = false
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: self.activity.fromUser, originalTradeIdeas: [tradeIdea], tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                guard let activityObject = try result().first as? Activity else { return }

                activityObject.deleteInBackground(block: { (success, error) in
                    QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "tradeIdea", object: self.activity.originalTradeIdea, skip: nil, limit: 1) { (result) in
                        
                        do {
                            
                            let tradeIdeasObjects = try result().first
                            tradeIdeasObjects?.deleteInBackground(block: { (success, error) in
                                
                                if success {
                                    self.delegate?.ideaDeleted(with: activityObject)
                                    self.delegate?.ideaUpdated(with: self.activity)
                                    return
                                }
                            })
                            
                        } catch {
                            //TODO: Show sweet alert with Error.message()
                        }
                    }
                    
                    if let tradeIdea = self.activity.tradeIdea, tradeIdea.reshareCount > 0 {
                        self.activity.tradeIdea?.reshareCount -= 1
                    }
                    self.activity.tradeIdea?.isResharedByCurrentUser = false
                    self.updateReshare(sender: sender)
                })
                
            } catch {
                //TODO: handle error
            }
        })
    }
    
    func updateReshare(sender: UIButton) {
        
        DispatchQueue.main.async {
            if let reshareCount = self.activity.tradeIdea?.reshareCount, reshareCount > 0 {
                self.reshareCountLabel.text = String(reshareCount.suffixNumber())
                self.reshareCountLabel.isHidden = false
            } else {
                self.reshareCountLabel.isHidden = true
            }
            
            sender.isEnabled = true
            sender.isSelected = self.activity.tradeIdea?.isResharedByCurrentUser ?? false
            
            self.delegate?.ideaUpdated(with: self.activity)
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
                
                SweetAlert().showAlert("Block @\(self.activity.fromUser.username!)?", subTitle: "@\(self.activity.fromUser.username!) will not be able to follow or view your ideas, and you will not see anything from @\(self.activity.fromUser.username!)", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.SSColors.green, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                    if isOtherButton {
                        Functions.blockUser(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
    
    // MARK: IdeaPostDelegate
    
    func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        if tradeIdeaTyp == .reshare {
            registerReshare(on: self.reshareButton)
        }
        
        self.delegate?.ideaPosted(with: activity, tradeIdeaTyp: tradeIdeaTyp)
        
        guard let currentUser = User.current() , currentUser.objectId != self.activity.fromUser.objectId else { return }
        
        // Send push
        
        guard let tradeIdea = activity.tradeIdea else { return }
        
        switch tradeIdeaTyp {
        case .new:
            
            return
            
        case .reply:
            
            #if DEBUG
            print("send push didn't happen in debug")
            #else
            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": tradeIdea.user.objectId!, "tradeIdeaObjectId": tradeIdea.objectId!, "checkSetting": "replyTradeIdea_notification", "title": "Trade Idea Reply Notification", "message": "@\(currentUser.username!) replied:\n" + tradeIdea.ideaDescription])
            #endif
            
        case .reshare:
            
            #if DEBUG
            print("send push didn't happen in debug")
            #else
            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": tradeIdea.user.objectId!, "tradeIdeaObjectId": tradeIdea.objectId!, "checkSetting": "reshareTradeIdea_notification", "title": "Trade Idea Reshare Notification", "message": "@\(currentUser.username!) reshared:\n" + tradeIdea.ideaDescription])
            #endif
        }
    }
    
    func ideaDeleted(with activity: Activity) {
        print("ideaDeleted")
        
        self.delegate?.ideaDeleted(with: activity)
    }
    
    func ideaUpdated(with activity: Activity) {
        print("ideaModified")
        
        self.delegate?.ideaUpdated(with: activity)
    }
    
    // MAKR: Gesture
    
    @objc func handleProfileGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let profileContainerController = Constants.Storyboards.profileStoryboard.instantiateViewController(withIdentifier: "ProfileContainerController") as! ProfileContainerController
        
        if (tapGestureRecognizer.view == userAvatar || tapGestureRecognizer.view == userName) {
            profileContainerController.user = self.activity.fromUser
        }
        
        UIApplication.topViewController()?.show(profileContainerController, sender: self)
    }
    
    @objc func handleTradeIdeaGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        let tradeIdeaDetailTableViewController = Constants.Storyboards.tradeIdeaStoryboard.instantiateViewController(withIdentifier: "TradeIdeaDetailTableViewController") as! TradeIdeaDetailTableViewController
        
        guard let originalTradeIdea = self.activity.originalTradeIdea else { return }
        QueryHelper.sharedInstance.queryActivityFor(fromUser: originalTradeIdea.user, toUser: nil, originalTradeIdeas: nil, tradeIdeas: [originalTradeIdea], stocks: nil, activityType: nil, skip: nil, limit: 1, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], selectKeys: nil, order: .descending, completion: { (result) in
            
            do {
                
                guard let activityObject = try result().first as? Activity else { return }
                tradeIdeaDetailTableViewController.activity = activityObject
                
                DispatchQueue.main.async {
                    UIApplication.topViewController()?.show(tradeIdeaDetailTableViewController, sender: self)
                }
            } catch {
                // TODO: handle error
            }
        })
    }
}

