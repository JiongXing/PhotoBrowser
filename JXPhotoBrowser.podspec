
Pod::Spec.new do |s|
    s.name             = 'JXPhotoBrowser'
    s.version          = '2.0.1'
    s.summary          = 'Elegant photo browser in Swift.'
    s.description      = 'Elegant photo browser in Swift. Inspired by WeChat.'
    
    s.homepage         = 'https://github.com/JiongXing/PhotoBrowser'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'JiongXing' => 'liangjiongxing@qq.com' }
    s.source           = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '9.0'
    s.swift_version = '4.2'
    
    s.default_subspec = 'Kingfisher'
    
    s.subspec 'Core' do |cs|
        cs.source_files = 'Source/Core/*'
    end
    
    s.subspec 'Kingfisher' do |ks|
        ks.source_files = 'Source/Kingfisher/*'
        ks.dependency 'JXPhotoBrowser/Core'
        ks.dependency 'Kingfisher'
    end
    
    s.subspec 'KingfisherWebP' do |ks|
        ks.source_files = 'Source/KingfisherWebP/*'
        ks.dependency 'JXPhotoBrowser/Core'
        ks.dependency 'KingfisherWebP'
    end
    
end
