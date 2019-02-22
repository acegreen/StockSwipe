//
//  News.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-15.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Parse

public class TradeIdea: PFObject, PFSubclassing {
    
    @NSManaged var user: User!
    @NSManaged var ideaDescription: String!
    @NSManaged var liked_by: [User]?
    @NSManaged var reshared_by: [TradeIdea]?
    @NSManaged var reshare_of: TradeIdea?
    @NSManaged var reply_to: TradeIdea?
    @NSManaged var hashtags: [String]?
    @NSManaged var stocks: [Stock]?
    @NSManaged var users: [User]?
    
    var likeCount: Int = 0
    var reshareCount: Int = 0
    var isLikedByCurrentUser = false
    var isResharedByCurrentUser = false
    
    public static func parseClassName() -> String {
        return String(describing: TradeIdea.self)
    }
    
    func checkNumberOfLikes(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdeas: nil, tradeIdeas: [self], stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], skip: nil, limit: nil, includeKeys: nil, selectKeys: nil, completion: { (result) in
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }
                self.likeCount = activityObjects.count
                
                if let currentUser = User.current() {
                    self.isLikedByCurrentUser = activityObjects.contains { $0.fromUser.objectId == currentUser.objectId }
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
        
        QueryHelper.sharedInstance.queryActivityFor(fromUser: nil, toUser: nil, originalTradeIdeas: [self], tradeIdeas: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], skip: nil, limit: nil, includeKeys: nil, completion: { (result) in
            
            do {
                
                guard let activityObjects = try result() as? [Activity] else { return }
                self.reshareCount = activityObjects.count
                
                if let currentUser = PFUser.current() {
                    self.isResharedByCurrentUser = activityObjects.contains { $0.fromUser.objectId == currentUser.objectId }
                }
                
            } catch {
                //TODO: handle error
                print(error.localizedDescription)
            }
            
            if let completion = completion {
                completion(self.reshareCount)
            }
        })
    }
}
