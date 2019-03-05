//
//  TutortialPageViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 3/5/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    // hard coded
    let pageCount = 5

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self

        let initialViewController = self.viewControllerAtIndex(0)
        self.setViewControllers([initialViewController], direction: .forward, animated: true, completion: nil)
    }
    
    private func viewControllerAtIndex(_ index: Int) -> TutorialContentViewController {
        
        if ((self.pageCount == 0) || (index >= self.pageCount)) {
            return TutorialContentViewController()
        }
        
        let vc: TutorialContentViewController = Constants.Storyboards.loginStoryboard.instantiateViewController(withIdentifier: "TutorialContentViewController") as! TutorialContentViewController
        
        var imageName: String!
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            imageName = "tutorial-page-" + String(index + 1) + "-iPad"
        default:
            imageName = "tutorial-page-" + String(index + 1) + "-iPhone"
        }
        
        vc.imageFile = imageName
        vc.pageIndex = index
        
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! TutorialContentViewController
        var index = vc.pageIndex as Int
        
        if (index == 0 || index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let vc = viewController as! TutorialContentViewController
        var index = vc.pageIndex as Int
        
        if (index == NSNotFound) {
            return nil
        }
        
        index += 1
        
        if (index == self.pageCount) {
            return nil
        }
        
        return self.viewControllerAtIndex(index)
        
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pageCount
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
