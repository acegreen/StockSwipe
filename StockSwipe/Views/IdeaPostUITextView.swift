//
//  IdeaPostUITextView.swift
//  StockSwipe
//
//  Created by Ace Green on 7/2/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

protocol IdeaPostTextViewDelegate {
    func textViewDidChangeTextInRange(_ textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String, currentText: NSString, updatedText: String)
}

class IdeaPostUITextView: UITextView, UITextViewDelegate, DetectTags {
    
    var textViewDelegate: IdeaPostTextViewDelegate!

//    override init(frame: CGRect, textContainer: NSTextContainer?) {
//        super.init(frame: frame, textContainer: textContainer)
//        self.delegate = self
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.delegate = self
//    }
//    
//    // TextView Delegates
//    
//    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
//        
//        let currentText:NSString = textView.text
//        let updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
//        
//        if updatedText.isEmpty {
//            
//            textView.textColor = UIColor.lightGrayColor()
//            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
//            
//        } else if textView.textColor == UIColor.lightGrayColor() && !text.isEmpty {
//            
//            textView.text = nil
//            textView.textColor = UIColor.blackColor()
//            
//        }
//        
//        self.textViewDelegate?.textViewDidChangeTextInRange(textView, shouldChangeTextInRange: range, replacementText: text, currentText: currentText, updatedText: updatedText)
//        
//        return true
//    }
//    
//    func textViewDidChangeSelection(textView: UITextView) {
//        if textView.textColor == UIColor.lightGrayColor() {
//            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
//        }
//    }

}
