# CHANGE LOG

## Version 1.0 
- [x] Loading animation before charts appear
- [x] Long/Short/Skip swipe gestures 
- [x] Query 10 random symbols each time. Symbols can’t repeat themselves until a certain point
- [x] New cards need to load when the stack of cards is empty (as long as the query has items left) 
- [x] Watchlist collectionview page 
- [x] Only top most card can accept gesture
- [x] Add settings page

## Version 2.0:
- [x] Integration with a professional charting API (TradingView)
- [x] Fix collection view UIView issue
- [x] Fix core data saving issue
- [x] Card animation into view (when the first 3 cards come on)
- [x] Share feature for charts
- [x] Allow Facebook login 
- [x] Update review second alert message 

## Version 2.1:
- [x] Add trending cloud 
- [x] Fix crash caused by adding existing chart to watchlist 

## Version 2.2:
- [x] Add iPhone support
- [x] Fix deselect button issue
- [x] Add no internet alert when reloading views with no internet

## Version 2.2.1:
- [x] Add tutorial
- [x] Move login view outside of main UINavigationController and fix segue glitch
- [x] Fix crashes due to popover controller 

## Version 2.2.3:
- [x] Add push notification 
- [x] Remove AppURL from share & fix optional issue

## Version 2.2.4:
- [x] No internet connect alert for “write a review” cell
- [x] Add no internet connect for cloud view controller
- [x] Fix crash in cards view caused by less than 3 cards
- [x] Fix Parse push badge issue

## Version 2.2.5:
- [x] Integrate with spotlight search API for searchable item
- [x] Add LaunchKit SDK + What’s New Popup
- [x] Add new button with animation for feedback
- [x] Add PopTips to certain views
- [x] Bring back appURL for share feature
- [x] Fix crash due to parseQueryString()
- [x] Fix crash with stockswipe:// url scheme

## Version 2.2.6:
- [x] Fix card images bug
- [x] Fix fourth card appearing incorrectly
- [x] Add usersChoice from cloud to Parse
- [x] Switch long/short indicators on card
- [x] Improve user experience (popTips, empty views, etc.)
- [x] Add exchange & sector Filters
- [x] Set stock defaults based on country 
- [x] Add TSX

## Version 2.3:
- [x] Overview page with horizontally scrolling index prices
- [x] Replace screenshots with chart image for share card feature
- [x] Fix Twitter table issue (sort of fixed)
- [x] Add user to mail chimp on signup. 
- [x] Switch from UIWebView to WKWebView

## Version 2.3.1:
- [x] Fix Facebook login mail chimp registration not executed
- [x] Fix SwiftyJSON crash caused by error handling during init
- [x] Improve Parse login error handling 
- [x] Have top stories link open in app

## Version 2.3.2:
- [x] Improve WebViewController (progress bar, share button, etc)
- [x] Define WkWebView properly 

## Version 2.4:
- [x] Fix crash caused by TwitterKit when sharing images from timeline
- [x] Fix various crashes see (Crashalytics)
- [x] Add spinner to overview page
- [x] Add FAQ page
- [x] Fix tradingView pop ups on iPhone (portrait) + top right warning indicator
- [x] Open URLs in SFSafariViewController for Tweets and Top Stories news

## Version 2.5:
- [x] Add “Trade Ideas” tab within chart details
- [x] Add Profile view
- [x] Make cloud & new table show no internet connection (cosmetic improvement)
- [x] Replace filter icon with 3 row icon
- [x] Fix share card vote count issue
- [x] Migrate Parse Database to server

## Version 2.5.1:
- [x] Fix crash caused when no stock symbol was found
- [x] Send chart object to ChartDetailTabBarController directly
- [x] Reduce queryStockObjects requests
- [x] Attempt to fix crash caused by grabTopStories()
- [x] Fix bug where user can delete another users trade ideas
- [x] Reduce queryChartImage() requests
- [x] Use some Practical POP (Protocol Oriented Programming)
- [x] Log Trade Idea in Answers 

## Version 2.5.2:
- [x] Upgrade TwitterKit to 2.3.0 (check for placeholder error)
- [x] Move Fabric frameworks to pods
- [x] Fork the latest MDCSwipeToChoose and update to include StockSwipe features
- [x] Add reply, like, reshape feature to trade ideas
- [x] Upgrade ideaCell to include nested trade ideas
- [x] Add a new trade idea detail view 
- [x] Update profile tableview cells 

## Version 2.5.3:
- [x] Add following feature
- [x] Add Idea, Following, Followers, Liked count in profile
- [x] Move settings into a new VC, rename old to “More”
- [x] Redesign Company Profile view to use UIStackView
- [x] Redesign icons on more page
- [x] Add Block & Report feature
- [x] handle user query with “username_lowercase”
- [x] Redo Facebook/Twitter info capturing section

## Version 2.5.4:
- [x] Add push notification support
- [x] Take another jab at fixing the crash in top stories 

## Version 2.5.5:
- [x] Make TradeIdea posts attach to multiple stocks and users
- [x] Add Notification Center

## Version 2.5.6:
- [x] Add search functionality with most trending/recent searches
- [x] Add cardsview long press gesture instead of auto add to watchlist when swiped
- [x] Fix bug on profile view where loading more info uses the wrong datasource
- [x] Take advantage of caching
- [x] Fix crash introduced in V2.5.5 && Parse 1.14.0 bug

## Version 2.5.7:
- [x] Fix swipe reset when not logged in (overlay gets stuck)
- [x] Move login/out inside the profile view
- [x] Fix hashtag with special characters
- [x] Fix repetitive hashtags not being recognized

## Version 2.5.8:
- [x] Add new trade ideas section in OverviewController
- [x] Allow users to compose trade ideas from OverviewController
- [x] Allow users to search stocks from OverviewController
- [x] Expand search to find users
- [x] Fix resolveTags recognizing cashtags from just numbers
- [x] Capture more login info
- [x] Add invite Facebook friends feature

## Version 2.5.9:
- [x] Be ‘lazy’ as much as possible with array mapping
- [x] Only new trade ideas should show on MarketView section (not replies/reshare) 
- [x] Fix cell auto dimensions on trade idea tableview
- [x] Fix reply trade idea being added to delegate ViewController
- [x] Clean up TradeIdea & User classes
- [x] Fix endless requests for checkLike & checkReshare in ideaCell
- [x] Fix trade idea reshare with empty idea (space and empty trade idea detail)
- [x] Log Facebook invite friends action
- [x] Move Feedback to its own Storyboard
- [x] Move Login flow to its own Storyboard
- [x] Clean up project structure
- [x] Use Reachability framework instead of self-made solution
- [x] Upgrade to Swift 3.0 
- [x] Set fetch limit on notification center requests and fetch more when scroll
- [x] Add push notification for when a user is mentioned in a trade idea (with settings flag)
- [x] Fix unwanted queryWith query caching (top news etc)

## Version 2.5.10:
- [x] Fix refresh/update queries for trade ideas
- [x] Fix cloud words overlapping glitch
- [x] Fix idea posted to the wrong profile
- [x] Fix idea post with nothing in it
- [x] Update screenshots 
- [x] Update push certificates

## Version 2.5.11:
- [x] Release 2.5.11 to make up for 2.5.10 missing features (exchange of build during review process)
- [x] Implement ideaUpdated delegate method to handle when a like/reshare count change happens
- [x] Continue ideaPostDelegate improvements
- [x] Adjust colors on companyprofile analyst rating view

## Version 2.5.12:
- [x] Fix login delegate not passed back to MoreVC
- [x] Log swipes in Answers
- [x] Fix CoreSpotlight optional description
- [x] Fix incorrect long/short count on cards view

## Version 2.5.13:
- [x] Fix a glitch with replyTradeIdeas
- [x] Adjust share chart tip so it doesn’t block the settings behind it
- [x] Add line breaks in CoreSpotlight item [partially done]
- [x] Adjust “More” page row vertical alignment
- [x] Fix carousel ticker rounding issue 
- [x] Add price color to ticker carousel
- [x] Resolve carousel stocks not decoded on iPhone (“%5E” bug)

## Version 2.5.14:
- [x] Log Login in Answers
- [x] Support Rollout.io Swift ## Version
- [x] Update Charts library to 3.0.0
- [x] Redo Chart, Trade Idea, User classes to revert completion in init() concept
- [x] Attempt to fix SearchTableView crash

## Version 2.5.15:
- [x] Fix company profile chart issues caused by Chart 3.0 upgrade
- [x] Refactor chartDetail, tradeIdea and profile storyboards
- [x] Fix user no image override 
- [x] Add setting to auto add swipes to watchlist 
- [x] Add a “add to watchlist” button in the chart detail view.
- [x] Add “All Things Stocks” link to more page
- [x] Fix medium stories opening blank with safari reader mode

## Version 2.5.16:
- [x] Fix crash caused by Trade Idea being empty [might already be resolved]
- [x] Fix SearchTableView persisting crash
- [x] Log user follow activity in Answers
- [x] Add Activity Type to Answers log of trade ideas
- [x] Update Cocoapods

## Version 2.5.17:
- [x] Update Parse Server


## Version 2.5.18:
- [x] Fix crash in Trade Idea cells
- [x] Update Cocoapods
- [x] Clean while refactoring

## Version 2.5.19:
- [x] Update to Swift 4.2
- [x] Add real-time data
- [x] Fix company profile section 2 missing info
- [x] Support email login/signup
- [x] minor fixes

## Version 2.5.20:
- [x] minor bug fixes introduced in 2.5.19
- [x] minor improvements to the UI
- [x] Chart share should deeplink to symbol 
