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
    
    var userObject: PFUser!
    
    var objectId: String!
    var fullname: String! = "John Doe"
    var username: String! = "@JohnDoe"
    var avtar: UIImage!
    
    var profile_image_url: String?
    
    private var ideasCount: Int = 0
    private var followingCount: Int = 0
    private var followersCount: Int = 0
    private var likedIdeasCount: Int = 0
    
    init(userObject: PFUser, completion: ((User?) -> Void)? = nil) {
        
        userObject.fetchIfNeededInBackgroundWithBlock { (userObject, error) in
            
            guard let userObject = userObject else {
                if let completion = completion {
                    completion(nil)
                }
                return
            }
            
            self.userObject = userObject as! PFUser
            self.objectId = userObject.objectId
            self.fullname = userObject.objectForKey("full_name") as? String
            self.username = "@\(self.userObject.username!)"
            self.profile_image_url = userObject.objectForKey("profile_image_url") as? String
            
            self.getAvatar({ (UIImage) in
                if let completion = completion {
                    completion(self)
                }
            })
        }
    }
    
    mutating func getAvatar(completionHandler: (UIImage) -> Void) {
        
        if let profileImageURL = self.profile_image_url {
            QueryHelper.sharedInstance.queryWith(profileImageURL, completionHandler: { (result) in
                
                do {
                    
                    let avatarData  = try result()
                    self.avtar = UIImage(data: avatarData)
                    
                    completionHandler(self.avtar)
                    
                } catch {
                    completionHandler(UIImage(named: "dummy_profile_male_big")!)
                }
            })
        } else {
            completionHandler(UIImage(named: "dummy_profile_male_big")!)
        }
    }
    
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
}

extension User: Equatable {}

public func ==(lhs: User, rhs: User) -> Bool {
    let areEqual = lhs.userObject == rhs.userObject
    
    return areEqual
}
