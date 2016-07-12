platform :ios, '9.0'
use_frameworks!

def shared_pods
    pod 'SwiftyJSON'
end

def shared_With_Tests_pods
    pod 'Parse'
    pod 'ParseFacebookUtilsV4'
    pod 'ParseTwitterUtils'
    pod 'ParseUI'
end

target 'StockSwipe' do
    pod 'MDCSwipeToChoose', :git => 'https://github.com/acegreen/MDCSwipeToChoose.git'
    pod 'SDVersion'
    pod 'DZNEmptyDataSet', '1.7.2'
    pod 'PulsingHalo', :git => 'https://github.com/shu223/PulsingHalo.git'
    pod 'Charts'
    pod 'Crashlytics'
    shared_With_Tests_pods
    pod 'TwitterKit'
    pod 'Appsee'
    pod 'LaunchKit'
    pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift2'
    pod 'BubbleTransition'
    pod 'AMPopTip'
    pod 'Rollout.io', '~> 0.14.4'
    pod 'ChimpKit'
    pod 'SWXMLHash'
    pod 'SKSplashView', :git =>'https://github.com/acegreen/SKSplashView.git', :branch => 'supporting-nsoperationqueue'
    
    shared_pods
    
    #pod 'ChameleonFramework/Swift'
    #pod 'SwiftSpinner'
    #pod 'Fabric'
    #pod 'Answers'
    #pod 'TwitterCore'
end

target 'StockSwipeWidget' do
    shared_pods
end

target 'StockSwipeTests' do
    shared_With_Tests_pods
end
