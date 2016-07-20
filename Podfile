platform :ios, '9.0'
use_frameworks!

def shared_pods
    pod 'SwiftyJSON'
end

target 'StockSwipe' do
    
    pod 'MDCSwipeToChoose', :git => 'https://github.com/acegreen/MDCSwipeToChoose.git'
    pod 'SDVersion'
    pod 'DZNEmptyDataSet', '1.7.2'
    pod 'Charts'
    pod 'SWXMLHash'
    pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'
    
    # Analytics
    pod 'Crashlytics'
    pod 'TwitterKit'
    pod 'Appsee'
    pod 'LaunchKit'
    pod 'Rollout.io', '~> 0.14.4'
    pod 'ChimpKit'
    
    # Parse
    pod 'Parse'
    pod 'ParseFacebookUtilsV4'
    pod 'ParseTwitterUtils'
    pod 'ParseUI'

    # Animation
    pod 'PulsingHalo', :git => 'https://github.com/shu223/PulsingHalo.git'
    pod 'BubbleTransition'
    pod 'AMPopTip'
    pod 'SKSplashView', :git =>'https://github.com/acegreen/SKSplashView.git', :branch => 'ag-improvements'
    pod 'NVActivityIndicatorView'

    shared_pods
    
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
