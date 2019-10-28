platform :ios, '9.0'

target 'Kasam' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Kasam

pod 'Firebase'
pod 'Firebase/Auth'
pod 'Firebase/Database'
pod 'Firebase/Storage'
pod 'SVProgressHUD'
pod 'ChameleonFramework'
pod 'Parchment'
pod 'FSCalendar'
pod 'SDWebImage'
pod 'FacebookCore'
pod 'FacebookLogin'
pod 'FacebookShare'
pod 'MXSegmentedPager'
pod 'Cosmos'
pod 'SwiftIcons'
pod 'lottie-ios'
pod 'SwiftEntryKit'
pod 'HGCircularSlider'
pod 'SkyFloatingLabelTextField'
pod 'Charts'
pod 'SwiftEntryKit', '1.1.4'
pod 'SkeletonView'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
            if ['Gifu'].include? target.name
                target.build_configurations.each do |config|
                    config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
end


