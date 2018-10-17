
Pod::Spec.new do |s|
    s.name             = 'JXPhotoBrowser'
    s.version          = '2.0.3'
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
    
    s.subspec 'Core' do |ss|
        ss.source_files = 'Source/Core/*'
        ss.dependency 'JXPhotoBrowser/Protocol'
        ss.dependency 'JXPhotoBrowser/Animator'
        ss.dependency 'JXPhotoBrowser/Enhance'
        ss.dependency 'JXPhotoBrowser/Transition'
        ss.dependency 'JXPhotoBrowser/Networking'
        ss.dependency 'JXPhotoBrowser/Utils'
    end

    s.subspec 'Protocol' do |ss|
        ss.source_files = 'Source/Protocol/*'
    end

    s.subspec 'Animator' do |ss|
        ss.source_files = 'Source/Animator/*'
    end

    s.subspec 'Enhance' do |ss|
        ss.source_files = 'Source/Enhance/*'
    end

    s.subspec 'Transition' do |ss|
        ss.source_files = 'Source/Transition/*'
    end

    s.subspec 'Networking' do |ss|
        ss.source_files = 'Source/Networking/*'
    end

    s.subspec 'Utils' do |ss|
        ss.source_files = 'Source/Utils/*'
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
