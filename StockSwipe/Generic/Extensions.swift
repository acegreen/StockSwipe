//
//  Extensions.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation
import NVActivityIndicatorView

extension CollectionType {
    func find(@noescape predicate: (Self.Generator.Element) throws -> Bool) rethrows -> Self.Generator.Element? {
        return try indexOf(predicate).map({self[$0]})
    }
}

extension Array {
    
    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
    
    mutating func moveItem(fromIndex oldIndex: Index, toIndex newIndex: Index) {
        insert(removeAtIndex(oldIndex), atIndex: newIndex)
    }
    
    func reduceWithIndex<T>(initial: T, @noescape combine: (T, Int, Array.Generator.Element) throws -> T) rethrows -> T {
        var result = initial
        for (index, element) in self.enumerate() {
            result = try combine(result, index, element)
        }
        return result
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}

extension Int {
    
    func suffixNumber() -> String {
        
        var num: Double = Double(self)
        let sign = ((num < 0) ? "-" : "" )
        
        num = fabs(num)
        
        if (num < 1000.0) {
            return "\(sign)\(Int(num))"
        }
        
        let exp:Int = Int(log10(num) / 3.0 ) //log10(1000));
        
        let units:[String] = ["K","M","G","T","P","E"]
        
        let roundedNum:Int = Int(round(10 * num / pow(1000.0,Double(exp))) / 10)
        
        return "\(sign)\(roundedNum)\(units[exp-1])"
    }
}

extension String {
    
    func NSRangeFromRange(range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.startIndex, within: utf16view)
        let to = String.UTF16View.Index(range.endIndex, within: utf16view)
        return NSMakeRange(utf16view.startIndex.distanceTo(from), from.distanceTo(to))
    }
    
    mutating func dropTrailingCharacters(dropCharacterSet: NSCharacterSet) {
        let nonCharacters = dropCharacterSet
        let characterArray = componentsSeparatedByCharactersInSet(nonCharacters)
        if let first = characterArray.first {
            self = first
        }
    }
    
    func URLEncodedString() -> String? {
        let escapedString = self.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
        return escapedString
    }
    
    func decodeEncodedString() -> String? {
        
        guard let encodedData = self.dataUsingEncoding(NSUTF8StringEncoding) else { return self }
        let attributedOptions : [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        
        do {
            
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            
            return attributedString.string
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            
            return self
            
        }
    }
    
    func replace(target: String, withString: String) -> String {
        
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    public var camelCase: String {
        get {
            return self.deburr().words().reduceWithIndex("") { (result, index, word) -> String in
                let lowered = word.lowercaseString
                return result + (index > 0 ? lowered.capitalizedString : lowered)
            }
        }
    }
    
    public var kebabCase: String {
        get {
            return self.deburr().words().reduceWithIndex("", combine: { (result, index, word) -> String in
                return result + (index > 0 ? "-" : "") + word.lowercaseString
            })
        }
    }
    
    public var snakeCase: String {
        get {
            return self.deburr().words().reduceWithIndex("", combine: { (result, index, word) -> String in
                return result + (index > 0 ? "_" : "") + word.lowercaseString
            })
        }
    }
    
    public var startCase: String {
        get {
            return self.deburr().words().reduceWithIndex("", combine: { (result, index, word) -> String in
                return result + (index > 0 ? " " : "") + word.capitalizedString
            })
        }
    }
    
    /// Strip string of accents and diacritics
    func deburr() -> String {
        let mutString = NSMutableString(string: self)
        CFStringTransform(mutString, nil, kCFStringTransformStripCombiningMarks, false)
        return mutString as String
    }
    
    /// Split string into array of 'words'
    func words() -> [String] {
        let hasComplexWordRegex = try! NSRegularExpression(pattern: Constants.RegexHelper.hasComplexWord, options: [])
        let wordRange = NSMakeRange(0, self.characters.count)
        let hasComplexWord = hasComplexWordRegex.rangeOfFirstMatchInString(self, options: [], range: wordRange)
        let wordPattern = hasComplexWord.length > 0 ? Constants.RegexHelper.complexWord : Constants.RegexHelper.basicWord
        let wordRegex = try! NSRegularExpression(pattern: wordPattern, options: [])
        let matches = wordRegex.matchesInString(self, options: [], range: wordRange)
        let words = matches.map { (result: NSTextCheckingResult) -> String in
            if let range = self.rangeFromNSRange(result.range) {
                return self.substringWithRange(range)
            } else {
                return ""
            }
        }
        return words
    }
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
            return from ..< to
        } else {
            return nil
        }
    }
    
    func format(f: String) -> String {
        return NSString(format: "%\(f)f", self) as String
    }
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return self.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor?  {
        get {
            return self.borderColor
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    
    func imageFromLayer() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UISegmentedControl {
    
    func insertSegmentWithMultilineTitle(title: String, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.text = title
        label.textColor = self.tintColor
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Center
        label.lineBreakMode = .ByWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        self.insertSegmentWithImage(label.imageFromLayer(), atIndex: segment, animated: animated)
    }
    
    func insertSegmentWithMultilineAttributedTitle(attributedTitle: NSAttributedString, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.attributedText = attributedTitle
        label.numberOfLines = 0
        label.sizeToFit()
        self.insertSegmentWithImage(label.imageFromLayer(), atIndex: segment, animated: animated)
    }
    
    func segmentWithMultilineAttributedTitle(attributedTitle: NSAttributedString, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.attributedText = attributedTitle
        label.numberOfLines = 0
        label.sizeToFit()
        
        self.setImage(label.imageFromLayer(), forSegmentAtIndex: segment)
    }
}

extension UIButton {
    
    public override func intrinsicContentSize() -> CGSize {
        
        let intrinsicContentSize = super.intrinsicContentSize()
        
        let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        
        return CGSize(width: adjustedWidth, height: adjustedHeight)
        
    }
}

extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    class func colorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension NSURL {
    var fragments: [String: String] {
        var results = [String: String]()
        if let pairs = self.fragment?.componentsSeparatedByString("&") where pairs.count > 0 {
            for pair: String in pairs {
                if let keyValue = pair.componentsSeparatedByString("=") as [String]? {
                    results.updateValue(keyValue[1], forKey: keyValue[0])
                }
            }
        }
        return results
    }
    
    func parseQueryString (urlQuery: String, firstSeperator: String, secondSeperator: String) -> NSDictionary? {
        
        let dict: NSMutableDictionary = NSMutableDictionary()
        
        let pairs = urlQuery.componentsSeparatedByString(firstSeperator)
        
        for pair in pairs {
            
            let elements: NSArray = pair.componentsSeparatedByString(secondSeperator)
            
            guard let key = elements.objectAtIndex(0).stringByRemovingPercentEncoding,
                let value = elements.objectAtIndex(1).stringByRemovingPercentEncoding
                else { return dict }
            
            dict.setObject(value!, forKey: key!)
        }
        
        return dict
    }
}

extension UIImage {
    
    enum AssetIdentifier: String  {
        
        case ideaGuyImage = "idea_guy"
        case noIdeaBulbImage = "no_idea"
        case newsBigImage = "news_big"
        case xButton = "x"
        case comingSoonImage = "coming_soon"
        case UserBlockedBig = "user_blocked_big"
        case UserDummyImage = "dummy_profile_male_big"
    }
    
    convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }
    
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(CGImage: image.CGImage!)
    }
    
    var rounded: UIImage {
        let imageView = UIImageView(image: self)
        imageView.layer.cornerRadius = size.height < size.width ? size.height/2 : size.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    var circle: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension DetectTags where Self: UITextView {
    
    func detectTags() -> (cashtags: [String], mentions: [String], hashtags: [String]) {
        
        var cashtags = [String]()
        var mentions = [String]()
        var hashtags = [String]()
        
        // turn string in to NSString
        let currentText = self.text
        
        let words:[String] = currentText.componentsSeparatedByCharactersInSet(.whitespaceAndNewlineCharacterSet())
        
        for word in words {
            
            var wordWithTagRemoved = String(word.characters.dropFirst())
            
            if word.hasPrefix("$") {
                
                wordWithTagRemoved.dropTrailingCharacters(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = NSCharacterSet.decimalDigitCharacterSet()
                if wordWithTagRemoved.rangeOfCharacterFromSet(digits) == nil {
                    cashtags.append(wordWithTagRemoved)
                }
                
            } else if word.hasPrefix("@") {
                
                wordWithTagRemoved.dropTrailingCharacters(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                mentions.append(wordWithTagRemoved)
            } else if word.hasPrefix("#") {
                
                wordWithTagRemoved.dropTrailingCharacters(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = NSCharacterSet.decimalDigitCharacterSet()
                if wordWithTagRemoved.rangeOfCharacterFromSet(digits) == nil {
                    hashtags.append(wordWithTagRemoved)
                }
                
            }
        }
        
        return (cashtags, mentions, hashtags)
    }
    
    func resolveTags() {
        
        // this needs to be an array of NSString.  String does not work.
        let words = self.text.componentsSeparatedByCharactersInSet(.whitespaceAndNewlineCharacterSet())
        
        // use storyboard attributes
        var attributes: [String: AnyObject]?
        if let name = self.font?.familyName, let size = self.font?.pointSize {
            attributes = [
                NSFontAttributeName : UIFont(name: name, size: size) as! AnyObject,
                NSForegroundColorAttributeName : (self.textColor ?? UIColor.blackColor())
            ]
        }
        
        // you can staple URLs onto attributed strings
        let attributedString = NSMutableAttributedString(string: self.text, attributes: attributes)
        
        // keep track of where we are as we interate through the string.
        // otherwise, a string like "#test #test" will only highlight the first one.
        var bookmark = text.startIndex
        
        // tag each word if it has a hashtag
        for word in words {
            
            // convert the word from NSString to String
            // this allows us to call "dropFirst" to remove the hashtag
            var stringifiedWord:String = word as String
            
            // drop the hashtag
            stringifiedWord = String(stringifiedWord.characters.dropFirst())
            
            // found a word that is prepended by a hashtag!
            // homework for you: implement @mentions here too.
            if word.hasPrefix("$") {
                
                // drop unwanted characters
                stringifiedWord.dropTrailingCharacters(NSCharacterSet.letterCharacterSet().invertedSet)
                
                let remainingRange = Range(bookmark..<text.endIndex)
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = NSCharacterSet.decimalDigitCharacterSet()
                
                if stringifiedWord.rangeOfCharacterFromSet(digits) != nil {
                    // hashtag contains a number, like "$1"
                    // so not clickable
                } else if let matchRange = text.rangeOfString(word as String, options: .LiteralSearch, range:remainingRange),
                    let escapedString = stringifiedWord.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) {
                    attributedString.addAttribute(NSLinkAttributeName, value: "cash:\(escapedString)", range: text.NSRangeFromRange(matchRange))
                }
                
            } else if word.hasPrefix("@") {
                // drop unwanted characters
                stringifiedWord.dropTrailingCharacters(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                
                let remainingRange = Range(bookmark..<text.endIndex)
                
                // set a link for when the user clicks on this word.
                // url scheme syntax "mention://" or "hash://"
                if let matchRange = text.rangeOfString(word, options: .LiteralSearch, range:remainingRange),
                    let escapedString = stringifiedWord.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) {
                    attributedString.addAttribute(NSLinkAttributeName, value: "mention:\(escapedString)", range: text.NSRangeFromRange(matchRange))
                }
            } else if  word.hasPrefix("#") {
                // drop unwanted characters
                stringifiedWord.dropTrailingCharacters(NSCharacterSet.alphanumericCharacterSet().invertedSet)
                
                let remainingRange = Range(bookmark..<text.endIndex)
                
                // set a link for when the user clicks on this word.
                // url scheme syntax "mention://" or "hash://"
                if let matchRange = text.rangeOfString(word, options: .LiteralSearch, range:remainingRange),
                    let escapedString = stringifiedWord.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) {
                    attributedString.addAttribute(NSLinkAttributeName, value: "hash:\(escapedString)", range: text.NSRangeFromRange(matchRange))
                }
            }
            
            bookmark = bookmark.advancedBy(word.characters.count)
        }
        
        self.attributedText = attributedString
    }
}

extension UIViewController {
    func isBeingPresentedInFormSheet() -> Bool {
        if let presentingViewController = presentingViewController {
            return traitCollection.horizontalSizeClass == .Compact && presentingViewController.traitCollection.horizontalSizeClass == .Regular
        }
        return false
    }
    
    func isModal() -> Bool {
        if self.presentingViewController != nil {
            return true
        }
        
        if self.presentingViewController?.presentedViewController == self {
            return true
        }
        
        if self.navigationController?.presentingViewController?.presentedViewController == self.navigationController  {
            return true
        }
        
        if self.tabBarController?.presentingViewController is UITabBarController {
            return true
        }
        
        return false
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

extension UITableView {
    
    func dequeueReusableCell<T: UITableViewCell where T: ReusableView>(forIndexPath indexPath: NSIndexPath) -> T {
        guard let cell = dequeueReusableCellWithIdentifier(T.reuseIdentifier, forIndexPath: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}

extension UITableViewCell: ReusableView { }

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    func performSegueWithIdentifier(segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegueWithIdentifier(segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            segueIdentifier = SegueIdentifier(rawValue: identifier)
            else { fatalError("Invalid segue identifier \(segue.identifier)") }
        
        return segueIdentifier
    }
}

extension ReusableView where Self: UIView {
    
    static var reuseIdentifier: String {
        return String(self)
    }
}

extension Tintable where Self: UIView {
    
    func tint(bool: Bool) {
        if bool {
            self.tintColor = Constants.stockSwipeGreenColor
        } else {
            self.tintColor = UIColor.lightGrayColor()
        }
    }
}

extension CellType where Self: UIViewController, CellIdentifier.RawValue == String {
    
    func reuseIdentifierForCell(tableView: UITableView, indexPath: NSIndexPath) -> CellIdentifier {
        guard let reuseIdentifier = tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier,
            cellIdentifier = CellIdentifier(rawValue: reuseIdentifier)
            else { fatalError("Invalid reuseidentifier for \(tableView.cellForRowAtIndexPath(indexPath)?.reuseIdentifier)") }
        
        return cellIdentifier
    }
    
    //    func dequeueReusableCellWithIdentifier(cellIdentifier: CellIdentifier, forIndexPath: NSIndexPath) {
    //         dequeueReusableCellWithIdentifier(cellIdentifier.rawValue, forIndexPath: forIndexPath)
    //    }
}