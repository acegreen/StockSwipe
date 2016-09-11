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
    func subScrollViewDidScroll(_ scrollView: UIScrollView)
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
    
    var tradeIdeaObjects = [PFObject]()
    var followingUsers = [PFUser]()
    var followersUsers = [PFUser]()
    var likedTradeIdeaObjects = [PFObject]()
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
    
    @IBAction func settingsButton(_ sender: AnyObject) {
        
        guard let viewRect = sender as? UIView else {
            return
        }
        
        guard let currentUser = PFUser.current() else {
            Functions.isUserLoggedIn(self)
            return
        }
        guard let user = self.user else { return }
        
        let settingsAlert = UIAlertController()
        settingsAlert.modalPresentationStyle = .popover
        if user.userObject.objectId == currentUser.objectId  {
            
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
            
            settingsAlert.addAction(blockAction(user.userObject))
            
            let reportIdea = UIAlertAction(title: "Report", style: .default) { action in
                
                SweetAlert().showAlert("Report \(user.userObject.username!)?", subTitle: "", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Report", buttonColor:UIColor.colorFromRGB(0xD0D0D0), otherButtonTitle: "Report & Block", otherButtonColor: Constants.stockSwipeGreenColor) { (isOtherButton) -> Void in
                    
                    if !isOtherButton {
                        
                        Functions.blockUser(user.userObject, postAlert: false)
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_user"] = user.userObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.success)
                                })
                                
                            } else {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                                })
                            }
                        })
                        
                    } else {
                        
                        let spamObject = PFObject(className: "Spam")
                        spamObject["reported_user"] = user.userObject
                        spamObject["reported_by"] = currentUser
                        
                        spamObject.saveEventually ({ (success, error) in
                            
                            if success {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    SweetAlert().showAlert("Reported", subTitle: "", style: AlertStyle.success)
                                })
                                
                            } else {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    SweetAlert().showAlert("Something Went Wrong!", subTitle: error?.localizedDescription, style: AlertStyle.warning)
                                })
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
        settingsAlert.view.tintColor = Constants.stockSwipeGreenColor
    }
    
    @IBAction func followButtonPressed(_ sender: FollowButton) {
        self.registerFollow(sender)
    }
    
    @IBAction func refreshControlAction(_ sender: UIRefreshControl) {
        
        getProfile()
        
        switch selectedSegmentIndex {
        case .zero, .three:
            Functions.setupConfigParameter("TRADEIDEAQUERYLIMIT") { (parameterValue) -> Void in
                self.tradeIdeaQueryLimit = parameterValue as? Int ?? 25
                self.getUserTradeIdeas()
            }
        case .one:
            getUsersFollowing()
        case .two:
            getUsersFollowers()
        }
        
        self.delegate?.didReloadProfileTableView()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getProfile()
        getUserTradeIdeas()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    func subDidSelectSegment(_ segmentedControl: UISegmentedControl) {
        
        selectedSegmentIndex = ProfileContainerController.SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
        
        switch selectedSegmentIndex {
        case .zero:
            if tradeIdeaObjects.count == 0 {
                self.getUserTradeIdeas()
            }
        case .one:
            if followingUsers.count == 0 {
                getUsersFollowing()
            }
        case .two:
            if followersUsers.count == 0 {
                getUsersFollowers()
            }
        case .three:
            if likedTradeIdeaObjects.count == 0 {
                self.getUserTradeIdeas()
            }
        }
        self.tableView.reloadData()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.subScrollViewDidScroll(scrollView)
    }
    
    func checkProfileButtonSettings() {
        if user?.objectId == PFUser.current()?.objectId {
            followButton.isHidden = true
            //editProfileButton.hidden = false
        } else {
            //editProfileButton.hidden = true
        }
    }
    
    func getProfile() {
        
        guard let user = user else { return }
        
        checkProfileButtonSettings()
        checkFollow(self.followButton)
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.avatarImage.image = user.avtar
        })
        
        self.fullNameLabel.text = user.fullname
        self.usernameLabel.text = user.username
    }
    
    func getUserTradeIdeas() {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user?.userObject else { return }
        
        switch selectedSegmentIndex {
        case .zero:
            
            isQueryingForTradeIdeas = true
            
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: userObject, skip: 0, limit: self.tradeIdeaQueryLimit) { (result) in
                
                self.isQueryingForTradeIdeas = false
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    self.tradeIdeaObjects = tradeIdeasObjects
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                }
            }
            
        case .one:
            return
        case .two:
            return
        case .three:
            
            isQueryingForLikedTradeIdeas = true
            
            QueryHelper.sharedInstance.queryActivityFor(userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: 0, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
                
                self.isQueryingForLikedTradeIdeas = false
                
                do {
                    
                    let activityObjects = try result()
                    
                    self.likedTradeIdeaObjects = activityObjects
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        
                        if self.refreshControl?.isRefreshing == true {
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
        
        if self.refreshControl?.isRefreshing == false && !self.footerActivityIndicator.isAnimating {
            self.footerActivityIndicator.startAnimating()
        }
        
        switch selectedSegmentIndex {
        case .zero:
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: userObject, skip: tradeIdeaObjects.count, limit: self.tradeIdeaQueryLimit) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    //add datasource object here for tableview
                    self.tradeIdeaObjects += tradeIdeasObjects
                    
                    var indexPaths = [IndexPath]()
                    for i in 0..<tradeIdeasObjects.count {
                        indexPaths.append(IndexPath(row: self.tableView.numberOfRows(inSection: 0) + i, section: 0))
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        //now insert cell in tableview
                        self.tableView.insertRows(at: indexPaths, with: .none)
                        
                        if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async(execute: { () -> Void in
                        if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                }
            }
        case .one:
            return
        case .two:
            return
        case .three:
            
            QueryHelper.sharedInstance.queryActivityFor(userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: likedTradeIdeaObjects.count, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
                
                do {
                    
                    let activityObjects = try result()
                    
                    
                    //add datasource object here for tableview
                    self.likedTradeIdeaObjects += activityObjects.lazy.map { $0["tradeIdea"] as! PFObject }
                    
                    var indexPaths = [IndexPath]()
                    for i in 0..<activityObjects.count {
                        indexPaths.append(IndexPath(row: self.tableView.numberOfRows(inSection: 0) + i, section: 0))
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        //now insert cell in tableview
                        self.tableView.insertRows(at: indexPaths, with: .none)
                        
                        if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                            self.updateRefreshDate()
                        }
                    })
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async(execute: { () -> Void in
                        if self.footerActivityIndicator?.isAnimating == true {
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
        
        QueryHelper.sharedInstance.queryActivityFor(user.userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: ["toUser"], completion: { (result) in
            
            self.isQueryingForFollowing = false
            
            do {
                
                let activityObjects = try result()
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    // add users to data source
                    self.followingUsers = activityObjects.lazy.map { $0["toUser"] as! PFUser }
                    
                    // reload table to reflect data
                    self.tableView.reloadData()
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                DispatchQueue.main.async(execute: { () -> Void in
                    if self.refreshControl?.isRefreshing == true {
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
        
        QueryHelper.sharedInstance.queryActivityFor(nil, toUser: user.userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: ["FromUser"], completion: { (result) in
            
            self.isQueryingForFollowers = false
            
            do {
                
                let activityObjects = try result()
                
                self.followersUsers = []
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    // add users to data source
                    self.followersUsers = activityObjects.lazy.map { $0["toUser"] as! PFUser }
                    
                    // reload table to reflect data
                    self.tableView.reloadData()
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
                
            } catch {
                DispatchQueue.main.async(execute: { () -> Void in
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                        self.updateRefreshDate()
                    }
                })
            }
        })
    }
    
    func checkFollow(_ sender: FollowButton) {
        
        guard user?.objectId != PFUser.current()?.objectId else { return }
        
        guard let currentUser = PFUser.current() else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] , users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.disabled
            self.isCurrentUserBlocked = true
            self.shouldShowProfileAnyway = false
            self.tableView.reloadEmptyDataSet()
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] , blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            sender.buttonState = FollowButton.state.blocked
            self.isUserBlocked = true
            self.tableView.reloadEmptyDataSet()
            return
        }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result()
                
                if activityObject.first != nil {
                    sender.buttonState = FollowButton.state.following
                } else {
                    sender.buttonState = FollowButton.state.notFollowing
                }
                
            } catch {
            }
        })
    }
    
    func registerFollow(_ sender: FollowButton) {
        
        guard user?.userObject.objectId != PFUser.current()?.objectId else {
            followButton.isHidden = true
            return
        }
        
        guard let currentUser = PFUser.current() else {
            let logInViewcontroller = LoginViewController.sharedInstance
            logInViewcontroller.loginDelegate = self
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] , users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.disabled
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == userObject.objectId }) {
            
            currentUser.remove(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                if success {
                    sender.buttonState = FollowButton.state.notFollowing
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
                    
                    activityObject.saveInBackground(block: { (success, error) in
                        
                        if success {
                            sender.buttonState = FollowButton.state.following
                            
                            // Send push
                            Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId":userObject.objectId!, "checkSetting": "follower_notification", "title": "Follower Notification", "message": "@\(currentUser.username!) is now following you"])
                            
                        } else {
                            sender.buttonState = FollowButton.state.notFollowing
                        }
                    })
                } else {
                    activityObject.first?.deleteEventually()
                    sender.buttonState = FollowButton.state.notFollowing
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
        
        if isModal() {
            self.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \((Date() as NSDate).formattedAsTimeAgo())"
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.white
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            switch selectedSegmentIndex {
            case .zero:
                self.loadMoreTradeIdeas()
            case .one:
                getUsersFollowing()
            case .two:
                getUsersFollowers()
            case .three:
                self.loadMoreTradeIdeas()
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
                
                SweetAlert().showAlert("Block @\(user.username!)?", subTitle: "@\(user.username!) will not be able to follow or view your ideas, and you will not see anything from @\(user.username!)", style: AlertStyle.warning, dismissTime: nil, buttonTitle:"Block", buttonColor:Constants.stockSwipeGreenColor, otherButtonTitle: nil, otherButtonColor: nil) { (isOtherButton) -> Void in
                    
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
            destinationViewController.tradeIdea = cell.tradeIdea
            
        case .ProfileSegueIdentifier:
            let profileContainerController = segue.destination as! ProfileContainerController
            profileContainerController.navigationItem.rightBarButtonItem = nil
            
            guard let cell = sender as? UserCell  else { return }
            profileContainerController.user = cell.user
        case .EditProfileSegueIdentifier:
            
            let navigationController = segue.destination as! UINavigationController
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
        
        if selectedSegmentIndex == .zero && self.user?.userObject.objectId == PFUser.current()?.objectId {
            
            self.tradeIdeaObjects.insert(tradeIdea.parseObject, at: 0)
            
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == parseObject.objectId }) {
            
            if selectedSegmentIndex == .zero && self.user?.userObject.objectId == PFUser.current()?.objectId {
                if let reshareOf = tradeIdea.object(forKey: "reshare_of") as? PFObject, let reshareTradeIdea = self.tradeIdeaObjects.find ({ $0.objectId == reshareOf.objectId })  {
                    
                    let indexPath = IndexPath(row: self.tradeIdeaObjects.index(of: reshareTradeIdea)!, section: 0)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                
                let indexPath = IndexPath(row: self.tradeIdeaObjects.index(of: tradeIdea)!, section: 0)
                self.tradeIdeaObjects.removeObject(tradeIdea)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                
                if tradeIdeaObjects.count == 0 {
                    self.tableView.reloadEmptyDataSet()
                }
            }
        }
    }
}

extension ProfileTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch selectedSegmentIndex {
        case .zero:
            return tradeIdeaObjects.count
        case .one:
            return followingUsers.count
        case .two:
            return followersUsers.count
        case .three:
            return likedTradeIdeaObjects.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch selectedSegmentIndex {
        case .zero:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(tradeIdeaObjects[(indexPath as NSIndexPath).row], timeFormat: .short)
            cell.delegate = self
            return cell
        case .one:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(followingUsers[(indexPath as NSIndexPath).row])
            return cell
        case .two:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(followersUsers[(indexPath as NSIndexPath).row])
            return cell
        case .three:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(likedTradeIdeaObjects[(indexPath as NSIndexPath).row], timeFormat: .short)
            cell.delegate = self
            return cell
        }
    }
    
    // DZNEmptyDataSet delegate functions
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        switch selectedSegmentIndex {
        case .zero:
            if !isQueryingForTradeIdeas && tradeIdeaObjects.count == 0 {
                return true
            }
        case .one:
            if !isQueryingForFollowing && followingUsers.count == 0 {
                return true
            }
        case .two:
            if !isQueryingForFollowers && followersUsers.count == 0 {
                return true
            }
        case .three:
            if !isQueryingForLikedTradeIdeas && likedTradeIdeaObjects.count == 0 {
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
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "@\(self.user!.userObject.username!) is blocked", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        switch selectedSegmentIndex {
        case .zero:
            attributedTitle = NSAttributedString(string: "No Trade Ideas", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        case .one:
            attributedTitle = NSAttributedString(string: "Not Following Anyone", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        case .two:
            attributedTitle = NSAttributedString(string: "No Followers Yet", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        case .three:
            attributedTitle = NSAttributedString(string: "No Trade Ideas Liked", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
        }
        
        return attributedTitle
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
        
        guard !isCurrentUserBlocked else {
            attributedTitle = NSAttributedString(string: "You are blocked from following @\(self.user!.userObject.username!) and viewing their profile", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        if isUserBlocked  && !shouldShowProfileAnyway {
            attributedTitle = NSAttributedString(string: "Are you sure you want to view this profile? Viewing this profile won't unblock @\(self.user!.userObject.username!)", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
            return attributedTitle
        }
        
        return NSAttributedString(string: "", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 24)])
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return (self.tableView.frame.midY - self.headerView.frame.midY) / 2
    }
    
    //    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
    //        shouldShowProfile = true
    //        self.refreshControlAction(self.refreshControl!)
    //    }
}
