//
//  ViewController.swift
//  TwitterProfileClone
//
//  Created by Sean Robertson on 3/16/15.
//  Copyright (c) 2015 Sean Robertson. All rights reserved.
//

import UIKit
import Parse

protocol SubSegmentedControlDelegate {
    func subDidSelectSegment(_ segmentedControl: UISegmentedControl)
}

class ProfileContainerController: UIViewController, UIScrollViewDelegate, ProfileTableVieDelegate {
    
    enum SegmentIndex: Int {
        case zero
        case one
        case two
        case three
    }
    
    @IBOutlet var containerView: UIView!

    @IBOutlet var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentedControlAction(_ sender: UISegmentedControl) {
        selectedSegmentIndex = SegmentIndex(rawValue: sender.selectedSegmentIndex)!
        self.delegate?.subDidSelectSegment(sender)
    }
    
    @IBOutlet var barOffset: NSLayoutConstraint!
    @IBOutlet var headerHeight: NSLayoutConstraint!
        
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var selectedSegmentIndex: SegmentIndex = SegmentIndex(rawValue: 0)!
    
    var delegate: SubSegmentedControlDelegate!
    
    var user: User?
    var isCurrentUserBlocked: Bool = false
    var isUserBlocked: Bool = false
    var shouldShowProfile: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.zPosition = 0
        segmentedControl.layer.zPosition = 1
        
        checkBlocked()
        
        layoutSegementedControl()
    }

    func subScrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        
        var segmentedControlTransform = CATransform3DIdentity
        segmentedControlTransform = CATransform3DTranslate(segmentedControlTransform, 0, max(-barOffset.constant, -offset), 0)
        segmentedControl.layer.transform = segmentedControlTransform
    }
    
    func didRefreshProfileTableView() {
        layoutSegementedControl()
    }
    
    func checkBlocked() {
        
        guard let currentUser = PFUser.current() else { return }
        guard let userObject = self.user?.userObject else { return }
        
        if let users_blocked_users = userObject["blocked_users"] as? [PFUser] , users_blocked_users.find({ $0.objectId == currentUser.objectId }) != nil {
            self.isCurrentUserBlocked = true
            self.shouldShowProfile = false
            return
        }
        
        if let blocked_users = currentUser["blocked_users"] as? [PFUser] , blocked_users.find({ $0.objectId == userObject.objectId }) != nil {
            self.isUserBlocked = true
            return
        }
    }
    
    func layoutSegementedControl() {
        
        guard !isCurrentUserBlocked else { return }
        guard var user = user else { return }
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        
        var attributedTitle: NSAttributedString!
        var attributedSubtitle: NSAttributedString!
        
        let titleAttrsDictionary = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 22),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let subTitleAttrsDictionary = [
            NSFontAttributeName: UIFont.systemFont(ofSize: 12),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        user.getIdeasCount({ (countString) in
            
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Ideas", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.append(attributedTitle)
            mutableAttString.append(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.append(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 0, animated: true)
        })
        
        user.getFollowingCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Following", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.append(attributedTitle)
            mutableAttString.append(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.append(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 1, animated: true)
        })
        
        user.getFollowersCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Followers", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.append(attributedTitle)
            mutableAttString.append(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.append(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 2, animated: true)
        })
        
        user.getLikedIdeasCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Liked", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.append(attributedTitle)
            mutableAttString.append(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.append(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 3, animated: true)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedProfile" {
            let profileVC = segue.destination as! ProfileTableViewController
            self.delegate = profileVC
            profileVC.delegate = self
            profileVC.user = user
        }
    }

}

