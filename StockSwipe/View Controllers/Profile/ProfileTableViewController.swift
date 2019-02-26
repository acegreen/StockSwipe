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
import Crashlytics
import Reachability

protocol ProfileTableVieDelegate {
    func subScrollViewDidScroll(_ scrollView: UIScrollView)
    func didRefreshProfileTableView()
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
    
    var profileTableDelegate: ProfileTableVieDelegate?
    var loginDelegate: LoginDelegate?
    var profileChangeDelegate: ProfileDetailTableViewControllerDelegate?
    
    var user: User!
    var isCurrentUserBlocked: Bool = false
    var isUserBlocked: Bool = false
    var shouldShowProfileAnyway: Bool = false
    
    var tradeIdeaActivities = [Activity]()
    var followingUserActivities = [User]()
    var followerUsersActivities = [User]()
    var likedTradeIdeasActivities = [Activity]()
    
    var isQueryingForTradeIdeas = false
    var isQueryingForFollowing = false
    var isQueryingForFollowers = false
    var isQueryingForLikedTradeIdeas = false
    
    var tradeIdeasLastRefreshDate: Date!
    var followingLastRefreshDate: Date!
    var followersLastRefreshDate: Date!
    var likedTradeIdeasLastRefreshDate: Date!
        
    var selectedSegmentIndex: ProfileContainerController.SegmentIndex = ProfileContainerController.SegmentIndex(rawValue: 0)!
    
    let reachability = Reachability()
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var avatarImage: UIImageView!
    @IBOutlet var fullNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    
    @IBOutlet var profileButtonsStack: UIStackView!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var followButton: FollowButton!
    @IBOutlet var editProfileButton: UIButton!
    
    @IBAction func settingsButton(_ sender: AnyObject) {
        
        guard let viewRect = sender as? UIView else {
            return
        }
        
        guard let currentUser = User.current() else {
            Functions.isUserLoggedIn(presenting: self)
            return
        }
        guard let user = self.user else { return }
        
        let settingsAlert = UIAlertController()
        settingsAlert.modalPresentationStyle = .popover
        if user.objectId == currentUser.objectId  {
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { action in
                self.performSegueWithIdentifier(.SettingsSegueIdentifier, sender: self)
            }
            settingsAlert.addAction(settingsAction)
            
            if PFUser.current() != nil {
                let logInOutAction = UIAlertAction(title: "Log Out", style: .default) { action in
                    let logInViewcontroller = LoginViewController.sharedInstance
                    logInViewcontroller.loginDelegate = self
                    
                    if PFUser.current() != nil {
                        logInViewcontroller.logOut()
                    }
                }
                settingsAlert.addAction(logInOutAction)
            }
            
        } else {
            
            settingsAlert.addAction(blockAction(user))
            
            let reportIdea = UIAlertAction(title: "Report", style: .default) { action in
                
                SweetAlert().showAlert("Report \(user.username!)?", subTitle: "", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor(rgbValue: 0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.SSColors.green) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(user, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_user"] = user
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async {
                                    Functions.showNotificationBanner(title: "Reported", subtitle: "", style: .success)
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    Functions.showNotificationBanner(title: nil, subtitle: error?.localizedDescription, style: .warning)
                                }
                            }
                        })
                        
                    } else {
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_user"] = user
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async {
                                    Functions.showNotificationBanner(title: "Reported", subtitle: "", style: .success)
                                }
                                
                            } else {
                                DispatchQueue.main.async {
                                    Functions.showNotificationBanner(title: nil, subtitle: error?.localizedDescription, style: .warning)
                                }
                            }
                        })
                    }
                }
            }
            settingsAlert.addAction(reportIdea)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
        }
        
        settingsAlert.addAction(cancel)
        
        if let presenter = settingsAlert.popoverPresentationController {
            presenter.sourceView = viewRect;
            presenter.sourceRect = viewRect.bounds;
        }
        
        UIApplication.topViewController()?.present(settingsAlert, animated: true, completion: nil)
        settingsAlert.view.tintColor = Constants.SSColors.green
    }
    
    @IBAction func followButtonPressed(_ sender: FollowButton) {
        self.registerFollow(sender)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl?) {
        
        switch selectedSegmentIndex {
        case .zero:
            getTradeIdeas(queryType: .update)
        case .one:
            getFollowing(queryType: .update)
        case .two:
            getFollowers(queryType: .update)
        case .three:
            getTradeIdeas(queryType: .update)
        }
        
        self.profileTableDelegate?.didRefreshProfileTableView()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getProfile()
        self.handleReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    deinit {
        self.reachability?.stopNotifier()
    }
    
    func subDidSelectSegment(_ segmentedControl: UISegmentedControl) {
        
        selectedSegmentIndex = ProfileContainerController.SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
        
        switch selectedSegmentIndex {
        case .zero:
            if tradeIdeaActivities.count == 0 {
                getTradeIdeas(queryType: .new)
            }
        case .one:
            if followingUserActivities.count == 0 {
                getFollowing(queryType: .new)
            }
        case .two:
            if followerUsersActivities.count == 0 {
                getFollowers(queryType: .new)
            }
        case .three:
            if likedTradeIdeasActivities.count == 0 {
                getTradeIdeas(queryType: .new)
            }
        }
        self.tableView.reloadData()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.profileTableDelegate?.subScrollViewDidScroll(scrollView)
    }
    
    func checkProfileButtonSettings() {
        if user?.objectId == PFUser.current()?.objectId {
            followButton.isHidden = true
            editProfileButton.isHidden = false
        } else {
            editProfileButton.isHidden = true
        }
    }
    
    func getProfile() {
        
        guard let user = user else { return }
        
        DispatchQueue.main.async {
            self.fullNameLabel.text = user.full_name
            self.usernameLabel.text = user.usertag
        }
        user.getAvatar { (avatar) in
            DispatchQueue.main.async {
                self.avatarImage.image = avatar
            }
        }
        
        self.checkProfileButtonSettings()
        self.checkFollow(self.followButton)
    }
    
    func getTradeIdeas(queryType: QueryHelper.QueryType) {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user else { return }
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?

        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
        case .update:
            queryOrder = .ascending
        }
        
        switch selectedSegmentIndex {
        case .zero:
            
            if queryType == .update {
                mostRecentRefreshDate = tradeIdeasLastRefreshDate
            } else if queryType == .older {
                skip = self.tradeIdeaActivities.count
            }
            
            isQueryingForTradeIdeas = true
            let activityTypes = [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue]
            
            QueryHelper.sharedInstance.queryActivityFor(fromUser: self.user, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: activityTypes, skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], selectKeys: nil, order: queryOrder, creationDate: mostRecentRefreshDate, cachePolicy: .networkElseCache) { result in
                
                do {
                    
                    guard let tradeIdeaObjects = try result() as? [Activity] else { return }
                    
                    guard tradeIdeaObjects.count > 0 else {
                        
                        self.isQueryingForTradeIdeas = false
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            if self.refreshControl?.isRefreshing == true {
                                self.refreshControl?.endRefreshing()
                            } else if self.footerActivityIndicator?.isAnimating == true {
                                self.footerActivityIndicator.stopAnimating()
                            }
                        }
                        self.updateRefreshDate()
                        self.tradeIdeasLastRefreshDate = Date()
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        
                        switch queryType {
                        case .new:
                            
                            self.tradeIdeaActivities = tradeIdeaObjects
                            self.tableView.reloadData()
                            
                        case .older:
                            
                            // append more trade ideas
                            let currentCount = self.tradeIdeaActivities.count
                            self.tradeIdeaActivities += tradeIdeaObjects
                            
                            // insert cell in tableview
                            self.tableView.beginUpdates()
                            for (i,_) in tradeIdeaObjects.enumerated() {
                                let indexPath = IndexPath(row: currentCount + i, section: 0)
                                self.tableView.insertRows(at: [indexPath], with: .none)
                            }
                            self.tableView.endUpdates()
                            
                        case .update:
                            
                            // append more trade ideas
                            self.tableView.beginUpdates()
                            for tradeIdeaActivity in tradeIdeaObjects {
                                self.tradeIdeaActivities.insert(tradeIdeaActivity, at: 0)
                                let indexPath = IndexPath(row: 0, section: 0)
                                self.tableView.insertRows(at: [indexPath], with: .none)
                            }
                            self.tableView.endUpdates()
                        }
                        
                        // end refresh and add time stamp
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                        self.updateRefreshDate()
                        self.tradeIdeasLastRefreshDate = Date()
                    }
                    
                    self.isQueryingForTradeIdeas = false
                    
                } catch {
                    
                    //TODO: Show sweet alert with Error.message()
                    DispatchQueue.main.async {
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }
                    
                    self.isQueryingForTradeIdeas = false
                }
            }
            
        case .one, .two:
            return
        case .three:
            
            if queryType == .update {
                mostRecentRefreshDate = likedTradeIdeasLastRefreshDate
            } else if queryType == .older {
                skip = self.likedTradeIdeasActivities.count
            }
            
            isQueryingForLikedTradeIdeas = true
            
            QueryHelper.sharedInstance.queryActivityFor(fromUser: userObject, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: skip, limit: QueryHelper.queryLimit, includeKeys: nil, order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
                
                do {
                    
                    guard let likedActivityObjects = try result() as? [Activity], let likedTradeIdeas = likedActivityObjects.map({ $0.tradeIdea }) as? [TradeIdea] else { return }
                    
                    QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdeas: nil, tradeIdeas: likedTradeIdeas, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue], skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["tradeIdea", "fromUser", "originalTradeIdea"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in

                        do {
                            
                            guard let activityObjects = try result() as? [Activity] else { return }
                            
                            guard activityObjects.count > 0 else {
                                
                                self.isQueryingForLikedTradeIdeas = false
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    if self.refreshControl?.isRefreshing == true {
                                        self.refreshControl?.endRefreshing()
                                    } else if self.footerActivityIndicator?.isAnimating == true {
                                        self.footerActivityIndicator.stopAnimating()
                                    }
                                }
                                self.updateRefreshDate()
                                self.likedTradeIdeasLastRefreshDate = Date()
                                
                                return
                            }
                            
                            DispatchQueue.main.async {
                                
                                switch queryType {
                                case .new:
                                    
                                    self.likedTradeIdeasActivities = activityObjects
                                    self.tableView.reloadData()
                                    
                                case .older:
                                    
                                    // append more trade ideas
                                    let currentCount = self.likedTradeIdeasActivities.count
                                    self.likedTradeIdeasActivities += activityObjects
                                    
                                    // insert cell in tableview
                                    self.tableView.beginUpdates()
                                    for (i,_) in activityObjects.enumerated() {
                                        let indexPath = IndexPath(row: currentCount + i, section: 0)
                                        self.tableView.insertRows(at: [indexPath], with: .none)
                                    }
                                    self.tableView.endUpdates()
                                    
                                case .update:
                                    
                                    // add more trade ideas to the top
                                    self.tableView.beginUpdates()
                                    for likedTradeIdea in activityObjects {
                                        self.likedTradeIdeasActivities.insert(likedTradeIdea, at: 0)
                                        let indexPath = IndexPath(row: 0, section: 0)
                                        self.tableView.insertRows(at: [indexPath], with: .none)
                                    }
                                    self.tableView.endUpdates()
                                }
                                
                                // end refresh and add time stamp
                                if self.refreshControl?.isRefreshing == true {
                                    self.refreshControl?.endRefreshing()
                                } else if self.footerActivityIndicator.isAnimating == true {
                                    self.footerActivityIndicator.stopAnimating()
                                }
                                
                                self.updateRefreshDate()
                                self.likedTradeIdeasLastRefreshDate = Date()
                            }
                            
                            self.isQueryingForLikedTradeIdeas = false
                            
                        } catch {

                            // TODO: handle error
                            DispatchQueue.main.async {
                                if self.refreshControl?.isRefreshing == true {
                                    self.refreshControl?.endRefreshing()
                                } else if self.footerActivityIndicator?.isAnimating == true {
                                    self.footerActivityIndicator.stopAnimating()
                                }
                            }
                            
                            self.isQueryingForLikedTradeIdeas = false
                        }
                    })
                    
                } catch {
                    
                    //TODO: Show sweet alert with Error.message()
                    DispatchQueue.main.async {
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }
                    
                    self.isQueryingForLikedTradeIdeas = false
                }
            })
        }
    }
    
    func getFollowing(queryType: QueryHelper.QueryType) {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?

        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
            skip = self.followingUserActivities.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = followingLastRefreshDate
        }
        
        isQueryingForFollowing = true
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: user, toUser: nil, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["toUser"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }

                guard activityObjects.count > 0 else {

                    self.isQueryingForFollowing = false

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                        self.updateRefreshDate()
                        self.followingLastRefreshDate = Date()
                    }

                    return
                }

                guard let followingUserActivities = activityObjects.map({ $0.toUser }) as? [User] else { return }

                DispatchQueue.main.async {

                    switch queryType {
                    case .new:

                        self.followingUserActivities = followingUserActivities
                        self.tableView.reloadData()

                    case .older:

                        // append more users
                        let currentCount = self.followingUserActivities.count
                        self.followingUserActivities += followingUserActivities

                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in followingUserActivities.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()

                    case .update:

                        // append more users and insert rows
                        self.tableView.beginUpdates()
                        for followingUser in followingUserActivities {
                            self.followingUserActivities.insert(followingUser, at: 0)
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                    }

                    // end refresh and add time stamp
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }

                    self.updateRefreshDate()
                    self.followingLastRefreshDate = Date()
                }

                self.isQueryingForFollowing = false
                
            } catch {
                
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                
                self.isQueryingForFollowing = false
            }
        })
    }
    
    func getFollowers(queryType: QueryHelper.QueryType) {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        var queryOrder: QueryHelper.QueryOrder
        var skip: Int?
        var mostRecentRefreshDate: Date?

        switch queryType {
        case .new, .older:
            queryOrder = .descending
            
            if !self.footerActivityIndicator.isAnimating {
                self.footerActivityIndicator.startAnimating()
            }
            
            skip = self.followerUsersActivities.count
            
        case .update:
            queryOrder = .ascending
            mostRecentRefreshDate = followersLastRefreshDate
        }
        
        isQueryingForFollowers = true
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: user, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: skip, limit: QueryHelper.queryLimit, includeKeys: ["fromUser"], order: queryOrder, creationDate: mostRecentRefreshDate, completion: { (result) in
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }

                guard activityObjects.count > 0 else {

                    self.isQueryingForFollowers = false

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }

                        self.updateRefreshDate()
                        self.followersLastRefreshDate = Date()
                    }

                    return
                }

                guard let followerUsersActivities = activityObjects.map({ $0.fromUser }) as? [User] else { return }

                DispatchQueue.main.async {

                    switch queryType {
                    case .new:

                        self.followerUsersActivities = followerUsersActivities
                        self.tableView.reloadData()

                    case .older:

                        // append more users
                        let currentCount = self.followerUsersActivities.count
                        self.followerUsersActivities += followerUsersActivities

                        // insert cell in tableview
                        self.tableView.beginUpdates()
                        for (i,_) in followerUsersActivities.enumerated() {
                            let indexPath = IndexPath(row: currentCount + i, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()

                    case .update:

                        // append more users and insert rows
                        self.tableView.beginUpdates()
                        for followerUser in followerUsersActivities {
                            self.followerUsersActivities.insert(followerUser, at: 0)
                            let indexPath = IndexPath(row: 0, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .none)
                        }
                        self.tableView.endUpdates()
                    }

                    // end refresh and add time stamp
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }

                    self.updateRefreshDate()
                    self.followersLastRefreshDate = Date()
                }

                self.isQueryingForFollowers = false
                
            } catch {
                
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    } else if self.footerActivityIndicator?.isAnimating == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                }
                
                self.isQueryingForFollowers = false
            }
        })
    }
    
    func checkFollow(_ sender: FollowButton) {
        
        guard user?.objectId != PFUser.current()?.objectId else { return }
        
        guard let currentUser = PFUser.current() else { return }
        guard let userObject = self.user else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] , users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.disabled
            self.isCurrentUserBlocked = true
            self.shouldShowProfileAnyway = false
            self.tableView.reloadData()
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] , blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            sender.buttonState = FollowButton.state.blocked
            self.isUserBlocked = true
            self.tableView.reloadData()
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: userObject, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result()
                
                DispatchQueue.main.async {
                    if activityObject.first != nil {
                        sender.buttonState = FollowButton.state.following
                    } else {
                        sender.buttonState = FollowButton.state.notFollowing
                    }
                    
                    sender.isHidden = false
                }
                
            } catch {
                //TODO: handle error
            }
        })
    }
    
    func registerFollow(_ sender: FollowButton) {
        
        guard user.objectId != User.current()?.objectId else {
            followButton.isHidden = true
            return
        }
        
        guard let currentUser = User.current() else {
            let logInViewcontroller = LoginViewController.sharedInstance
            logInViewcontroller.loginDelegate = self
            Functions.isUserLoggedIn(presenting: UIApplication.topViewController()!)
            return
        }
        
        if let users_blocked_users = user.blocked_users, users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.disabled
            return
        }
        
        if let blocked_users = currentUser.blocked_users, let blockedUser = blocked_users .find({ $0.objectId == user.objectId }) {
            
            currentUser.remove(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                if success {
                    sender.buttonState = FollowButton.state.notFollowing
                }
            })
            return
        }
        
        sender.isEnabled = false
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: user, originalTradeIdeas: nil, tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil) { (result) in
            
            do {
                
                let activityObject = try result()
                if activityObject.first == nil {

                    let activityObject = Activity()
                    activityObject["fromUser"] = currentUser
                    activityObject["toUser"] = self.user
                    activityObject["activityType"] = Constants.ActivityType.Follow.rawValue

                    activityObject.saveEventually({ (success, error) in

                        if success {
                            sender.buttonState = FollowButton.state.following

                            #if DEBUG
                                print("send push didn't happen in debug")
                            #else
                                // Send push
                                Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId": self.user.objectId!, "checkSetting": "follower_notification", "title": "Follower Notification", "message": "@\(currentUser.username!) is now following you"])
                            #endif

                            // log following
                            Answers.logCustomEvent(withName: "Follow", customAttributes: ["From User": currentUser.username ?? "N/A", "To User": self.user.username ?? "N/A", "Activity Type": "Followed", "App Version": Constants.AppVersion])

                        } else {

                            DispatchQueue.main.async {
                                sender.buttonState = FollowButton.state.notFollowing
                            }
                        }
                    })

                } else {
                    activityObject.first?.deleteEventually()

                    DispatchQueue.main.async {
                        sender.buttonState = FollowButton.state.notFollowing
                    }

                    // log following
                    Answers.logCustomEvent(withName: "Follow", customAttributes: ["From User": currentUser.username ?? "N/A", "To User": self.user.username ?? "N/A", "Activity Type": "Unfollowed", "App Version": Constants.AppVersion])
                }
                
            } catch {                
                //TODO: handle error
            }
            
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
        }
        
    }
    
    func didLoginSuccessfully() {
        self.getProfile()
        self.loginDelegate?.didLoginSuccessfully()
    }
    
    func didLogoutSuccessfully() {
        
        if isModal() {
            self.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
        self.loginDelegate?.didLogoutSuccessfully()
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: " + (Date() as NSDate).formattedAsTimeAgo()
        let attrsDictionary = [
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            
            switch selectedSegmentIndex {
            case .zero, .three:
                getTradeIdeas(queryType: .older)
            case .one:
                getFollowing(queryType: .older)
            case .two:
                getFollowers(queryType: .older)
            }
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
                
                SweetAlert().showAlert("Block @\(user.username!)?", subTitle: "@\(user.username!) will not be able to follow or view your ideas, and you will not see anything from @\(user.username!)", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.SSColors.green, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
                    if isOtherButton {
                        Functions.blockUser(user, postAlert: true)
                    }
                }
            }
            
            return blockUser
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let segueIdentifier = segueIdentifierForSegue(segue)
        
        switch segueIdentifier {
            
        case .TradeIdeaDetailSegueIdentifier:
            let destinationViewController = segue.destination as! TradeIdeaDetailTableViewController
            destinationViewController.delegate = self
            
            guard let cell = sender as? IdeaCell else { return }
            destinationViewController.activity = cell.activity
            
        case .ProfileSegueIdentifier:
            let profileContainerController = segue.destination as! ProfileContainerController
            
            guard let cell = sender as? UserCell  else { return }
            profileContainerController.user = cell.user
        case .EditProfileSegueIdentifier:
            let navigationController = segue.destination as! UINavigationController
            let profileDetailViewController = navigationController.viewControllers.first as! ProfileDetailTableViewController
            profileDetailViewController.delegate = self
            profileDetailViewController.user = self.user
            
            break
        case .SettingsSegueIdentifier:
            break
        }
    }
}

extension ProfileTableViewController: ProfileDetailTableViewControllerDelegate {
    
    func userProfileChanged(newUser: User) {
        self.user = newUser
        self.getProfile()
        self.tableView.reloadData()
        
        self.profileChangeDelegate?.userProfileChanged(newUser: newUser)
    }
}

extension ProfileTableViewController: IdeaPostDelegate {
    
    internal func ideaPosted(with activity: Activity, tradeIdeaTyp: Constants.TradeIdeaType) {
        
        guard tradeIdeaTyp != .reply else { return }
        
        if selectedSegmentIndex == .zero && self.user?.objectId == User.current()?.objectId {

            let indexPath = IndexPath(row: 0, section: 0)
            self.tradeIdeaActivities.insert(activity, at: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    internal func ideaDeleted(with activity: Activity) {
        
        guard self.user?.objectId == User.current()?.objectId else { return }
        
        if selectedSegmentIndex == .zero, let activity = self.tradeIdeaActivities.find ({ $0.objectId == activity.objectId }), let index = self.tradeIdeaActivities.index(of: activity) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tradeIdeaActivities.removeObject(activity)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        if tradeIdeaActivities.count == 0 {
            self.tableView.reloadData()
        }
    }

    internal func ideaUpdated(with activity: Activity) {
     
        if (selectedSegmentIndex == .zero || selectedSegmentIndex == .three), let activity = self.tradeIdeaActivities.find ({ $0.objectId == activity.objectId }), let index = self.tradeIdeaActivities.index(of: activity) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

extension ProfileTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch selectedSegmentIndex {
        case .zero:
            return tradeIdeaActivities.count
        case .one:
            return followingUserActivities.count
        case .two:
            return followerUsersActivities.count
        case .three:
            return likedTradeIdeasActivities.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch selectedSegmentIndex {
        case .zero:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            guard let tradeIdeaActivityAtIndex = self.tradeIdeaActivities.get(indexPath.row) else { return cell }
            cell.configureCell(with: tradeIdeaActivityAtIndex, timeFormat: .short)
            cell.delegate = self
            return cell
        case .one:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(with: followingUserActivities[indexPath.row])
            return cell
        case .two:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(with: followerUsersActivities[indexPath.row])
            return cell
        case .three:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            guard let likedTradeIdeaAtIndex = self.likedTradeIdeasActivities.get(indexPath.row) else { return cell }
            cell.configureCell(with: likedTradeIdeaAtIndex, timeFormat: .short)
            cell.delegate = self
            return cell
            return cell
        }
        
        return UITableViewCell()
    }
    
    // DZNEmptyDataSet delegate functions
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        switch selectedSegmentIndex {
        case .zero:
            if !isQueryingForTradeIdeas && tradeIdeaActivities.count == 0 {
                return true
            }
        case .one:
            if !isQueryingForFollowing && followingUserActivities.count == 0 {
                return true
            }
        case .two:
            if !isQueryingForFollowers && followerUsersActivities.count == 0 {
                return true
            }
        case .three:
            if !isQueryingForLikedTradeIdeas && likedTradeIdeasActivities.count == 0 {
                return true
            }
        }
        return false
    }
    
    //    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!{
    //        guard !isCurrentUserBlocked else {
    //            return UIImage(assetIdentifier: .UserBlockedBig)
    //        }
    //    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "@\(self.user.username!) is blocked", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        switch selectedSegmentIndex {
        case .zero:
            attributedTitle = NSAttributedString(string: "Ideas", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        case .one:
            attributedTitle = NSAttributedString(string: "Following", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        case .two:
            attributedTitle = NSAttributedString(string: "Followers", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        case .three:
            attributedTitle = NSAttributedString(string: "Ideas Liked", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        }
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "You are blocked from following @\(self.user.username!) and viewing their profile", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "Are you sure you want to view this profile? Viewing this profile won't unblock @\(self.user.username!)", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        return NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return (self.tableView.frame.midY - self.headerView.frame.midY) / 2
    }
    
    //    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
    //        shouldShowProfile = true
    //        self.refreshControlAction(self.refreshControl!)
    //    }
}

extension ProfileTableViewController {
    
    // MARK: handle reachability
    
    func handleReachability() {
        self.reachability?.whenReachable = { reachability in
            if self.tradeIdeaActivities.count == 0 {
                self.getTradeIdeas(queryType: .new)
            }
        }
        
        self.reachability?.whenUnreachable = { _ in
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}
