//
//  User.swift
//  StockSwipe
//
//  Created by Ace Green on 7/2/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public class User: PFUser {

    @NSManaged var username_lowercase: String?
    @NSManaged var full_name: String?
    @NSManaged var fullname_lowercase: String?
    @NSManaged var bio: String?
    @NSManaged var website: String?
    @NSManaged var recentSearches: [PFObject]?
    @NSManaged var profile_image: PFFileObject?
    @NSManaged var profile_image_url: String?
    @NSManaged var blocked_users: [PFUser]?
    @NSManaged var location: String?
    
    @NSManaged var socialmedia_verified: Bool
    @NSManaged var emailVerified: Bool
    
    @NSManaged var likedTradeIdea_notification: Bool
    @NSManaged var newTradeIdea_notification: Bool
    @NSManaged var replyTradeIdea_notification: Bool
    @NSManaged var reshareTradeIdea_notification: Bool
    @NSManaged var follower_notification: Bool
    @NSManaged var mention_notification: Bool
    @NSManaged var swipe_addToWatchlist: Bool
    
    private(set) var avtar = UIImage(named: "dummy_profile_male")!
    private(set) var ideasCount: Int = 0
    private(set) var followingCount: Int = 0
    private(set) var followersCount: Int = 0
    private(set) var likedIdeasCount: Int = 0
    
    var usertag: String {
        return (self.username != nil) ? "@" + self.username! : ""
    }
    
    func getAvatar(_ completion: @escaping (UIImage) -> Void) {
        guard self.profile_image?.url != nil || profile_image_url != nil else {
            completion(self.avtar)
            return
        }
        QueryHelper.sharedInstance.queryWith(queryString: self.profile_image?.url ?? profile_image_url ?? "", useCacheIfPossible: true, completionHandler: { (result) in
            do {
                
                let avatarData  = try result()
                if let image = UIImage(data: avatarData) {
                    self.avtar = image
                    completion(self.avtar)
                } else {
                    completion(self.avtar)
                }
            } catch {
                completion(self.avtar)
            }
        })
    }

    func getIdeasCount(_ completion: @escaping (_ countString: String) -> Void) {
        
        let activityTypes = [Constants.ActivityType.TradeIdeaNew.rawValue, Constants.ActivityType.TradeIdeaReshare.rawValue, Constants.ActivityType.TradeIdeaReply.rawValue]
        QueryHelper.sharedInstance.countActivityFor(fromUser: self, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: activityTypes) { (result) in
            
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
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: self, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue]) { (result) in
            
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
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: self, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.Follow.rawValue]) { (result) in
            
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
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: self, toUser: nil, originalTradeIdea: nil, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], completion: { (result) in
            
            do {
                
                let count = try result()
                self.likedIdeasCount = count
                
            } catch {
                self.likedIdeasCount =  0
            }
            
            completion(self.likedIdeasCount.suffixNumber())
        })
    }
}

//extension User: Equatable {}
//
//public func ==(lhs: User, rhs: User) -> Bool {
//    let areEqual = lhs == rhs
//    
//    return areEqual
//}
