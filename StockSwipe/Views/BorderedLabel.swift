//
//  BorderedLabel.swift
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

class BorderedLabel: UILabel {

    init(frame: CGRect, text: NSString, color: UIColor, angle: Double) {
        
        super.init(frame: frame)
        
        constructLabel(text, color: color, angle: angle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func constructLabel(text: NSString, color: UIColor, angle: Double) {
        
        self.layer.borderColor = color.CGColor
        self.layer.borderWidth = 3.0
        self.layer.cornerRadius = 7.5
    
        self.text = text.uppercaseString
        self.textAlignment = NSTextAlignment.Center
        self.font = UIFont (name: "HelveticaNeue-CondensedBlack", size: 25.0)
        self.textColor = color
        
        self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, CGFloat(Functions.degreesToRadians(angle)))
        
    }
}