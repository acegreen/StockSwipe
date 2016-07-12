//
//  User.swift
//  StockSwipe
//
//  Created by Ace Green on 7/2/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public struct User {
    
    let userObject: PFUser!
    
    private var ideasCount: Int = 0
    private var followingCount: Int = 0
    private var followersCount: Int = 0
    private var likedIdeasCount: Int = 0
    
    mutating func getIdeasCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countTradeIdeasFor("user", object: userObject) { (result) in
            
            do {
                
                let count = try result()
                self.ideasCount = count
                
            } catch {
                self.ideasCount =  0
            }
            
            completionHandler(countString: self.ideasCount.suffixNumber())
        }
    }
    
    mutating func getFollowingCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(userObject, toUser: nil, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.Follow.rawValue) { (result) in
            
            do {
                
                let count = try result()
                self.followingCount = count
                
            } catch {
                self.followingCount =  0
            }
            
            completionHandler(countString: self.followingCount.suffixNumber())
        }
    }
    
    mutating func getFollowersCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(nil, toUser: userObject, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.Follow.rawValue) { (result) in
            
            do {
                
                let count = try result()
                self.followingCount = count
                
            } catch {
                self.followingCount =  0
            }
            
            completionHandler(countString: self.followingCount.suffixNumber())
        }
    }
    
    mutating func getLikedIdeasCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(userObject, toUser: nil, tradeIdea: nil, stock: nil, activityType: Constants.ActivityType.TradeIdeaLike.rawValue, completion: { (result) in
            
            do {
                
                let count = try result()
                self.likedIdeasCount = count
                
            } catch {
                self.likedIdeasCount =  0
            }
            
            completionHandler(countString: self.likedIdeasCount.suffixNumber())
        })
    }
    
    init(userObject: PFUser!) {
        self.userObject = userObject
    }
}

extension User: Equatable {}

public func ==(lhs: User, rhs: User) -> Bool {
    let areEqual = lhs.userObject == rhs.userObject
    
    return areEqual
}
