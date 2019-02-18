//
//  WatchlistCardCollectionViewCell.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-30.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import QuartzCore

class WatchlistCardCollectionViewCell: UICollectionViewCell, ResetAbleTransform {
    
    let overlayWidth:  CGFloat = 100.0
    let overlayHeight: CGFloat = 50.0

    var disabledHighlightedAnimation = false
    
    @IBOutlet weak var cardView: CardView!
    
    func configure(with card: Card) {
        self.cardView.configure(with: card)
    }
    
    func clear() {
        self.cardView.clear()
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                // Set self border to show selection
                self.layer.borderWidth = 1.5
                self.layer.borderColor = Constants.SSColors.grey.cgColor
                
            } else {
                // Remove bold cell border
                self.layer.borderWidth = 0
                self.layer.borderColor = UIColor.clear.cgColor
                
            }
        }
    }
    
    func freezeAnimations() {
        disabledHighlightedAnimation = true
        layer.removeAllAnimations()
    }
    
    func unfreezeAnimations() {
        disabledHighlightedAnimation = false
    }
    
    func resetTransform() {
        transform = .identity
    }
    
    // Make it appears very responsive to touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animate(isHighlighted: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animate(isHighlighted: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animate(isHighlighted: false)
    }
    
    private func animate(isHighlighted: Bool, completion: ((Bool) -> Void)? = nil) {
        
        guard !disabledHighlightedAnimation else { return }
        
        let animationOptions: UIView.AnimationOptions = Constants.isEnabledAllowsUserInteractionWhileHighlightingCard
            ? [.allowUserInteraction] : []
        if isHighlighted {
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 0,
                           options: animationOptions, animations: {
                            self.transform = .init(scaleX: Constants.cardHighlightedFactor, y: Constants.cardHighlightedFactor)
            }, completion: completion)
        } else {
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 0,
                           options: animationOptions, animations: {
                            self.transform = .identity
            }, completion: completion)
        }
    }
}
