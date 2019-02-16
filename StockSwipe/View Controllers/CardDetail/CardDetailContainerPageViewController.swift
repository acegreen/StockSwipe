//
//  CardDetailContainerViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/12/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import Foundation

class CardDetailContainerPageViewController: UIPageViewController {
    
    weak var overviewDelegate: CardDetailContainerPageViewControllerDelegate?
    var card: Card!
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        let cardDetailFirstPageViewController = Constants.Storyboards.cardDetailStoryboard.instantiateViewController(withIdentifier: "CardDetailFirstPageViewController") as! CardDetailFirstPageViewController
        cardDetailFirstPageViewController.card = card
        
        let navigationController = Constants.Storyboards.tradeIdeaStoryboard.instantiateInitialViewController() as! UINavigationController
        let tradeIdeasTableViewController = navigationController.viewControllers.first as! TradeIdeasTableViewController
        tradeIdeasTableViewController.stockObject = card.parseObject
        return [cardDetailFirstPageViewController,navigationController ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        view.backgroundColor = UIColor.clear
        
        if let initialViewController = orderedViewControllers.first {
            scrollToViewController(viewController: initialViewController)
        }
        
        overviewDelegate?.cardDetailContainerPageViewController(cardDetailContainerPageViewController: self, didUpdatePageCount: orderedViewControllers.count)
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
                            // Setting the view controller programmatically does not fire
                            // any delegate methods, so we have to manually notify the
                            // 'overviewDelegate' of the new index.
                            self.notifyOverviewDelegateOfNewIndex()
        })
    }
    
    private func notifyOverviewDelegateOfNewIndex() {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.firstIndex(of: firstViewController) {
            overviewDelegate?.cardDetailContainerPageViewController(cardDetailContainerPageViewController: self, didUpdatePageIndex: index)
        }
    }
}

// MARK: UIPageViewControllerDataSource
extension CardDetailContainerPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        // User is on the first view controller and swiped left to loop to
        // the last view controller.
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
        
        // User is on the last view controller and swiped right to loop to
        // the first view controller.
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
}

extension CardDetailContainerPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        notifyOverviewDelegateOfNewIndex()
    }
    
}

protocol CardDetailContainerPageViewControllerDelegate: class {
    
    func cardDetailContainerPageViewController(cardDetailContainerPageViewController: CardDetailContainerPageViewController,
                                    didUpdatePageCount count: Int)
    
    func cardDetailContainerPageViewController(cardDetailContainerPageViewController: CardDetailContainerPageViewController,
                                    didUpdatePageIndex index: Int)
    
}
