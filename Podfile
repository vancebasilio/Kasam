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
pod 'SDWebImage', '~> 5.0'
pod 'FacebookCore'
pod 'FacebookLogin'
pod 'FacebookShare'
pod 'MXSegmentedPager'
pod 'Cosmos', '~> 19.0'
pod 'SkeletonView'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    end
  end
end
