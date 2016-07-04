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
    func subDidSelectSegment(segmentedControl: UISegmentedControl)
}

class ProfileContainerController: UIViewController, UIScrollViewDelegate, ProfileTableVieDelegate {
    
    enum SegmentIndex: Int {
        case Zero
        case One
        case Two
        case Three
    }
    
    @IBOutlet var containerView: UIView!

    @IBOutlet var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentedControlAction(sender: UISegmentedControl) {
        selectedSegmentIndex = SegmentIndex(rawValue: sender.selectedSegmentIndex)!
        self.delegate.subDidSelectSegment(sender)
    }
    
    @IBOutlet var barOffset: NSLayoutConstraint!
    @IBOutlet var headerHeight: NSLayoutConstraint!
        
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var selectedSegmentIndex: SegmentIndex = SegmentIndex(rawValue: 0)!
    
    var delegate: SubSegmentedControlDelegate!
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.zPosition = 0
        segmentedControl.layer.zPosition = 1
        
        layoutSegementedControl()
    }

    func subScrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        
        var segmentedControlTransform = CATransform3DIdentity
        segmentedControlTransform = CATransform3DTranslate(segmentedControlTransform, 0, max(-barOffset.constant, -offset), 0)
        segmentedControl.layer.transform = segmentedControlTransform
    }
    
    func didReloadProfileTableView() {
        layoutSegementedControl()
    }
    
    func layoutSegementedControl() {
        
        guard var user = user else { return }
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .ByWordWrapping
        paragraphStyle.alignment = .Center
        
        var attributedTitle: NSAttributedString!
        var attributedSubtitle: NSAttributedString!
        
        let titleAttrsDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(22),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        let subTitleAttrsDictionary = [
            NSFontAttributeName: UIFont.systemFontOfSize(12),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        user.getIdeasCount({ (countString) in
            
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Ideas", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.appendAttributedString(attributedTitle)
            mutableAttString.appendAttributedString(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.appendAttributedString(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 0, animated: true)
        })
        
        user.getFollowingCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Following", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.appendAttributedString(attributedTitle)
            mutableAttString.appendAttributedString(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.appendAttributedString(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 1, animated: true)
        })
        
        user.getFollowersCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Followers", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.appendAttributedString(attributedTitle)
            mutableAttString.appendAttributedString(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.appendAttributedString(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 2, animated: true)
        })
        
        user.getLikedIdeasCount({ (countString) in
            attributedTitle = NSAttributedString(string: countString, attributes: titleAttrsDictionary)
            attributedSubtitle = NSAttributedString(string: "Liked", attributes: subTitleAttrsDictionary)
            
            let mutableAttString = NSMutableAttributedString()
            mutableAttString.appendAttributedString(attributedTitle)
            mutableAttString.appendAttributedString(NSAttributedString(string: "\n", attributes: nil))
            mutableAttString.appendAttributedString(attributedSubtitle)
            
            self.segmentedControl.segmentWithMultilineAttributedTitle(mutableAttString, atIndex: 3, animated: true)
        })
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedProfile" {
            let profileVC = segue.destinationViewController as! ProfileTableViewController
            self.delegate = profileVC
            profileVC.delegate = self
            profileVC.user = user
        }
    }

}

