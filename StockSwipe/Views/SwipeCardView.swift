//
//  ChoosePersonView.swift
//  SwiftLikedOrNope
//
// Copyright (c) 2014 to present, Richard Burdish @rjburdish
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit
import MDCSwipeToChoose

@IBDesignable
class SwipeCardView: MDCSwipeToChooseView, ResetAbleTransform {
    
    // Our custom view from the XIB file
    var cardView: CardView!
    var card: Card! {
        didSet {
            if self.cardView != nil {
                self.cardView.card = card
            }
        }
    }
    
    var disabledHighlightedAnimation = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadCardViewFromNib()
    }
    
    init(frame: CGRect, card: Card, options: MDCSwipeToChooseViewOptions?) {
        super.init(frame: frame, options: options)
        self.card = card
        
        loadCardViewFromNib()
        self.cardView.card = card
        
        self.addCenterMotionEffectsXY(withOffset: motionOffset)
    }
    
    func loadCardViewFromNib() {
        self.cardView = CardView(frame: self.frame)
        self.addSubview(self.cardView)
        self.sendSubviewToBack(self.cardView)
        self.cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.cardView.topAnchor.constraint(equalTo: self.topAnchor),
            self.cardView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.cardView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.cardView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])

        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
    }
    
    func freezeAnimations() {
        disabledHighlightedAnimation = true
        layer.removeAllAnimations()
    }
    
    func unfreezeAnimations() {
        disabledHighlightedAnimation = false
    }
    
    func resetTransform() {
//        transform = .identity
    }
    
    // Make it appears very responsive to touch
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        animate(isHighlighted: true)
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        animate(isHighlighted: false)
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesCancelled(touches, with: event)
//        animate(isHighlighted: false)
//    }
//
//    private func animate(isHighlighted: Bool, completion: ((Bool) -> Void)? = nil) {
//
//        guard !disabledHighlightedAnimation else { return }
//
//        let animationOptions: UIView.AnimationOptions = Constants.isEnabledAllowsUserInteractionWhileHighlightingCard
//            ? [.allowUserInteraction] : []
//        if isHighlighted {
//            UIView.animate(withDuration: 1,
//                           delay: 0,
//                           usingSpringWithDamping: 1,
//                           initialSpringVelocity: 0,
//                           options: animationOptions, animations: {
//                            self.transform = .init(scaleX: Constants.cardHighlightedFactor, y: Constants.cardHighlightedFactor)
//            }, completion: completion)
//        } else {
//            UIView.animate(withDuration: 1,
//                           delay: 0,
//                           usingSpringWithDamping: 1,
//                           initialSpringVelocity: 0,
//                           options: animationOptions, animations: {
//                            self.transform = .identity
//            }, completion: completion)
//        }
//    }
}
