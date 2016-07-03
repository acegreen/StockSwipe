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
    
    var ideasCount: Int = 0
    var followingCount: Int = 0
    
    var followersCount: Int = 0
    var likedIdeasCount: Int = 0
    
    mutating func getIdeasCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countTradeIdeasFor("user", object: userObject) { (result) in
            
            do {
                
                let count = try result()
                self.ideasCount = count
                
            } catch {
                self.ideasCount =  0
            }
            
            completionHandler(countString: Double(self.ideasCount).formatPoints())
        }
    }
    
    mutating func getFollowingCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countUserActivityFor(userObject, toUser: nil) { (result) in
            
            do {
                
                let count = try result()
                self.followingCount = count
                
            } catch {
                self.followingCount =  0
            }
            
            completionHandler(countString: Double(self.followingCount).formatPoints())
        }
    }
    
    mutating func getFollowersCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countUserActivityFor(nil, toUser: userObject) { (result) in
            
            do {
                
                let count = try result()
                self.followersCount = count
                
            } catch {
                self.followersCount =  0
            }
            
           completionHandler(countString: Double(self.followersCount).formatPoints())
        }
    }
    
    mutating func getLikedIdeasCount(completionHandler: (countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countTradeIdeasFor("liked_by", object: userObject) { (result) in
            
            do {
                
                let count = try result()
                self.likedIdeasCount = count
                
            } catch {
                self.likedIdeasCount =  0
            }
            
            completionHandler(countString: Double(self.likedIdeasCount).formatPoints())
        }
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
