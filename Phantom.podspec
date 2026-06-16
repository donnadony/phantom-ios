Pod::Spec.new do |s|
    s.name             = 'Phantom'
    s.version          = '0.0.14'
    s.summary          = 'Debug toolkit for iOS apps'
    s.homepage         = 'https://github.com/donnadony/phantom-ios'
    s.license          = { :type => 'MIT' }
    s.author           = { 'Dony Mollo' => 'dony.mollo11@gmail.com' }
    s.source           = { :git => 'https://github.com/donnadony/phantom-ios.git', :tag => s.version.to_s }
    s.platform         = :ios, '14.0'
    s.source_files     = 'Sources/Phantom/**/*.swift'
    s.swift_version    = '5.9'
    s.requires_arc     = true
end
