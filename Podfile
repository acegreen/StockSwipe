platform :ios, '11.0'
use_frameworks!

def shared_pods
    pod 'SwiftyJSON'
end

target 'StockSwipe' do
    
    # Utility
    pod 'MDCSwipeToChoose', :git => 'https://github.com/acegreen/MDCSwipeToChoose.git'
    pod 'SDVersion'
    pod 'DZNEmptyDataSet'
    pod 'Charts', '3.2.1'
    pod 'SWXMLHash'
    pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'
    pod 'ReachabilitySwift'
    pod 'NotificationBannerSwift'

    # Analytics
    pod 'Crashlytics'
    pod 'ChimpKit'
    
    # Parse
    pod 'Parse'
    pod 'Parse/FacebookUtils'
    pod 'Parse/TwitterUtils'
    pod 'Parse/UI'
    
    # Facebook
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    #pod 'FacebookCore'
    #pod 'FacebookShare'
    
    # Twitter
    pod 'TwitterKit'

    # Animation
    pod 'BubbleTransition'
    pod 'AMPopTip'
    pod 'SKSplashView', :git =>'https://github.com/acegreen/SKSplashView.git', :branch => 'ag-improvements'
    pod 'NVActivityIndicatorView'

    shared_pods
    
    # Retired
    #pod 'LaunchKit'
    #pod 'PulsingHalo', :git => 'https://github.com/shu223/PulsingHalo.git'
    #pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift2'
    #pod 'ChameleonFramework/Swift'
    #pod 'SwiftSpinner'
    #pod 'Fabric'
    #pod 'Answers'
    #pod 'TwitterCore'
end

target 'StockSwipeWidget' do
    shared_pods
end
