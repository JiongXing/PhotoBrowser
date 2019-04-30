
Pod::Spec.new do |s|
    s.name             = 'JXPhotoBrowser'
    s.version          = '2.1.4'
    s.summary          = 'Elegant photo browser in Swift.'
    s.description      = 'Elegant photo browser in Swift. Inspired by WeChat.'
    
    s.homepage         = 'https://github.com/JiongXing/PhotoBrowser'
    s.screenshots     = 'https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Transition.png'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'JiongXing' => 'liangjiongxing@qq.com' }
    s.source           = { :git => 'https://github.com/JiongXing/PhotoBrowser.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '9.0'
    s.swift_version = '4.2'
    
    s.default_subspec = 'Kingfisher'
    
    s.subspec 'Core' do |ss|
        ss.source_files = 'Source/Core/*', 'Source/Core/*/*'
    end
    
    s.subspec 'Kingfisher' do |ss|
        ss.source_files = 'Source/Kingfisher/*'
        ss.dependency 'JXPhotoBrowser/Core'
        ss.dependency 'Kingfisher'
    end
    
    s.subspec 'KingfisherWebP' do |ss|
        ss.source_files = 'Source/KingfisherWebP/*'
        ss.dependency 'JXPhotoBrowser/Core'
        ss.dependency 'KingfisherWebP'
    end
    
end
