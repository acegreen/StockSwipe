//
//  News.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public class TradeIdea {
    
    var user: User!
    var description: String!
    
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
    
    var publishedDate: Date!

    var parseObject: PFObject!
    var nestedParseObject: PFObject?
    
    init(parseObject: PFObject, completion: ((TradeIdea?) -> Void)? = nil) {
        
        parseObject.fetchIfNeededInBackground { (parseObject, error) in
            
            guard let parseObject = parseObject else  {
                if let completion = completion {
                    completion(nil)
                }
                return
            }
            
            self.parseObject = parseObject
            
            self.description = parseObject.object(forKey: "description") as? String ?? ""
            
            self.likeCount = parseObject.object(forKey: "likeCount") as? Int ?? 0
            self.reshareCount = parseObject.object(forKey: "reshareCount") as? Int ?? 0
            
            self.publishedDate = parseObject.createdAt
            
            self.checkNumberOfLikes(completion: { (isLikedByCurrentUser) in
                
                self.checkNumberOfReshares(completion: { (isResharedByCurrentUser) in
                    
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
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self.parseObject, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.likeCount = activityObjects.count
                
                if let currentUser = PFUser.current() {
                    self.isLikedByCurrentUser = activityObjects.map { $0.object(forKey: "fromUser") as? PFUser }.contains { $0?.objectId == currentUser.objectId }
                }
                
            } catch {
            }
            
            if let completion = completion {
                completion(self.likeCount)
            }
        })
    }
    
    func checkNumberOfReshares(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: self.parseObject, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObjects = try result()
                self.reshareCount = activityObjects.count
                
                if let currentUser = PFUser.current() {
                    self.isResharedByCurrentUser = activityObjects.map { $0.object(forKey: "fromUser") as? PFUser }.contains { $0?.objectId == currentUser.objectId }
                }
                
            } catch {
            }
            
            if let completion = completion {
                completion(self.reshareCount)
            }
        })
    }
    
//    func checkIfLikedByCurrentUser(completion: ((Bool) -> Void)?) {
//        
//        guard let currentUser = PFUser.current() else { return }
//        
//        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: self.parseObject, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
//            
//            do {
//                
//                let activityObject = try result().first
//                
//                if activityObject != nil {
//                    self.isLikedByCurrentUser = true
//                }
//                
//            } catch {
//            }
//            
//            if let completion = completion {
//                completion(self.isLikedByCurrentUser)
//            }
//        })
//    }
//    
//    func checkIfResharedByCurrentUser(completion: ((Bool) -> Void)?) {
//        
//        guard let currentUser = PFUser.current() else { return }
//    
//        QueryHelper.sharedInstance.queryActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: self.parseObject, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
//            
//            do {
//                
//                let activityObject = try result().first
//                
//                if activityObject != nil {
//                    self.isResharedByCurrentUser = true
//                }
//    
//            } catch {
//            }
//            
//            if let completion = completion {
//                completion(self.isResharedByCurrentUser)
//            }
//        })
//    }
}

extension TradeIdea: Equatable {}

public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
    let areEqual = lhs.parseObject == rhs.parseObject
    
    return areEqual
}
