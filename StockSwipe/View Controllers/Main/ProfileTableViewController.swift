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
    
    var delegate: ProfileTableVieDelegate!
    
    var user: User?
    var isCurrentUserBlocked: Bool = false
    var isUserBlocked: Bool = false
    var shouldShowProfileAnyway: Bool = true
    
    var tradeIdeas = [TradeIdea]()
    var followingUsers = [User]()
    var followersUsers = [User]()
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
                        spamObject["reported_user"] = user.userObject
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
        
        switch selectedSegmentIndex {
        case .zero:
            tradeIdeas.removeAll()
            getUserTradeIdeas()
        case .one:
            followingUsers.removeAll()
            getUsersFollowing()
        case .two:
            followersUsers.removeAll()
            getUsersFollowers()
        case .three:
            likedTradeIdeas.removeAll()
            getUserTradeIdeas()
        }
        self.tableView.reloadData()
        
        self.delegate?.didRefreshProfileTableView()
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getProfile()
        
        Functions.setupConfigParameter("TRADEIDEAQUERYLIMIT") { (parameterValue) -> Void in
            self.tradeIdeaQueryLimit = parameterValue as? Int ?? 25
            self.getUserTradeIdeas()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    func subDidSelectSegment(_ segmentedControl: UISegmentedControl) {
        
        selectedSegmentIndex = ProfileContainerController.SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
        
        switch selectedSegmentIndex {
        case .zero:
            if tradeIdeas.count == 0 {
                getUserTradeIdeas()
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
            if likedTradeIdeas.count == 0 {
                getUserTradeIdeas()
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
        
        self.avatarImage.image = user.avtar
        self.fullNameLabel.text = user.fullname
        self.usernameLabel.text = user.username
    }
    
    func getUserTradeIdeas() {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user?.userObject else { return }
        
        switch selectedSegmentIndex {
        case .zero:
            
            isQueryingForTradeIdeas = true
            
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor(key: "user", object: userObject, skip: self.tradeIdeas.count, limit: self.tradeIdeaQueryLimit) { (result) in
                
                self.isQueryingForTradeIdeas = false
                
                do {
                    
                    let tradeIdeaObjects = try result()
                    
                    guard tradeIdeaObjects.count > 0 else {
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadEmptyDataSet()
                            if self.refreshControl?.isRefreshing == true {
                                self.refreshControl?.endRefreshing()
                            } else if self.footerActivityIndicator?.isAnimating == true {
                                self.footerActivityIndicator.stopAnimating()
                            }
                            self.updateRefreshDate()
                        }
                        
                        return
                    }
                    
                    for tradeIdeaObject in tradeIdeaObjects {
                        
                        TradeIdea(parseObject: tradeIdeaObject, completion: { (tradeIdea) in
                            
                            if let tradeIdea = tradeIdea {
                                
                                DispatchQueue.main.async {
                                    
                                    // append more trade ideas
                                    self.tradeIdeas.append(tradeIdea)
                                    
                                    // insert cell in tableview
                                    let indexPath = IndexPath(row: self.tradeIdeas.count - 1, section: 0)
                                    self.tableView.insertRows(at: [indexPath], with: .none)
                                    
                                    // end refresh and add time stamp
                                    if self.refreshControl?.isRefreshing == true {
                                        self.refreshControl?.endRefreshing()
                                    } else if self.footerActivityIndicator?.isAnimating == true {
                                        self.footerActivityIndicator.stopAnimating()
                                    }
                                    self.updateRefreshDate()
                                }
                            }
                        })
                    }
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async {
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }
                }
            }
            
        case .one, .two:
            return
        case .three:
            
            isQueryingForLikedTradeIdeas = true
            
            QueryHelper.sharedInstance.queryActivityFor(fromUser: userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: self.likedTradeIdeas.count, limit: self.tradeIdeaQueryLimit, includeKeys: ["tradeIdea"], completion: { (result) in
                
                self.isQueryingForLikedTradeIdeas = false
                
                do {
                    
                    let activityObjects = try result()
                    
                    let likedTradeIdeaObjects = activityObjects.map { $0["tradeIdea"] as! PFObject }
                    
                    guard likedTradeIdeaObjects.count > 0 else {
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadEmptyDataSet()
                            if self.refreshControl?.isRefreshing == true {
                                self.refreshControl?.endRefreshing()
                            } else if self.footerActivityIndicator?.isAnimating == true {
                                self.footerActivityIndicator.stopAnimating()
                            }
                            self.updateRefreshDate()
                        }
                        
                        return
                    }
                    
                    for likedTradeIdeaObject in likedTradeIdeaObjects {
                        
                        TradeIdea(parseObject: likedTradeIdeaObject, completion: { (likedTradeIdea) in
                            
                            if let likedTradeIdea = likedTradeIdea {
                                
                                DispatchQueue.main.async {
                                    
                                    self.likedTradeIdeas.append(likedTradeIdea)
                                    
                                    //now insert cell in tableview
                                    let indexPath = IndexPath(row: self.likedTradeIdeas.count - 1, section: 0)
                                    self.tableView.insertRows(at: [indexPath], with: .none)
                                    
                                    if self.refreshControl?.isRefreshing == true {
                                        self.refreshControl?.endRefreshing()
                                    } else if self.footerActivityIndicator?.isAnimating == true {
                                        self.footerActivityIndicator.stopAnimating()
                                    }
                                    self.updateRefreshDate()
                                }
                            }
                        })
                    }
                    
                } catch {
                    
                    // TO-DO: Show sweet alert with Error.message()
                    DispatchQueue.main.async {
                        if self.refreshControl?.isRefreshing == true {
                            self.refreshControl?.endRefreshing()
                        } else if self.footerActivityIndicator?.isAnimating == true {
                            self.footerActivityIndicator.stopAnimating()
                        }
                    }
                }
            })
        }
    }
    
    func getUsersFollowing() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        isQueryingForFollowing = true
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: user.userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: ["toUser"], completion: { (result) in
            
            self.isQueryingForFollowing = false
            
            do {
                
                let activityObjects = try result()
                
                // add users to data source
                self.followingUsers = activityObjects.map {
                    User(userObject: $0["toUser"] as! PFUser, completion: { (user) in
                        
                        DispatchQueue.main.async {
                            
                            if self.followingUsers.count == activityObjects.count {
                                // reload table to reflect data
                                self.tableView.reloadData()
                                if self.refreshControl?.isRefreshing == true {
                                    self.refreshControl?.endRefreshing()
                                    self.updateRefreshDate()
                                }
                            }
                        }
                    })
                }
                
            } catch {
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        })
    }
    
    func getUsersFollowers() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        isQueryingForFollowers = true
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: user.userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: ["fromUser"], completion: { (result) in
            
            self.isQueryingForFollowers = false
            
            do {
                
                let activityObjects = try result()
                
                // add users to data source
                self.followersUsers = activityObjects.map {
                    User(userObject: $0["fromUser"] as! PFUser, completion: { (user) in
                        
                        DispatchQueue.main.async {
                            if self.followersUsers.count == activityObjects.count {
                                // reload table to reflect data
                                self.tableView.reloadData()
                                if self.refreshControl?.isRefreshing == true {
                                    self.refreshControl?.endRefreshing()
                                    self.updateRefreshDate()
                                }
                            }
                        }
                    })
                }
                
            } catch {
                DispatchQueue.main.async {
                    if self.refreshControl?.isRefreshing == true {
                        self.refreshControl?.endRefreshing()
                    }
                }
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
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result()
                
                if activityObject.first != nil {
                    sender.buttonState = FollowButton.state.following
                } else {
                    sender.buttonState = FollowButton.state.notFollowing
                }
                
                sender.isHidden = false
                
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
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.Follow.rawValue], skip: nil, limit: nil, includeKeys: nil) { (result) in
            
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
                            
                            #if DEBUG
                                print("send push didn't happen in debug")
                            #else
                                // Send push
                                Functions.sendPush(Constants.PushType.ToUser, parameters: ["userObjectId":userObject.objectId!, "checkSetting": "follower_notification", "title": "Follower Notification", "message": "@\(currentUser.username!) is now following you"])
                            #endif
                            
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
        
        let title: String = "Last Update: " + (Date() as NSDate).formattedAsTimeAgo()
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
            case .zero, .three:
                getUserTradeIdeas()
            case .one:
                print("reach bottom segment section", selectedSegmentIndex)
            //getUsersFollowing()
            case .two:
                print("reach bottom segment section", selectedSegmentIndex)
            //getUsersFollowers()
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
        
        if tradeIdeaTyp == .new {
            
            let indexPath = IndexPath(row: 0, section: 0)
            self.tradeIdeas.insert(tradeIdea, at: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
            
            self.tableView.reloadEmptyDataSet()
        }
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            
            if let reshareOf = tradeIdea.nestedTradeIdea, let reshareTradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == reshareOf.parseObject.objectId })  {
                
                let indexPath = IndexPath(row: self.tradeIdeas.index(of: reshareTradeIdea)!, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            let indexPath = IndexPath(row: self.tradeIdeas.index(of: tradeIdea)!, section: 0)
            self.tradeIdeas.removeObject(tradeIdea)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        if tradeIdeas.count == 0 {
            self.tableView.reloadEmptyDataSet()
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
            return tradeIdeas.count
        case .one:
            return followingUsers.count
        case .two:
            return followersUsers.count
        case .three:
            return likedTradeIdeas.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch selectedSegmentIndex {
        case .zero:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(with: tradeIdeas[indexPath.row], timeFormat: .short)
            cell.delegate = self
            return cell
        case .one:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(with: followingUsers[indexPath.row])
            return cell
        case .two:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as UserCell
            cell.configureCell(with: followersUsers[indexPath.row])
            return cell
        case .three:
            let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as IdeaCell
            cell.configureCell(with: likedTradeIdeas[indexPath.row], timeFormat: .short)
            cell.delegate = self
            return cell
        }
    }
    
    // DZNEmptyDataSet delegate functions
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
        
        switch selectedSegmentIndex {
        case .zero:
            if !isQueryingForTradeIdeas && tradeIdeas.count == 0 {
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