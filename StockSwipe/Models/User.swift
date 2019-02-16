//
//  User.swift
//  StockSwipe
//
//  Created by Ace Green on 7/2/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public class User: NSObject {
    
    var userObject: PFUser!
    
    var objectId: String!
    var fullname: String! = "John Doe"
    var username: String! = "@JohnDoe"
    var avtar: UIImage! = UIImage(named: "dummy_profile_male")
    var bio: String?
    var location: String?
    var website: String?
    var profile_image_url: String?
    
    var createdAt: Date!
    
    private(set) var ideasCount: Int = 0
    private(set) var followingCount: Int = 0
    private(set) var followersCount: Int = 0
    private(set) var likedIdeasCount: Int = 0
    
    public init(userObject: PFUser) {
        
        super.init()
        
        self.userObject = userObject
    }
    
    func fetchUserInBackground(_ completion: @escaping (User?) -> Void) {
        
        userObject.fetchInBackground { (userObject, error) in
            guard let userObject = userObject as? PFUser else { return completion(nil) }
            self.updateObject(userObject: userObject)
            completion(self)
        }
    }
    
    func fetchIfNeededInBackground(_ completion: @escaping (User?) -> Void) {
        
        userObject.fetchIfNeededInBackground() { (userObject, error) in
            guard let userObject = userObject as? PFUser else { return completion(nil) }
            self.updateObject(userObject: userObject)
            completion(self)
        }
    }
    
    func getAvatar(_ completion: @escaping (UIImage?) -> Void) {
        
        if let profileImage = self.userObject["profile_image"] as? PFFileObject {
            
            profileImage.getDataInBackground { (data, error) in
                if let avatarData = data, let image = UIImage(data: avatarData) {
                    self.avtar = image
                }
                
                completion(self.avtar)
            }
                
        } else if let profileImageURL = self.profile_image_url {
            
            QueryHelper.sharedInstance.queryWith(queryString: profileImageURL, useCacheIfPossible: true, completionHandler: { (result) in
                
                do {
                    
                    let avatarData  = try result()
                    if let image = UIImage(data: avatarData) {
                        self.avtar = image 
                    }
                    completion(self.avtar)
                    
                } catch {
                    completion(self.avtar)
                }
            })
        } else {
            completion(self.avtar)
        }
    }
    
    func getIdeasCount(_ completion: @escaping (_ countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countTradeIdeasFor(key: "user", object: userObject) { (result) in
            
            do {
                
                let count = try result()
                self.ideasCount = count
                
            } catch {
                self.ideasCount =  0
            }
            
            completion(self.ideasCount.suffixNumber())
        }
    }
    
    func getFollowingCount(_ completion: @escaping (_ countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue]) { (result) in
            
            do {
                
                let count = try result()
                self.followingCount = count
                
            } catch {
                self.followingCount =  0
            }
            
            completion(self.followingCount.suffixNumber())
        }
    }
    
    func getFollowersCount(_ completion: @escaping (_ countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: userObject, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue]) { (result) in
            
            do {
                
                let count = try result()
                self.followingCount = count
                
            } catch {
                self.followingCount =  0
            }
            
            completion(self.followingCount.suffixNumber())
        }
    }
    
    func getLikedIdeasCount(_ completion: @escaping (_ countString: String) -> Void) {
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: userObject, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], completion: { (result) in
            
            do {
                
                let count = try result()
                self.likedIdeasCount = count
                
            } catch {
                self.likedIdeasCount =  0
            }
            
            completion(self.likedIdeasCount.suffixNumber())
        })
    }
    
    internal func updateObject(userObject: PFUser) {
        
        self.objectId = userObject.objectId
        self.fullname = userObject.object(forKey: "full_name") as? String ?? "John Doe"
        self.username = "@\(self.userObject.username!)"
        self.profile_image_url = userObject.object(forKey: "profile_image_url") as? String
        
        if let bio = self.userObject.object(forKey: "bio") as? String {
            self.bio = bio
        }
        
        if let location = self.userObject["location"] as? String {
            self.location = location
        }
        
        if let website = self.userObject.object(forKey: "website") as? String {
            self.website = website
        }
        
        self.createdAt = userObject.createdAt
    }
}

extension User {
    
    class func makeUser(from userObjects: [PFUser]) -> [User] {
        return userObjects.map { User(userObject: $0) }
    }
}

//extension User: Equatable {}
//
//public func ==(lhs: User, rhs: User) -> Bool {
//    let areEqual = lhs.userObject == rhs.userObject
//    
//    return areEqual
//}
