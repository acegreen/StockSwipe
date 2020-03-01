platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

def shared_pods
  # Utility
  pod 'SwiftyJSON'
  pod 'DataCache', :git => 'https://github.com/huynguyencong/DataCache.git'
  pod 'ReachabilitySwift'

  # Analytics
  pod 'Firebase/Core'
end

target 'StockSwipe' do
  shared_pods

  # Utility
  pod 'SDVersion'
  pod 'SWXMLHash'

  # Analytics
  pod 'ChimpKit'
  pod 'Branch'

  # Parse
  pod 'Parse'
  pod 'Parse/FacebookUtils'
  pod 'Parse/TwitterUtils'
  pod 'Parse/UI'

  # Facebook
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'FacebookShare'

  # Twitter
  pod 'TwitterKit'

  # UI/Animation
  pod 'MDCSwipeToChoose', :git => 'https://github.com/acegreen/MDCSwipeToChoose.git'
  pod 'Charts'
  pod 'BubbleTransition'
  pod 'DZNEmptyDataSet'
  pod 'AMPopTip'
  pod 'NotificationBannerSwift'
  pod 'SKSplashView', :git =>'https://github.com/acegreen/SKSplashView.git', :branch => 'ag-improvements'
  pod 'NVActivityIndicatorView'
  pod 'UICountingLabel'

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

target 'StockSwipeTests' do
  inherit! :search_paths
  shared_pods
  pod 'OHHTTPStubs/Swift', '~> 8.0'
end

target 'StockSwipeWidget' do
  shared_pods
end
