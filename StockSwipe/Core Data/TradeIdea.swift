//
//  News.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public struct TradeIdea {
    
    var user: User!
    var description: String!
    
    var likeCount: Int = 0 {
        didSet {
            self.parseObject.setObject(self.likeCount, forKey: "likeCount")
            self.parseObject.saveEventually()
        }
    }
    var reshareCount: Int = 0 {
        didSet {
            self.parseObject.setObject(self.reshareCount, forKey: "reshareCount")
            self.parseObject.saveEventually()
        }
    }
    
    var isLikedByCurrentUser: Bool! = false
    var isResharedByCurrentUser: Bool! = false
    
    var nestedTradeIdeaObject: PFObject?
    
    var publishedDate: Date!
    var parseObject: PFObject!
    
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
            self.nestedTradeIdeaObject = parseObject.object(forKey: "reshare_of") as? PFObject
            self.publishedDate = parseObject.createdAt
            
            self.checkIfLikedByCurrentUser(completion: { (isLikedByCurrentUser) in
                self.isLikedByCurrentUser = isLikedByCurrentUser
                
                self.checkIfResharedByCurrentUser(completion: { (isResharedByCurrentUser) in
                    self.isResharedByCurrentUser = isResharedByCurrentUser
                    
                    User(userObject: parseObject.object(forKey: "user") as! PFUser, completion: { (user) in
                        self.user = user
                        if let completion = completion {
                            completion(self)
                        }
                    })
                })
            })
        }
    }
    
   mutating func checkIfLikedByCurrentUser(completion: ((Bool) -> Void)?) {
        
        guard let currentUser = PFUser.current() else { return }
        
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: self.parseObject, stock: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result().first
                
                if activityObject != nil {
                    self.isLikedByCurrentUser = true
                } else {
                    self.isLikedByCurrentUser = false
                }
                
                if let completion = completion {
                    completion(self.isLikedByCurrentUser)
                }
                
            } catch {
            }
        })
    }
    
    mutating func checkIfResharedByCurrentUser(completion: ((Bool) -> Void)?) {
        
        guard let currentUser = PFUser.current() else { return }
    
        QueryHelper.sharedInstance.queryActivityFor(currentUser, toUser: nil, originalTradeIdea: self.parseObject, tradeIdea: nil, stock: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: 1, includeKeys: nil, completion: { (result) in
            
            do {
                
                let activityObject = try result().first
                
                if activityObject != nil {
                    self.isResharedByCurrentUser = true
                } else {
                    self.isResharedByCurrentUser = false
                }
                
                if let completion = completion {
                    completion(self.isResharedByCurrentUser)
                }
    
            } catch {
                
            }
        })
    }
}

extension TradeIdea: Equatable {}

public func ==(lhs: TradeIdea, rhs: TradeIdea) -> Bool {
    let areEqual = lhs.parseObject == rhs.parseObject
    
    return areEqual
}
