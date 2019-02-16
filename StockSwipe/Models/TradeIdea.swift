//
//  News.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public class TradeIdea: NSObject {
    
    var user: User!
    var ideaDescription: String!
    
    var likeCount: Int = 0
    var reshareCount: Int = 0
    
    var isLikedByCurrentUser: Bool! = false
    var isResharedByCurrentUser: Bool! = false
    
    var nestedTradeIdea: TradeIdea?
    
    var createdAt: Date!

    var parseObject: PFObject!
    var nestedParseObject: PFObject?
    
    public init(parseObject: PFObject) {
        
        super.init()
        
        self.parseObject = parseObject
        
        self.fetchTradeIdeaIfNeeded { _ in }
    }
    
    func fetchTradeIdeaIfNeeded(_ completion: @escaping (TradeIdea?) -> Void) {
        
        parseObject.fetchIfNeededInBackground { (parseObject, error) in
            
            guard let parseObject = parseObject else { return completion(nil) }
            
            self.updateObject(parseObject: parseObject)
            
            completion(self)
        }
    }
    
    func checkNumberOfLikes(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self.parseObject, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.likeCount = activityObjects.count
                
                if let currentUser = PFUser.current() {
                    
                    var userObjects = [PFUser]()
                    for activityObject in activityObjects {
                        if let userObject = activityObject["fromUser"] as? PFUser {
                            userObjects.append(userObject)
                        }
                    }
                    
                    self.isLikedByCurrentUser = userObjects.contains { $0.objectId == currentUser.objectId }
                }
                
            } catch {
                //TODO: handle error
            }
            
            if let completion = completion {
                completion(self.likeCount)
            }
        })
    }
    
    func checkNumberOfReshares(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: self.parseObject, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.reshareCount = activityObjects.count
                
                if let currentUser = PFUser.current() {
                    
                    var userObjects = [PFUser]()
                    for activityObject in activityObjects {
                        if let userObject = activityObject["fromUser"] as? PFUser {
                            userObjects.append(userObject)
                        }
                    }
                    
                    self.isResharedByCurrentUser = userObjects.contains { $0.objectId == currentUser.objectId }
                }
                
            } catch {
                //TODO: handle error
            }
            
            if let completion = completion {
                completion(self.reshareCount)
            }
        })
    }
    
    internal func updateObject(parseObject: PFObject) {
        
        self.ideaDescription = parseObject.object(forKey: "description") as? String ?? ""
        
        self.createdAt = parseObject.createdAt
        
        if let userObject = parseObject.object(forKey: "user") as? PFUser {
            self.user = User(userObject: userObject)
        }
        
        if let nestedTradeIdeaObject = parseObject.object(forKey: "reshare_of") as? PFObject {
            self.nestedParseObject = nestedTradeIdeaObject
            self.nestedTradeIdea = TradeIdea(parseObject: nestedTradeIdeaObject)
        }
    }
}

extension TradeIdea {
    
    class func makeTradeIdeas(from tradeIdeaObjects: [PFObject]) -> [TradeIdea] {
        return tradeIdeaObjects.map { TradeIdea(parseObject: $0) }
    }
}

//extension TradeIdea: Equatable {}
//
//public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
//    let areEqual = lhs.parseObject == rhs.parseObject
//    
//    return areEqual
//}
