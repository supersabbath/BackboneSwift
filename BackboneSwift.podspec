Pod::Spec.new do |s|
s.name         = 'BackboneSwift'
s.version      = '1.0.0'
s.summary      = 'BackboneSwift'
s.requires_arc = true
s.license  = 'MIT'
s.author = {
'Fernando Canon' => 'fernando.canon@starzplayarabia.com'
}
s.homepage  = 'https://github.com/supersabbath/BackboneSwift'
s.source = {
:git => "https://github.com/supersabbath/BackboneSwift.git" , :tag => '1.0.0'
}
s.source_files = 'BackboneSwift/src/*.{swift}', 'BackboneSwift/src/utils/*.{swift}'
s.frameworks = 'UIKit'
s.dependency 'SwiftyJSON', '~> 2.3.2'
s.dependency 'Alamofire', '~> 3.0'
s.dependency 'PromiseKit', '~> 3.0.2'
#, :path => '~/Projects/promiseKit/PromiseKit'
end
