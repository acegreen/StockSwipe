//
//  OverviewContainerPageViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/10/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import DataCache
import SafariServices

protocol OverviewContainerPageViewControllerDelegate: class {
    
    func overviewPageViewController(overviewPageViewController: OverviewContainerPageViewController,
                                    didUpdatePageCount count: Int)
    
    func overviewPageViewController(overviewPageViewController: OverviewContainerPageViewController,
                                    didUpdatePageIndex index: Int)
    
}

class OverviewContainerPageViewController: UIPageViewController {
    
    weak var overviewDelegate: OverviewContainerPageViewControllerDelegate?
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [Constants.Storyboards.mainStoryboard.instantiateViewController(withIdentifier: "OverviewFirstPageViewController") as! OverviewFirstPageViewController,
                Constants.Storyboards.tradeIdeaStoryboard.instantiateViewController(withIdentifier: "TradeIdeasTableViewController") as! TradeIdeasTableViewController]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.clear
        
        if let initialViewController = orderedViewControllers.first {
            scrollToViewController(viewController: initialViewController)
        }
        
        overviewDelegate?.overviewPageViewController(overviewPageViewController: self, didUpdatePageCount: orderedViewControllers.count)
    }
    
    func scrollToNextViewController() {
        if let visibleViewController = viewControllers?.first,
            let nextViewController = pageViewController(self, viewControllerAfter: visibleViewController) {
            scrollToViewController(viewController: nextViewController)
        }
    }
    
    func scrollToViewController(index newIndex: Int) {
        if let firstViewController = viewControllers?.first,
            let currentIndex = orderedViewControllers.firstIndex(of: firstViewController) {
            let direction: UIPageViewController.NavigationDirection = newIndex >= currentIndex ? .forward : .reverse
            let nextViewController = orderedViewControllers[newIndex]
            scrollToViewController(viewController: nextViewController, direction: direction)
        }
    }
    
    private func scrollToViewController(viewController: UIViewController,
                                        direction: UIPageViewController.NavigationDirection = .forward) {
        setViewControllers([viewController],
                           direction: direction,
                           animated: true,
                           completion: { (finished) -> Void in
                            self.notifyOverviewDelegateOfNewIndex()
        })
    }
    
    private func notifyOverviewDelegateOfNewIndex() {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.firstIndex(of: firstViewController) {
            overviewDelegate?.overviewPageViewController(overviewPageViewController: self, didUpdatePageIndex: index)
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension OverviewContainerPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count

        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
}

extension OverviewContainerPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        notifyOverviewDelegateOfNewIndex()
    }
    
}
