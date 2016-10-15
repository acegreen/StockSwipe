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
    
    var likeCount: Int = 0 {
        willSet {
            if newValue > likeCount {
                self.parseObject.incrementKey("likeCount")
            } else if likeCount > 0 {
                self.parseObject.incrementKey("likeCount", byAmount: -1)
            }
            self.parseObject.saveEventually()
        }
    }
    
    var reshareCount: Int = 0 {
        willSet {
            if newValue > reshareCount {
                self.parseObject.incrementKey("reshareCount")
            } else if reshareCount > 0 {
                self.parseObject.incrementKey("reshareCount", byAmount: -1)
            }
            self.parseObject.saveEventually()
        }
    }
    
    var isLikedByCurrentUser: Bool! = false
    var isResharedByCurrentUser: Bool! = false
    
    var nestedTradeIdea: TradeIdea?
    
    var createdAt: Date!

    var parseObject: PFObject!
    var nestedParseObject: PFObject?
    
    init(parseObject: PFObject, completion: ((TradeIdea?) -> Void)? = nil) {
        
        super.init()
        
        parseObject.fetchIfNeededInBackground { (parseObject, error) in
            
            guard let parseObject = parseObject else  {
                if let completion = completion {
                    completion(self)
                }
                return
            }
            
            self.parseObject = parseObject
            
            self.ideaDescription = parseObject.object(forKey: "description") as? String ?? ""
            
            self.likeCount = parseObject.object(forKey: "likeCount") as? Int ?? 0
            self.reshareCount = parseObject.object(forKey: "reshareCount") as? Int ?? 0
            
            self.createdAt = parseObject.createdAt
            
            self.checkNumberOfLikes(completion: { (likeCount) in
                
                self.checkNumberOfReshares(completion: { (reshareCount) in
                    
                    if let userObject = parseObject.object(forKey: "user") as? PFObject {
                        
                        User(userObject: userObject, completion: { (user) in
                            
                            self.user = user
                            
                            if let nestedTradeIdeaObject = parseObject.object(forKey: "reshare_of") as? PFObject {
                                
                                self.nestedParseObject = nestedTradeIdeaObject
                                
                                TradeIdea(parseObject: nestedTradeIdeaObject, completion: { (tradeIdea) in
                                    
                                    self.nestedTradeIdea = tradeIdea
                                    
                                    if let completion = completion {
                                        completion(self)
                                    }
                                })
                            } else {
                                
                                if let completion = completion {
                                    completion(self)
                                }
                            }
                        })
                    }
                })
            })
        }
    }
    
    func checkNumberOfLikes(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self.parseObject, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
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
            }
            
            if let completion = completion {
                completion(self.likeCount)
            }
        })
    }
    
    func checkNumberOfReshares(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: self.parseObject, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
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
            }
            
            if let completion = completion {
                completion(self.reshareCount)
            }
        })
    }
}

//extension TradeIdea: Equatable {}
//
//public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
//    let areEqual = lhs.parseObject == rhs.parseObject
//    
//    return areEqual
//}
