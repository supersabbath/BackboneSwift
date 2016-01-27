Pod::Spec.new do |s|
s.name         = 'BackboneSwift'
s.version      = '1.0.0'
s.summary      = 'BackboneSwift'
s.requires_arc = true
s.license  = 'MIT'
s.author = {
'Fernando Canon' => 'fernando.canon@starzplayarabia.com'
}
s.homepage  = 'https://github.com/supersabbath'
s.source = {
:git => "git@git.parsifalentertainment.com:/iosplayer " , :tag => '1.0.0'
}
s.source_files = 'BackboneSwift/src/**/*.{switf}', 'BackboneSwift/src/utils/*.{swift}'
s.frameworks = 'UIKit'
end
