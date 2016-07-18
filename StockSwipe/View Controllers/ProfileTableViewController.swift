//
//  ProfileViewController.swift
//  TwitterProfileClone
//
//  Created by Sean Robertson on 3/16/15.
//  Copyright (c) 2015 Sean Robertson. All rights reserved.
//

import UIKit
import Parse
import DZNEmptyDataSet

protocol ProfileTableVieDelegate {
    func subScrollViewDidScroll(scrollView: UIScrollView)
    func didReloadProfileTableView()
}

class ProfileTableViewController: UITableViewController, CellType, SubSegmentedControlDelegate, SegueHandlerType, LoginDelegate {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
        case UserCell = "UserCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case ProfileSegueIdentifier = "ProfileSegueIdentifier"
        case SettingsSegueIdentifier = "SettingsSegueIdentifier"
        case EditProfileSegueIdentifier = "EditProfileSegueIdentifier"
    }
    
    var delegate: ProfileTableVieDelegate!
    
    var user: User?
    var isCurrentUserBlocked: Bool = false
    var isUserBlocked: Bool = false
    var shouldShowProfileAnyway: Bool = true
    
    var tradeIdeas = [TradeIdea]()
    var followingUsers = [PFUser]()
    var followersUsers = [PFUser]()
    var likedTradeIdeas = [TradeIdea]()
    var tradeIdeaQueryLimit = 25
    
    var isQueryingForTradeIdeas = true
    var isQueryingForFollowing = true
    var isQueryingForFollowers = true
    var isQueryingForLikedTradeIdeas = true
    
    var selectedSegmentIndex: ProfileContainerController.SegmentIndex = ProfileContainerController.SegmentIndex(rawValue: 0)!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var avatarImage:UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    
    @IBOutlet var profileButtonsStack: UIStackView!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var followButton: FollowButton!
    @IBOutlet var editProfileButton: UIButton!
    
    @IBAction func settingsButton(sender: AnyObject) {
        
        guard let viewRect = sender as? UIView else {
            return
        }
        
        guard let currentUser = PFUser.currentUser() else { return }
        guard let user = self.user else { return }
        
        if user.userObject.objectId == currentUser.objectId  {
            self.performSegueWithIdentifier(.SettingsSegueIdentifier, sender: self)
            return
        }
        
        let settingsAlert = UIAlertController()
        settingsAlert.modalPresentationStyle = .Popover
        if user.userObject.objectId != currentUser.objectId  {
            
            settingsAlert.addAction(blockAction(user.userObject))
            
            let reportIdea = UIAlertAction(title: "Report", style: .Default) { action in
                
                SweetAlert().showAlert("Report \(user.userObject.username!)?", subTitle: "", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor.colorFromRGB(0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(user.userObject, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_user"] = user.userObject
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
                        spamObject["reported_user"] = user.userObject
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
            settingsAlert.addAction(reportIdea)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { action in
        }
        
        settingsAlert.addAction(cancel)
        
        if let presenter = settingsAlert.popoverPresentationController {
            presenter.sourceView = viewRect;
            presenter.sourceRect = viewRect.bounds;
        }
        
        UIApplication.topViewController()?.presentViewController(settingsAlert, animated: true, completion: nil)
        settingsAlert.view.tintColor = Constants.stockSwipeGreenColor
        
    }
    
    @IBAction func followButtonPressed(sender: FollowButton) {
        self.registerFollow(sender)
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        
        getProfile()
        
        switch selectedSegmentIndex {
        case .Zero, .Three:
            Functions.setupConfigParameter("TRADEIDEAQUERYLIMIT") { (parameterValue) -> Void in
                self.tradeIdeaQueryLimit = parameterValue as? Int ?? 25
                self.getUserTradeIdeas()
            }
        case .One:
            getUsersFollowing()
        case .Two:
            getUsersFollowers()
        }
        
        self.delegate?.didReloadProfileTableView()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableView properties
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0
        
        checkProfileSettings()
        getProfile()
        getUserTradeIdeas()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    func subDidSelectSegment(segmentedControl: UISegmentedControl) {
        
        selectedSegmentIndex = ProfileContainerController.SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
        
        switch selectedSegmentIndex {
        case .Zero:
            if tradeIdeas.count == 0 {
                self.getUserTradeIdeas()
            }
        case .One:
            if followingUsers.count == 0 {
                getUsersFollowing()
            }
        case .Two:
            if followersUsers.count == 0 {
                getUsersFollowers()
            }
        case .Three:
            if likedTradeIdeas.count == 0 {
                self.getUserTradeIdeas()
            }
        }
        self.tableView.reloadData()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.delegate.subScrollViewDidScroll(scrollView)
    }
    
    func checkProfileSettings() {
        if user?.userObject.objectId == PFUser.currentUser()?.objectId {
            followButton.hidden = true
            editProfileButton.hidden = false
        }
        profileButtonsStack.sizeToFit()
    }
    
    func getProfile() {
        
        guard let user = user else { return }
        
        checkFollow(self.followButton)
        
        if let profileImageURL = user.userObject.objectForKey("profile_image_url") as? String {
            
            QueryHelper.sharedInstance.queryWith(profileImageURL, completionHandler: { (result) in
                
                do {
                    
                    let imageData = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let profileImage = UIImage(data: imageData)
                        self.avatarImage.image = profileImage
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    
                }
            })
        }
        
        if let fullName = user.userObject.objectForKey("full_name") as? String {
            self.fullNameLabel.text = fullName
        }
        
        if let username = user.userObject.username  {
            self.usernameLabel.text = "@\(username)"
        }
    }
    
    func getUserTradeIdeas() {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user?.userObject else { return }
        
        switch selectedSegmentIndex {
        case .Zero:
            
            isQueryingForTradeIdeas = true
            
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: userObject, skip: 0, limit: self.tradeIdeaQueryLimit) { (result) in
                
                self.isQueryingForTradeIdeas = false
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    self.tradeIdeas = []
                    for tradeIdeaObject: PFObject in tradeIdeasObjects {
                        
                        let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: tradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                        
                        self.tradeIdeas.append(tradeIdea)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                }
            }
            
        case .One:
            return
        case .Two:
            return
        case .Three:
            
            isQueryingForLikedTradeIdeas = true
            
            QueryHelper.sharedInstance.queryActivityFor(userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: 0, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
                
                self.isQueryingForLikedTradeIdeas = false

                do {
                    
                    let activityObjects = try result()
                    
                    self.likedTradeIdeas = []
                    for activityObject: PFObject in activityObjects {
                        
                        if let tradeIdeaObject = activityObject.objectForKey("tradeIdea") as? PFObject {
                        
                            let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: tradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                            
                            self.likedTradeIdeas.append(tradeIdea)
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                }
            })
        }
    }
    
    func loadMoreTradeIdeas() {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if self.refreshControl?.refreshing == false && !self.footerActivityIndicator.isAnimating() {
            self.footerActivityIndicator.startAnimating()
        }
        
        switch selectedSegmentIndex {
        case .Zero:
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: userObject, skip: tradeIdeas.count, limit: self.tradeIdeaQueryLimit) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        for tradeIdeaObject: PFObject in tradeIdeasObjects {
                            
                            let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: tradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                            
                            //add datasource object here for tableview
                            self.tradeIdeas.append(tradeIdea)
                            
                            //now insert cell in tableview
                            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.tradeIdeas.count - 1, inSection: 0)], withRowAnimation: .None)
                        }
                        
                        if self.footerActivityIndicator?.isAnimating() == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if self.footerActivityIndicator?.isAnimating() == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                }
            }
        case .One:
            return
        case .Two:
            return
        case .Three:
            
            QueryHelper.sharedInstance.queryActivityFor(userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: likedTradeIdeas.count, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
                
                do {
                    
                    let activityObjects = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        for activityObject: PFObject in activityObjects {
                            
                            if let tradeIdeaObject = activityObject.objectForKey("tradeIdea") as? PFObject {
                                
                                let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["likeCount"] as? Int ?? 0, reshareCount: tradeIdeaObject["reshareCount"] as? Int ?? 0, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                                
                                //add datasource object here for tableview
                                self.likedTradeIdeas.append(tradeIdea)
                                
                                //now insert cell in tableview
                                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.likedTradeIdeas.count - 1, inSection: 0)], withRowAnimation: .None)
                            }
                        }
                        
                        if self.footerActivityIndicator?.isAnimating() == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if self.footerActivityIndicator?.isAnimating() == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                }
            })
        }
    }
    
    func getUsersFollowing() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        isQueryingForFollowing = true

        QueryHelper.sharedInstance.queryActivityFor(user.userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            self.isQueryingForFollowing = false
            
            do {
                
                let activityObjects = try result()
                
                self.followingUsers = []
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    for activityObject in activityObjects {
                        let toUser = activityObject["toUser"] as! PFUser
                        self.followingUsers.append(toUser)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                })
                
            } catch {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        })
    }
    
    func getUsersFollowers() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        isQueryingForFollowers = true

        QueryHelper.sharedInstance.queryActivityFor(nil, toUser: user.userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            self.isQueryingForFollowers = false

            do {
                
                let activityObjects = try result()
                
                self.followersUsers = []
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    for activityObject in activityObjects {
                        let fromUser = activityObject["fromUser"] as! PFUser
                        self.followersUsers.append(fromUser)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        if self.refreshControl?.refreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                })
                
            } catch {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        })
    }
    
    func checkFollow(sender: FollowButton) {
        
        guard user?.userObject.objectId != PFUser.currentUser()?.objectId else { return }
        
        guard let currentUser = PFUser.currentUser() else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] where users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.Disabled
            self.isCurrentUserBlocked = true
            self.shouldShowProfileAnyway = false
            self.tableView.reloadEmptyDataSet()
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] where blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            sender.buttonState = FollowButton.state.Blocked
            self.isUserBlocked = true
            self.tableView.reloadEmptyDataSet()
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result()
                
                if activityObject.first != nil {
                    sender.buttonState = FollowButton.state.Following
                } else {
                    sender.buttonState = FollowButton.state.NotFollowing
                }
                
            } catch {
            }
        })
    }
    
    func registerFollow(sender: FollowButton) {
        
        guard user?.userObject.objectId != PFUser.currentUser()?.objectId else {
            followButton.hidden = true
            return
        }
        
        guard let currentUser = PFUser.currentUser() else {
            let logInViewcontroller = LoginViewController.sharedInstance
            logInViewcontroller.loginDelegate = self
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] where users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.Disabled
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == userObject.objectId }) {
            
            currentUser.removeObject(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                if success {
                    sender.buttonState = FollowButton.state.NotFollowing
                }
            })
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil) { (result) in
            
            do {
                
                let activityObject = try result()
                
                if activityObject.first == nil {
                    
                    let activityObject = PFObject(className: "Activity")
                    activityObject["fromUser"] = currentUser
                    activityObject["toUser"] = userObject
                    activityObject["activityType"] = Constants.ActivityType.Follow.rawValue
                    
                    activityObject.saveInBackgroundWithBlock({ (success, error) in
                        
                        if success {
                            sender.buttonState = FollowButton.state.Following
                            
                            // Send push
                            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId":userObject.objectId!, "checkSetting": "follower_notification", "title": "Follower Notification", "message": "@\(currentUser.username!) is now following you"])
                            
                        } else {
                            sender.buttonState = FollowButton.state.NotFollowing
                        }
                    })
                } else {
                    activityObject.first?.deleteEventually()
                    sender.buttonState = FollowButton.state.NotFollowing
                }
                
            } catch {
                
                // TO-DO: handle error
                
            }
        }
        
    }
    
    func didLoginSuccessfully() {
        self.getProfile()
    }
    
    func didLogoutSuccessfully() {
        self.getProfile()
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \(NSDate().formattedAsTimeAgo())"
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            switch selectedSegmentIndex {
            case .Zero:
                self.loadMoreTradeIdeas()
            case .One:
                getUsersFollowing()
            case .Two:
                getUsersFollowers()
            case .Three:
                self.loadMoreTradeIdeas()
            }
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
                
                SweetAlert().showAlert("Block @\(user.username!)?", subTitle: "@\(user.username!) will not be able to follow or view your ideas, and you will not see anything from @\(user.username!)", style: AlertStyle.Warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.stockSwipeGreenColor, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                    if isOtherButton {
                        Functions.blockUser(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            
            let destinationViewController = segue.destinationViewController as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.tradeIdea = cell.tradeIdea
            
        case .ProfileSegueIdentifier:
            let profileContainerController = segue.destinationViewController as! ProfileContainerController
            profileContainerController.navigationItem.rightBarButtonItem = nil
            
            guard let cell = sender as? UserCell  else { return }
            profileContainerController.user = User(userObject: cell.user)
        case .EditProfileSegueIdentifier:
            
            let navigationController = segue.destinationViewController as! UINavigationController
            let profileDetailViewController = navigationController.viewControllers.first as! ProfileDetailTableViewController
            
            profileDetailViewController.user = self.user
            
            break
        case .SettingsSegueIdentifier:
            break
        }
    }
}

extension ProfileTableViewController: IdeaPostDelegate {
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        self.tradeIdeas.insert(tradeIdea, atIndex: 0)
        
        if selectedSegmentIndex == .Zero && self.user?.userObject.objectId == PFUser.currentUser()?.objectId {
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            
            if selectedSegmentIndex == .Zero && self.user?.userObject.objectId == PFUser.currentUser()?.objectId {
                if let reshareOf = tradeIdea.parseObject.objectForKey("reshare_of") as? PFObject, let reshareTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == reshareOf.objectId })  {
                    
                    let indexPath = NSIndexPath(forRow: self.tradeIdeas.indexOf(reshareTradeIdea)!, inSection: 0)
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
                
                let indexPath = NSIndexPath(forRow: self.tradeIdeas.indexOf(tradeIdea)!, inSection: 0)
                self.tradeIdeas.removeObject(tradeIdea)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                
                if tradeIdeas.count == 0 {
                    self.tableView.reloadEmptyDataSet()
                }
            }
        }
    }
}

extension ProfileTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch selectedSegmentIndex {
        case .Zero:
            return tradeIdeas.count
        case .One:
            return followingUsers.count
        case .Two:
            return followersUsers.count
        case .Three:
            return likedTradeIdeas.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch selectedSegmentIndex {
        case .Zero:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(tradeIdeas[indexPath.row], timeFormat: .Short)
            cell.delegate = self
            return cell
        case .One:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(followingUsers[indexPath.row])
            return cell
        case .Two:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(followersUsers[indexPath.row])
            return cell
        case .Three:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(likedTradeIdeas[indexPath.row], timeFormat: .Short)
            cell.delegate = self
            return cell
        }
    }
    
    // DZNEmptyDataSet delegate functions
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        
        switch selectedSegmentIndex {
        case .Zero:
            if !isQueryingForTradeIdeas && tradeIdeas.count == 0 {
                return true
            }
        case .One:
            if !isQueryingForFollowing && followingUsers.count == 0 {
                return true
            }
        case .Two:
            if !isQueryingForFollowers && followersUsers.count == 0 {
                return true
            }
        case .Three:
            if !isQueryingForLikedTradeIdeas && likedTradeIdeas.count == 0 {
                return true
            }
        }
        return false
    }
    
    //    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
    //
    //        guard !isCurrentUserBlocked else {
    //            return UIImage(assetIdentifier: .UserBlockedBig)
    //        }
    //    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "@\(self.user!.userObject.username!) is blocked", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
            return attributedTitle
        }
        
        switch selectedSegmentIndex {
        case .Zero:
            attributedTitle = NSAttributedString(string: "No Trade Ideas", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        case .One:
            attributedTitle = NSAttributedString(string: "Not Following Anyone", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        case .Two:
            attributedTitle = NSAttributedString(string: "No Followers Yet", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        case .Three:
            attributedTitle = NSAttributedString(string: "No Trade Ideas Liked", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        }
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "You are blocked from following @\(self.user!.userObject.username!) and viewing their profile", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "Are you sure you want to view this profile? Viewing this profile won't unblock @\(self.user!.userObject.username!)", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
            return attributedTitle
        }
        
        return NSAttributedString(string: "", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return (self.tableView.frame.midY - self.headerView.frame.midY) / 2
    }
    
    //    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
    //        shouldShowProfile = true
    //        self.refreshControlAction(self.refreshControl!)
    //    }
}