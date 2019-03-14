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
    @NSManaged var ideaDescription: String?
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
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: nil, tradeIdea: self, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], completion: { (result) in
            
            do {
                let count = try result()
                self.likeCount = count
                
                
                if let currentUser = User.current() {
                    QueryHelper.sharedInstance.countActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: nil, tradeIdea: self, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaLike.rawValue], limit: 1, completion: { (result) in
                        
                        do {
                            let count = try result()
                            self.isLikedByCurrentUser = count > 0
                            
                            if let completion = completion {
                                completion(self.likeCount)
                            }
                            
                        } catch {
                            //TODO: handle error
                            if let completion = completion {
                                completion(self.likeCount)
                            }
                        }
                    })
                } else {
                    if let completion = completion {
                        completion(self.likeCount)
                    }
                }
                
            } catch {
                //TODO: handle error
                if let completion = completion {
                    completion(self.likeCount)
                }
            }
        })
    }
    
    func checkNumberOfReshares(completion: ((Int) -> Void)?) {
        
        QueryHelper.sharedInstance.countActivityFor(fromUser: nil, toUser: nil, originalTradeIdea: self, tradeIdea: nil, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], limit: nil, completion: { (result) in
            
            do {
                let count = try result()
                self.reshareCount = count
                
                if let currentUser = User.current() {
                    QueryHelper.sharedInstance.countActivityFor(fromUser: currentUser, toUser: nil, originalTradeIdea: self, tradeIdea: self, stocks: nil, activityType: [Constants.ActivityType.TradeIdeaReshare.rawValue], limit: 1, completion: { (result) in
                        
                        do {
                            let count = try result()
                            self.isResharedByCurrentUser = count > 0
                            
                            if let completion = completion {
                                completion(self.reshareCount)
                            }
                        } catch {
                            //TODO: handle error
                            if let completion = completion {
                                completion(self.reshareCount)
                            }
                        }
                    })
                } else {
                    if let completion = completion {
                        completion(self.reshareCount)
                    }
                }
                
            } catch {
                //TODO: handle error
                if let completion = completion {
                    completion(self.reshareCount)
                }
            }
        })
    }
}
