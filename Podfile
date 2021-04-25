

target 'Kasam' do
  use_frameworks!

pod 'Firebase'
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'Firebase/Storage'
pod 'Firebase/Performance'
pod 'Firebase/Analytics'
pod 'Firebase/Messaging'
pod 'Fabric'
pod 'Crashlytics'
pod 'GoogleSignIn'
pod 'youtube-ios-player-helper'

pod 'FacebookCore'
pod 'FacebookLogin'
pod 'FacebookShare'

pod 'SVProgressHUD'
pod 'ChameleonFramework'
pod 'SDWebImage'
pod 'SwiftIcons'
pod 'Cosmos'

pod 'lottie-ios'
pod 'HGCircularSlider'
pod 'SkyFloatingLabelTextField'
pod 'Charts'
pod 'SwiftEntryKit'
pod 'IQKeyboardManagerSwift'
pod 'SwipeCellKit'
pod 'AMPopTip'

end

post_install do |pi|
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
end


