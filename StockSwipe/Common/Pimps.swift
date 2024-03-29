//
//  Extensions.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-21.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import Foundation
import NVActivityIndicatorView

extension Collection {
    func find(_ predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Iterator.Element? {
        return try firstIndex(where: predicate).map({self[$0]})
    }
}

extension Array {
    
    // Safely lookup an index that might be out of bounds,
    // returning nil if it does not exist
    func get(_ index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
    
    mutating func moveItem(fromIndex oldIndex: Index, toIndex newIndex: Index) {
        insert(remove(at: oldIndex), at: newIndex)
    }
    
    func reduceWithIndex<T>(_ initial: T, combine: (T, Int, Array.Iterator.Element) throws -> T) rethrows -> T {
        var result = initial
        for (index, element) in self.enumerated() {
            result = try combine(result, index, element)
        }
        return result
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(_ object: Element) {
        if let index = self.firstIndex(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
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
        
        let units:[String] = ["K","M","B","T","P","E"]
        
        let roundedNum:Int = Int(round(10 * num / pow(1000.0,Double(exp))) / 10)
        
        return "\(sign)\(roundedNum)\(units[exp-1])"
    }
}

extension Double {
    
    /// Rounds the double to decimal places value
    func roundTo(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    
    func toRadians() -> CGFloat {
        return CGFloat(self * (M_PI/180.0))
    }
}

extension String {
    
    func NSRangeFromRange(from range: Range<String.Index>) -> NSRange? {
        let utf16view = self.utf16
        if let from = range.lowerBound.samePosition(in: utf16view), let to = range.upperBound.samePosition(in: utf16view) {
            return NSMakeRange(utf16view.distance(from: utf16view.startIndex, to: from), utf16view.distance(from: from, to: to))
        }
        return nil
    }
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        guard nsRange.location != NSNotFound else { return nil }
        let start = self.index(self.startIndex, offsetBy: nsRange.location)
        let end = self.index(start, offsetBy: nsRange.length)
        return start..<end
    }
    
    mutating func dropTrailingCharacters(_ dropCharacterSet: CharacterSet) {
        let nonCharacters = dropCharacterSet
        let characterArray = components(separatedBy: nonCharacters)
        if let first = characterArray.first {
            self = first
        }
    }
    
    func URLEncodedString() -> String? {
        let escapedString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return escapedString
    }
    
    func decodeEncodedString() -> String? {
        
        guard let encodedData = self.data(using: String.Encoding.utf8) else { return self }
        
        do {
            
            let attributedString = try NSAttributedString(data: encodedData, options: [.documentType: NSAttributedString.DocumentType.html,
                                                                                       .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            
            return attributedString.string
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
            
            return self
            
        }
    }
    
    func replace(_ target: String, withString: String) -> String {
        
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
    
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension Date {
    func dateFormattedString() -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    static func dateBySubtractingDays(_ currentDate: Date, numberOfDays: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.day = numberOfDays
        return (Calendar.current as NSCalendar).date(byAdding: .day, value: numberOfDays, to: currentDate, options: NSCalendar.Options(rawValue: 0))!
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
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func imageFromLayer() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func edges(to view: UIView, top: CGFloat=0, left: CGFloat=0, bottom: CGFloat=0, right: CGFloat=0) {
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: left),
            self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: right),
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: top),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottom)
            ])
    }
}

extension UISegmentedControl {
    
    func insertSegmentWithMultilineTitle(_ title: String, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.text = title
        label.textColor = self.tintColor
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        self.insertSegment(with: label.imageFromLayer(), at: segment, animated: animated)
    }
    
    func insertSegmentWithMultilineAttributedTitle(_ attributedTitle: NSAttributedString, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.attributedText = attributedTitle
        label.numberOfLines = 0
        label.sizeToFit()
        self.insertSegment(with: label.imageFromLayer(), at: segment, animated: animated)
    }
    
    func segmentWithMultilineAttributedTitle(_ attributedTitle: NSAttributedString, atIndex segment: Int, animated: Bool) {
        let label: UILabel = UILabel()
        label.attributedText = attributedTitle
        label.numberOfLines = 0
        label.sizeToFit()
        
        self.setImage(label.imageFromLayer(), forSegmentAt: segment)
    }
}

extension UIButton {
    
    open override var intrinsicContentSize : CGSize {
        
        let intrinsicContentSize = super.intrinsicContentSize
        
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
    
    convenience init( rgbValue: UInt) {
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension URL {
    var fragments: [String: String] {
        var results = [String: String]()
        if let pairs = self.fragment?.components(separatedBy: "&") , pairs.count > 0 {
            for pair: String in pairs {
                if let keyValue = pair.components(separatedBy: "=") as [String]? {
                    results.updateValue(keyValue[1], forKey: keyValue[0])
                }
            }
        }
        return results
    }
    
    func parseQueryString (_ urlQuery: String, firstSeperator: String, secondSeperator: String) -> NSDictionary? {
        
        let dict: NSMutableDictionary = NSMutableDictionary()
        
        let pairs = urlQuery.components(separatedBy: firstSeperator)
        
        for pair in pairs {
            
            let elements = pair.components(separatedBy: secondSeperator)
            
            guard let key = (elements[0] as AnyObject).removingPercentEncoding,
                  let value = (elements[1] as AnyObject).removingPercentEncoding
            else { return dict }
            
            dict.setObject(value!, forKey: key! as NSCopying)
        }
        
        return dict
    }
}

extension UIImage {
    
    enum AssetIdentifier: String  {
        case noIdeaBulbImage = "no_idea"
        case xButton = "x"
        case UserDummyImage = "dummy_profile_male"
    }
    
    convenience init!(assetIdentifier: AssetIdentifier) {
        self.init(named: assetIdentifier.rawValue)
    }
    
    convenience init(view: UIView) {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        self.init(cgImage: (image.cgImage)!)
    }
    
    var rounded: UIImage {
        let imageView = UIImageView(image: self)
        imageView.layer.cornerRadius = size.height < size.width ? size.height/2 : size.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    var circle: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

extension DetectTags where Self: UITextView {
    
    func detectTags() -> (cashtags: [String], mentions: [String], hashtags: [String]) {
        
        var cashtags = [String]()
        var mentions = [String]()
        var hashtags = [String]()
        
        // turn string in to NSString
        let currentText = self.text as NSString
        
        let words:[String] = currentText.components(separatedBy: .whitespacesAndNewlines)
        
        for word in words {
            
            var wordWithTagRemoved = String(word.dropFirst())
            
            if word.hasPrefix("$") {
                
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.letters.inverted)
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = CharacterSet.decimalDigits
                if wordWithTagRemoved.rangeOfCharacter(from: digits) == nil {
                    cashtags.append(wordWithTagRemoved)
                }
                
            } else if word.hasPrefix("@") {
                
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.alphanumerics.inverted)
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                mentions.append(wordWithTagRemoved)
            } else if word.hasPrefix("#") {
                
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.alphanumerics.inverted)
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = CharacterSet.decimalDigits
                if wordWithTagRemoved.rangeOfCharacter(from: digits) == nil {
                    hashtags.append(wordWithTagRemoved)
                }
                
            }
        }
        
        return (cashtags, mentions, hashtags)
    }
    
    func resolveTags() {
        
        // this needs to be an array of NSString.  String does not work.
        let words = self.text.components(separatedBy: .whitespacesAndNewlines)
        
        // use storyboard attributes
        var attributes: [NSAttributedString.Key: Any]!
        if let name = self.font?.familyName, let size = self.font?.pointSize {
            attributes = [
                NSAttributedString.Key.font : UIFont(name: name, size: size)!,
                NSAttributedString.Key.foregroundColor : (self.textColor ?? UIColor.black)
            ]
        }
        
        // you can staple URLs onto attributed strings
        let attributedString = NSMutableAttributedString(string: self.text)
        attributedString.addAttributes(attributes, range: (self.text as NSString).range(of: self.text))
        
        // keep track of where we are as we interate through the string.
        // otherwise, a string like "#test #test" will only highlight the first one.
        var bookmark = text.startIndex
        
        // tag each word if it has a hashtag
        for word in words {
            
            // convert the word from NSString to String
            // this allows us to call "dropFirst" to remove the hashtagattributedString
            var wordWithTagRemoved = word as String
            
            // drop the hashtag
            wordWithTagRemoved = String(wordWithTagRemoved.dropFirst())
            
            // found a word that is prepended by a hashtag!
            // homework for you: implement @mentions here too.
            if word.hasPrefix("$") {
                
                // drop unwanted characters
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.letters.inverted)
                
                let remainingRange = bookmark..<text.endIndex
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                if let matchRange = text.range(of: word as String, options: .literal, range:remainingRange),
                    let escapedString = wordWithTagRemoved.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                    attributedString.addAttribute(.link, value: "cash:\(escapedString)", range: text.NSRangeFromRange(from: matchRange)!)
                }
                
            } else if word.hasPrefix("@") {
                // drop unwanted characters
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.alphanumerics.inverted)
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                let remainingRange = bookmark..<text.endIndex
                
                // set a link for when the user clicks on this word.
                // url scheme syntax "mention://" or "hash://"
                if let matchRange = text.range(of: word, options: .literal, range:remainingRange),
                    let escapedString = wordWithTagRemoved.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                    attributedString.addAttribute(.link, value: "mention:\(escapedString)", range: text.NSRangeFromRange(from: matchRange)!)
                }
            } else if  word.hasPrefix("#") {
                // drop unwanted characters
                wordWithTagRemoved.dropTrailingCharacters(CharacterSet.alphanumerics.inverted)
                
                guard Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty
                    else { continue }
                
                let remainingRange = bookmark..<text.endIndex
                
                // set a link for when the user clicks on this word.
                // url scheme syntax "mention://" or "hash://"
                if let matchRange = text.range(of: word, options: .literal, range:remainingRange),
                    let escapedString = wordWithTagRemoved.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                    attributedString.addAttribute(.link, value: "hash:\(escapedString)", range: text.NSRangeFromRange(from: matchRange)!)
                }
            }
            
            bookmark = text.index(bookmark, offsetBy: word.count)
        }
        
        self.attributedText = attributedString
    }
}

extension UIViewController {
    func isBeingPresentedInFormSheet() -> Bool {
        if let presentingViewController = presentingViewController {
            return traitCollection.horizontalSizeClass == .compact && presentingViewController.traitCollection.horizontalSizeClass == .regular
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
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
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
    
    func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T where T: ReusableView {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
}

extension UITableViewCell: ReusableView { }

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    func performSegueWithIdentifier(_ segueIdentifier: SegueIdentifier, sender: Any?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier)
            else { fatalError("Invalid segue identifier \(segue.identifier)") }
        
        return segueIdentifier
    }
}

extension ReusableView where Self: UIView {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension Tintable where Self: UIView {
    
    func tint(_ bool: Bool) {
        if bool {
            self.tintColor = Constants.SSColors.greenDark
        } else {
            self.tintColor = UIColor.lightGray
        }
    }
}

extension CellType where Self: UIViewController, CellIdentifier.RawValue == String {
    
    func reuseIdentifierForCell(_ tableView: UITableView, indexPath: IndexPath) -> CellIdentifier {
        guard let reuseIdentifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier,
            let cellIdentifier = CellIdentifier(rawValue: reuseIdentifier)
            else { fatalError("Invalid reuseidentifier for \(tableView.cellForRow(at: indexPath)?.reuseIdentifier)") }
        
        return cellIdentifier
    }
    
    //    func dequeueReusableCellWithIdentifier(cellIdentifier: CellIdentifier, forIndexPath: NSIndexPath) {
    //         dequeueReusableCellWithIdentifier(cellIdentifier.rawValue, forIndexPath: forIndexPath)
    //    }
}

extension NibLoadable {
    @discardableResult
    func fromNib() -> UIView? {
        let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as! UIView
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.edges(to: self)
        return contentView
    }
}

extension NSLayoutConstraint {
    
    func setMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant
        )
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        newConstraint.isActive = true
        
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}
