
Pod::Spec.new do |s|
    s.name             = 'JXPhotoBrowser'
    s.version          = '3.1.2'
    s.summary          = 'Elegant photo browser in Swift.'
    s.description      = 'Elegant photo browser in Swift. Inspired by WeChat.'
    
    s.homepage         = 'https://github.com/JiongXing/PhotoBrowser'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'JiongXing' => 'liangjiongxing@qq.com' }
    s.source           = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '8.0'
    s.swift_version = '4.0', '4.2', '5.0'
    s.source_files = 'Sources/JXPhotoBrowser/*'
    
end
