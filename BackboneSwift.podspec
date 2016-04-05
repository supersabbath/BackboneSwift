Pod::Spec.new do |s|
s.name         = 'BackboneSwift'
s.version      = '0.0.7'
s.summary      = 'BackboneSwift'
s.requires_arc = true
s.platform = :ios, :tvos  
s.tvos.deployment_target = '9.0'

s.ios.deployment_target = '8.1'
s.license = { :type => 'MIT', :text => '@see README' }
s.author = {
'Fernando Canon' => 'fernando.canon@starzplayarabia.com'
}
s.homepage  = 'https://github.com/supersabbath/BackboneSwift'
s.source = {
	:git => "https://github.com/supersabbath/BackboneSwift.git" , :tag => s.version
}
s.source_files = 'BackboneSwift/src/*.{swift}', 'BackboneSwift/src/utils/*.{swift}'
s.frameworks = 'UIKit'
s.dependency 'SwiftyJSON', '~> 2.3.2'
s.dependency 'Alamofire', '~> 3.0'
s.dependency 'PromiseKit', '~> 3.0.2'
 
end
