//
//  WatchlistCardCollectionViewCell.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-05-30.
//  Copyright (c) 2015 Richard Burdish. All rights reserved.
//

import UIKit
import QuartzCore

class WatchlistCardCollectionViewCell: UICollectionViewCell {
    
    let overlayWidth:  CGFloat = 100.0
    let overlayHeight: CGFloat = 50.0
    
    @IBOutlet weak var cardView: SwipeCardView!
    @IBOutlet weak var overlayLabel: UILabel!
    
    func configure(with card: Card) {
        
        let symbol = card.symbol
        let companyName = card.companyName
        
        self.cardView.card = card
        self.cardView.symbolLabel.text = "\(symbol)"
        self.cardView.companyNameLabel.text = "\(companyName)"
        self.cardView.exchangeLabel.text = "\(card.exchange)"
        self.cardView.setCardInfo()
        
        guard let cardModel = card.cardModel, let userChoice = Constants.UserChoices(rawValue: cardModel.userChoice) else { return }
        
        switch userChoice {
        
        case .SHORT:
            self.overlayLabel.layer.borderColor = UIColor.red.cgColor
            self.overlayLabel.text = "\(Constants.UserChoices.SHORT.rawValue)"
            self.overlayLabel.textColor = UIColor.red
            self.overlayLabel.transform = CGAffineTransform.identity.rotated(by: 15.toRadians())
            
        case .LONG:
            self.overlayLabel.layer.borderColor = Constants.SSColors.green.cgColor
            self.overlayLabel.text = "\(Constants.UserChoices.LONG.rawValue)"
            self.overlayLabel.textColor = Constants.SSColors.green
            self.overlayLabel.transform = CGAffineTransform.identity.rotated(by: -15.toRadians())
        case .SKIP:
            break
        }
        
        self.overlayLabel.layer.borderWidth = 3.0
        self.overlayLabel.layer.cornerRadius = 7.5
    }
    
    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                
                // Set self border to show selection
                self.layer.cornerRadius = 7.5
                self.layer.borderWidth = 1.5
                self.layer.borderColor = Constants.SSColors.grey.cgColor
                
            } else {
                
                // Remove bold cell border
                self.layer.cornerRadius = 7.5
                self.layer.borderWidth = 0.5
                self.layer.borderColor = Constants.SSColors.grey.cgColor
                
            }
        }
    }

}
