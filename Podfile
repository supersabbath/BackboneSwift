source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.4'
use_frameworks!

def libraries
    
    pod 'Alamofire', '~> 3.5.0'
    pod 'PromiseKit/CorePromise', '~> 3.5.0'
    pod 'SwiftyJSON'
    
end

target :'BackboneSwift' do
  
    libraries
    
end


target :'BackboneSwiftTests' do
    libraries
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end
