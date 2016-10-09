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
import Foundation
import MDCSwipeToChoose

class SwipeChartView: MDCSwipeToChooseView {
    
    var chart: Chart!
    var imageView: UIImageView!
    var informationView: UIView!
    var nameLabel: UILabel!
    var likedImageLabelView:ImagelabelView!
    var nopeImageLabelView: ImagelabelView!
    
    let rightPadding:CGFloat = 20.0
    let leftPadding:CGFloat = 10.0
    
    init(frame: CGRect, chart: Chart, options: MDCSwipeToChooseViewOptions?) {
        
        super.init(frame: frame, options: options)
        
        self.backgroundColor = UIColor.white
        self.chart = chart
        
        self.imageView = UIImageView(frame: CGRect(x: 0, y: Constants.chartImageTopPadding, width: self.bounds.width, height: self.bounds.height - Constants.informationViewHeight - Constants.chartImageTopPadding))
        self.imageView.image = chart.image
        
        if !imageView .isDescendant(of: self) {
            
            self.addSubview(imageView)
            self.sendSubview(toBack: imageView)
            
        }
        
        self.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        self.imageView.autoresizingMask = self.autoresizingMask
        self.imageView.layer.masksToBounds = true
        
        self.addCenterMotionEffectsXY(withOffset: motionOffset)
        
        constructInformationView()
        //constructNameLabel()
        constructLongImageLabelView()
        constructShortImageLabelView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    func constructInformationView() -> Void {
        
        let informationViewFrame:CGRect = CGRect(x: 0, y: self.imageView.bounds.height + Constants.chartImageTopPadding, width: self.bounds.width, height: Constants.informationViewHeight);
        self.informationView = UIView(frame:informationViewFrame)
        self.informationView.backgroundColor = UIColor.white
        self.informationView.clipsToBounds = true
        self.informationView.autoresizingMask = self.autoresizingMask
        
        if !informationView .isDescendant(of: self) {
            
            self.addSubview(self.informationView)
        }
    }
    
//    func constructNameLabel() -> Void {
//
//        let frame:CGRect = CGRectMake(leftPadding,
//            topPadding,
//            floor(CGRectGetWidth(self.informationView.frame)/2),
//            CGRectGetHeight(self.informationView.frame) - topPadding)
//        self.nameLabel = UILabel(frame:frame)
//        self.nameLabel.text = "\(chart.symbol)"
//        
//        if !nameLabel .isDescendantOfView(self) {
//            
//            self.informationView.addSubview(self.nameLabel)
//        }
//    }
    
    func constructLongImageLabelView() -> Void {
        
        let image: UIImage = UIImage(named: "long")!
        self.likedImageLabelView = self.buildImageLabelViewLeftOf(self.informationView.bounds.width - rightPadding, image: image, text: chart.longCount.suffixNumber() ?? String(0))
        likedImageLabelView.imageView.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        likedImageLabelView.imageView.tintColor = UIColor.black
        
        if !likedImageLabelView.isDescendant(of: self) {
            self.informationView.addSubview(self.likedImageLabelView)
        }
    }
    
    func constructShortImageLabelView() -> Void {
        
        guard likedImageLabelView.isDescendant(of: self) else { return }
        
        let image:UIImage = UIImage(named:"short")!
        self.nopeImageLabelView = buildImageLabelViewLeftOf(self.likedImageLabelView.frame.minX, image:image, text: chart.shortCount.suffixNumber() ?? String(0))
        nopeImageLabelView.imageView.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        nopeImageLabelView.imageView.tintColor = UIColor.black
        
        if !nopeImageLabelView .isDescendant(of: self) {
            self.informationView.addSubview(self.nopeImageLabelView)
        }
    }
    
    func buildImageLabelViewLeftOf(_ x:CGFloat, image:UIImage, text:String) -> ImagelabelView {
        
        let frame:CGRect = CGRect(x: x - 80, y: 0,
            width: image.size.width,
            height: self.informationView.bounds.height)
        let view:ImagelabelView = ImagelabelView(frame:frame, image:image, text:text)
        view.autoresizingMask = UIViewAutoresizing.flexibleLeftMargin
        return view
    }
}
