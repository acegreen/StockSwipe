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

class NoChartView: UIView {
    
    var label: UILabel!
    
    init(frame: CGRect, text: String) {
        
        super.init(frame: frame)
        
        self.setupView()
        self.constructLabel(text)
        
        self.addCenterMotionEffectsXY(withOffset: motionOffset)
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    func setupView() {
        
        self.backgroundColor = UIColor.white
        self.layer.masksToBounds = false;
        self.layer.cornerRadius = Constants.cardCornerRadius
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.gray.cgColor

    }
    
    func constructLabel(_ text: String) -> Void {
        self.label = UILabel(frame: CGRect(x: 50, y: 0, width: self.bounds.width - 100, height: self.bounds.height))
        self.label.textAlignment = NSTextAlignment.center
        self.label.numberOfLines = 0
        self.label.text = text
        self.label.font = Constants.SSFonts.makeFont(size:35)
        self.label.textColor = UIColor.gray
        self.addSubview(self.label)
    }
}
