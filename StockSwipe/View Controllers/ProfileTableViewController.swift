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

class ProfileTableViewController: UITableViewController, CellType, SubSegmentedControlDelegate, SegueHandlerType {
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
        case UserCell = "UserCell"
    }
    
    enum SegueIdentifier: String {
        case TradeIdeaDetailSegueIdentifier = "TradeIdeaDetailSegueIdentifier"
        case ProfileDetailSegueIdentifier = "ProfileDetailSegueIdentifier"
    }
    
    var delegate: ProfileTableVieDelegate!
    
    var user: User?
    var isCurrentUserBlocked: Bool = false
    var isUserBlocked: Bool = false
    var shouldShowProfile: Bool = true
    
    var tradeIdeas = [TradeIdea]()
    var followingUsers = [PFUser]()
    var followersUsers = [PFUser]()
    var likedTradeIdeas = [TradeIdea]()
    
    var selectedSegmentIndex: ProfileContainerController.SegmentIndex = ProfileContainerController.SegmentIndex(rawValue: 0)!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var avatarImage:UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var followButton: FollowButton!
    
    @IBAction func followButtonPressed(sender: FollowButton) {
        self.registerFollow(sender)
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        
        getProfile()
        
        switch selectedSegmentIndex {
        case .Zero, .Three:
            self.getUserTradeIdeas()
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
        
        // Remove follow/unfollow buttons if user == currentUser
        if user?.userObject.objectId == PFUser.currentUser()?.objectId {
            followButton.hidden = true
        }
        
        // set tableView properties
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200.0
        
        self.getProfile()
        self.getUserTradeIdeas()
        
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
    
    func getProfile() {
        
        guard let user = user else { return }
        
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
        
        if let username = user.userObject.username {
            self.usernameLabel.text = username
        }
        
        if let location = user.userObject.objectForKey("location") as? String {
            self.locationLabel.text = location
        }
        
        checkBlocked()
        checkFollow(self.followButton)
    }
    
    func checkBlocked() {

        guard let currentUser = PFUser.currentUser() else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] where users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            self.isCurrentUserBlocked = true
            self.shouldShowProfile = false
            self.tableView.reloadEmptyDataSet()
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] where blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            self.isUserBlocked = true
            self.tableView.reloadEmptyDataSet()
            return
        }
    }
    
    func getUserTradeIdeas() {
        
        guard !isCurrentUserBlocked else { return }
        guard let userObject = self.user?.userObject else { return }
        
        switch selectedSegmentIndex {
        case .Zero:
            
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: userObject, skip: 0, limit: 15) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    self.tradeIdeas = []
                    for tradeIdeaObject: PFObject in tradeIdeasObjects {
                        
                        let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                        
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
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("liked_by", object: userObject, skip: 0, limit: 15) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    self.likedTradeIdeas = []
                    for tradeIdeaObject: PFObject in tradeIdeasObjects {
                        
                        let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                        
                        self.likedTradeIdeas.append(tradeIdea)
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
        }
    }
    
    func loadMoreTradeIdeas(skip skip: Int) {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        if self.refreshControl?.refreshing == false && !self.footerActivityIndicator.isAnimating() {
            self.footerActivityIndicator.startAnimating()
        }
        
        switch selectedSegmentIndex {
        case .Zero:
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: user.userObject, skip: skip, limit: 15) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        for tradeIdeaObject: PFObject in tradeIdeasObjects {
                            
                            let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                            
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
            
            QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("liked_by", object: user.userObject, skip: skip, limit: 15) { (result) in
                
                do {
                    
                    let tradeIdeasObjects = try result()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        for tradeIdeaObject: PFObject in tradeIdeasObjects {
                            
                            let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, likeCount: tradeIdeaObject["liked_by"]?.count, reshareCount: tradeIdeaObject["reshared_by"]?.count, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                            
                            //add datasource object here for tableview
                            self.likedTradeIdeas.append(tradeIdea)
                            
                            //now insert cell in tableview
                            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.likedTradeIdeas.count - 1, inSection: 0)], withRowAnimation: .None)
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
        }
    }
    
    func getUsersFollowing() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        QueryHelper.sharedInstance.queryUserActivityFor(user.userObject, toUser: nil) { (result) in
            
            do {
                
                let userActivityObjects = try result()
                
                self.followingUsers = []
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if let userActivityObjects = userActivityObjects {
                        for userActivity in userActivityObjects {
                            let toUser = userActivity["toUser"] as! PFUser
                            self.followingUsers.append(toUser)
                        }
                        self.tableView.reloadData()
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
        }
    }
    
    func getUsersFollowers() {
        
        guard !isCurrentUserBlocked else { return }
        guard let user = user else { return }
        
        QueryHelper.sharedInstance.queryUserActivityFor(nil, toUser: user.userObject) { (result) in
            
            do {
                
                let userActivityObjects = try result()
                
                self.followersUsers = []
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if let userActivityObjects = userActivityObjects {
                        for userActivity in userActivityObjects {
                            let fromUser = userActivity["fromUser"] as! PFUser
                            self.followersUsers.append(fromUser)
                        }
                        self.tableView.reloadData()
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
        }
    }
    
    func checkFollow(sender: FollowButton) {
        
        guard let currentUser = PFUser.currentUser() else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] where users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            sender.buttonState = FollowButton.state.Disabled
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] where blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            sender.buttonState = FollowButton.state.Blocked
            return
        }
        
        QueryHelper.sharedInstance.queryUserActivityFor(currentUser, toUser: userObject) { (result) in
            
            do {
                
                let userActivityObject = try result()
                
                if userActivityObject?.first != nil {
                    sender.buttonState = FollowButton.state.Following
                } else {
                    sender.buttonState = FollowButton.state.NotFollowing
                }
                
            } catch {
            }
        }
    }
    
    func registerFollow(sender: FollowButton) {
        
        guard let currentUser = PFUser.currentUser() else {
            Functions.isUserLoggedIn(UIApplication.topViewController()!)
            return
        }
        
        guard let userObject = self.user?.userObject else { return }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser], let blockedUser = blocked_users .find({ $0.objectId == userObject.objectId }) {
            
            currentUser.removeObject(blockedUser, forKey: "blocked_users")
            
            currentUser.saveEventually({ (success, error) in
                if success {
                    sender.buttonState = FollowButton.state.NotFollowing
                }
            })
            return
        }
        
        QueryHelper.sharedInstance.queryUserActivityFor(currentUser, toUser: userObject) { (result) in
            
            do {
                
                let userActivityObject = try result()
                
                if userActivityObject?.first == nil {
                    
                    let userActivityObject = PFObject(className: "UserActivity")
                    userActivityObject["fromUser"] = currentUser
                    userActivityObject["toUser"] = userObject
                    
                    userActivityObject.saveInBackgroundWithBlock({ (success, error) in
                        
                        if success {
                            sender.buttonState = FollowButton.state.Following
                        } else {
                            sender.buttonState = FollowButton.state.NotFollowing
                        }
                    })
                } else {
                    userActivityObject?.first?.deleteEventually()
                    sender.buttonState = FollowButton.state.NotFollowing
                }
                
            } catch {
                
                // TO-DO: handle error
                
            }
        }

    }
    
    func updateRefreshDate() {
        
        let title: String = "Last Update: \(NSDate().formattedAsTimeAgo())"
        let attrsDictionary = [
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
        
        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: attrsDictionary)
        self.refreshControl?.attributedTitle = attributedTitle
    }
    
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
            cell.configureCell(tradeIdeas[indexPath.row])
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
            cell.configureCell(likedTradeIdeas[indexPath.row])
            cell.delegate = self
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if user?.userObject.objectId == PFUser.currentUser()?.objectId {
            return true
        }
        
        return false
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.loadMoreTradeIdeas(skip: tradeIdeas.count)
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
            
        case .ProfileDetailSegueIdentifier:
            let profileContainerController = segue.destinationViewController as! ProfileContainerController
            profileContainerController.navigationItem.rightBarButtonItem = nil
            
            guard let cell = sender as? UserCell  else { return }
            profileContainerController.user = User(userObject: cell.user)

        }
    }
}

extension ProfileTableViewController: IdeaPostDelegate {
    
    func ideaPosted(with tradeIdea: TradeIdea, tradeIdeaTyp: Constants.TradeIdeaType) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tradeIdeas.insert(tradeIdea, atIndex: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        
        self.tableView.reloadEmptyDataSet()
    }
    
    func ideaDeleted(with parseObject: PFObject) {
        
        if let tradeIdea = self.tradeIdeas.find ({ $0.parseObject.objectId == parseObject.objectId }) {
            let indexPath = NSIndexPath(forRow: self.tradeIdeas.indexOf(tradeIdea)!, inSection: 0)
            self.tradeIdeas.removeObject(tradeIdea)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        if tradeIdeas.count == 0 {
            self.tableView.reloadEmptyDataSet()
        }
    }
}

extension ProfileTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // DZNEmptyDataSet delegate functions
    
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
        
        guard !isUserBlocked else {
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
        
        guard !isUserBlocked else {
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