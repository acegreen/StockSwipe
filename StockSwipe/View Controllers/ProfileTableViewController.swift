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

protocol SubScrollDelegate {
    func subScrollViewDidScroll(scrollView: UIScrollView)
}

class ProfileTableViewController: UITableViewController, CellType, SubSegmentedControlDelegate {
    
    enum SegmentIndex: Int {
        case Zero
        case One
        case Two
        case Three
    }
    
    enum CellIdentifier: String {
        case IdeaCell = "IdeaCell"
        case FollowingCell = "FollowingCell"
        case FollowersCell = "FollowersCell"
        case LikedIdeaCell = "LikedIdeaCell"
    }
    
    var delegate: SubScrollDelegate!
    
    var user: PFUser?

    var tradeIdeas = [TradeIdea]()
    var followingUsers = [PFUser]()
    var followersUsers = [PFUser]()
    var likedTradeIdeas = [TradeIdea]()
    
    var selectedSegmentIndex: SegmentIndex = SegmentIndex(rawValue: 0)!
    
    @IBOutlet var headerView: UIView!
    @IBOutlet var avatarImage:UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    
    @IBOutlet var unfollowButton: CircleButton!
    
    @IBAction func UnfollowButtonPressed(sender: AnyObject) {
        
    }
    
    @IBOutlet var followButton: CircleButton!
    
    
    @IBAction func followButtonPressed(sender: AnyObject) {
        
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        
        self.getTradeIdeas(user, skip: 0)
    }
    
    @IBOutlet var footerActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove follow/unfollow buttons if user == currentUser
        if user?.objectId == PFUser.currentUser()?.objectId {
            
            followButton.hidden = true
            unfollowButton.hidden = true
        }
        
        // set tableView properties
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100.0
        
        self.getProfile(user)
        self.getTradeIdeas(user, skip: 0)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    func subDidSelectSegment(segmentedControl: UISegmentedControl) {
        
        selectedSegmentIndex = SegmentIndex(rawValue: segmentedControl.selectedSegmentIndex)!
        self.tableView.reloadData()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.delegate.subScrollViewDidScroll(scrollView)
    }

    func getProfile(user: PFUser?) {
        
        guard let user = user else { return }
        
        if let profileImageURL = user.objectForKey("profile_image_url") as? String {
            
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
        
        if let username = user.username {
            self.usernameLabel.text = username
        }
        
        if let location = user.objectForKey("location") as? String {
            self.locationLabel.text = location
        }
    }
    
    func getTradeIdeas(user: PFUser?, skip: Int) {
        
        guard let user = user else {
            return
        }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: user, skip: skip) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                self.tradeIdeas = []
                for tradeIdeaObject: PFObject in tradeIdeasObjects {
                    
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                    
                    self.tradeIdeas.append(tradeIdea)
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    
                    if self.refreshControl?.refreshing == true {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    self.updaterefreshDate()
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.refreshControl?.refreshing == true {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    func loadMoreTradeIdeas(user: PFUser?, skip: Int) {
        
        guard let user = user where user.authenticated else {
            return
        }
        
        if self.refreshControl?.refreshing == false && !self.footerActivityIndicator.isAnimating() {
            self.footerActivityIndicator.startAnimating()
        }
        
        QueryHelper.sharedInstance.queryTradeIdeaObjectsFor("user", object: user, skip: skip) { (result) in
            
            do {
                
                let tradeIdeasObjects = try result()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    for tradeIdeaObject: PFObject in tradeIdeasObjects {
                        
                    let tradeIdea = TradeIdea(user: tradeIdeaObject["user"] as! PFUser, stock: tradeIdeaObject["stock"] as! PFObject, description: tradeIdeaObject["description"] as! String, publishedDate: tradeIdeaObject.createdAt, parseObject: tradeIdeaObject)
                        
                        //add datasource object here for tableview
                        self.tradeIdeas.append(tradeIdea)
                        
                        //now insert cell in tableview
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.tradeIdeas.count - 1, inSection: 0)], withRowAnimation: .None)
                    }
                    
                    if self.footerActivityIndicator?.isAnimating() == true {
                        self.footerActivityIndicator.stopAnimating()
                    }
                    
                    self.updaterefreshDate()
                })
                
            } catch {
                
                // TO-DO: Show sweet alert with Error.message()
                if self.footerActivityIndicator?.isAnimating() == true {
                    self.footerActivityIndicator.stopAnimating()
                }
                
            }
        }
    }
    
    func updaterefreshDate() {
        
        let refreshDateFormatter = NSDateFormatter()
        refreshDateFormatter.dateStyle = .LongStyle
        refreshDateFormatter.timeStyle = .ShortStyle
        
        let title: String = "Last Update: \(refreshDateFormatter.stringFromDate(NSDate()))"
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
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.IdeaCell.rawValue, forIndexPath: indexPath) as! IdeaCell
            cell.configureIdeaCell(tradeIdeas[indexPath.row])
            return cell
        case .One:
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.FollowingCell.rawValue, forIndexPath: indexPath) as! FollowingCell
            return cell
        case .Two:
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.FollowersCell.rawValue, forIndexPath: indexPath) as! FollowersCell
            return cell
        case .Three:
            let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.LikedIdeaCell.rawValue, forIndexPath: indexPath) as! LikedIdeaCell
            return cell
        }
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if user == PFUser.currentUser() {
            return true
        }
        
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            tradeIdeas[indexPath.row].parseObject.deleteEventually()
            tradeIdeas.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let offset = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height))
        if offset >= 0 && offset <= 5 {
            // This is the last cell so get more data
            self.loadMoreTradeIdeas(user, skip: tradeIdeas.count)
        }
    }
}

extension ProfileTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // DZNEmptyDataSet delegate functions
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        
        return UIImage(assetIdentifier: .IdeaGuyImage)
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let attributedTitle: NSAttributedString!
            
        attributedTitle = NSAttributedString(string: "No Data!", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(24)])
        
        return attributedTitle
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let attributedDescription: NSAttributedString!
        attributedDescription = NSAttributedString(string: "Table is empty", attributes: [NSFontAttributeName: UIFont.systemFontOfSize(18), NSParagraphStyleAttributeName: paragraphStyle])
        
        return attributedDescription
        
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
       return (self.tableView.frame.midY - self.headerView.frame.midY) / 2
    }
}