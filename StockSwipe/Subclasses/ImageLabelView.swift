//
//  ImageLabelView.swift
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

class ImagelabelView: UIView {
    var imageView: UIImageView!
    var label: UILabel!

    init(frame: CGRect, image: UIImage, text: String) {
        
        super.init(frame: frame)
        
        constructImageView(image)
        constructLabel(text)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func constructImageView(_ image:UIImage) -> Void {
        
        let framex = CGRect(x: floor((self.bounds.width - image.size.width)/2),
            y: self.frame.midY - (image.size.height / 2),
            width: image.size.width,
            height: image.size.height)
        imageView = UIImageView(frame: framex)
        imageView.image = image
        addSubview(self.imageView)
    }
    
    func constructLabel(_ text:String) -> Void {
        
        let labelTextDistance: CGFloat = 15.0
        let height:CGFloat = 20.0
        
        let frame2 = CGRect(x: self.imageView.frame.width + labelTextDistance, y: self.imageView.frame.midY - (height / 2), width: self.bounds.width, height: height);
        self.label = UILabel(frame: frame2)
        label.text = text
        label.font = Constants.stockSwipeFont
        addSubview(label)
        
    }
}
