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

class ProfileContainerController: UIViewController, UIScrollViewDelegate, SubScrollDelegate {
    
    @IBOutlet var containerView: UIView!

    @IBOutlet var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentedControlAction(sender: UISegmentedControl) {
        self.delegate.subDidSelectSegment(sender)
    }
    
    @IBOutlet var barOffset: NSLayoutConstraint!
    @IBOutlet var headerHeight: NSLayoutConstraint!
    
    var delegate: SubSegmentedControlDelegate!
    
    var user: PFUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.zPosition = 0
        segmentedControl.layer.zPosition = 1
    }

    func subScrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        
        var segmentedControlTransform = CATransform3DIdentity
        segmentedControlTransform = CATransform3DTranslate(segmentedControlTransform, 0, max(-barOffset.constant, -offset), 0)
        segmentedControl.layer.transform = segmentedControlTransform
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

