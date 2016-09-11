platform :ios, '9.0'
use_frameworks!

def shared_pods
    pod 'SwiftyJSON', :git => 'https://github.com/acegreen/SwiftyJSON.git', :branch => 'swift3'
end

target 'StockSwipe' do
    
    pod 'MDCSwipeToChoose', :git => 'https://github.com/acegreen/MDCSwipeToChoose.git'
    pod 'SDVersion'
    pod 'DZNEmptyDataSet'
    pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', :branch => 'Swift-3.0'
    pod 'SWXMLHash'
    pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'
    
    # Analytics
    pod 'Crashlytics'
    pod 'Appsee'
    pod 'LaunchKit'
    pod 'Rollout.io'
    pod 'ChimpKit'
    
    # Parse
    pod 'Parse'
    pod 'ParseFacebookUtilsV4'
    pod 'ParseTwitterUtils'
    pod 'ParseUI'
    
    # Facebook
    pod 'FacebookCore'
    pod 'FacebookShare'
    
    # Twitter
    pod 'TwitterKit'

    # Animation
    pod 'BubbleTransition'
    pod 'AMPopTip'
    pod 'SKSplashView', :git =>'https://github.com/acegreen/SKSplashView.git', :branch => 'ag-improvements'
    pod 'NVActivityIndicatorView'

    shared_pods
    
    # Retired
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
