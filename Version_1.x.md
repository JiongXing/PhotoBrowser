# JXPhotoBrowser


# Features
- [x] 支持缩放式转场动画
- [x] 支持淡入淡出式转场动画
- [x] 支持下滑手势渐变关闭浏览器
- [x] 支持初始图、大图和原图三个级别
- [x] 支持`GIF`格式
- [x] 支持`WebP`格式
- [x] 支持本地图片
- [x] 支持自定义图片加载器，此时不依赖任何第三方框架
- [x] 支持嵌入导航栏
- [x] 支持屏幕旋转
- [x] 支持修改数据源，刷新浏览器
- [x] 支持长按返回当前图片对象
- [x] 支持在浏览场景自由添加视图
- [x] 支持插件开发，自由扩展功能
- [x] 插件式集成光点型的页码指示器
- [x] 插件式集成数字型的页码指示器
- [x] 插件式集成图片加载进度指示器
- [x] 插件式集成查看原图按钮
- [ ] 完美支持短视频浏览

# Version History

## Version 1.6.1
**2018/09/28**
- 修正Cocoapods配置的Swift版本

## Version 1.6.0
**2018/09/20**
- 更新到 Swift 4.2
- 看图插件支持设置3D-Touch中Peek操作的选项

## Version 1.5.1
**2018/08/22**
- 修复长图下拉没有触发关闭的问题

## Version 1.5.0
**2018/08/16**
- 长按事件回调时返回手势对象
- 打开新页面时自动还原状态栏显示，也可以主动控制隐藏/显示
- 下移了光点型页码指示器在iPhoneX上的默认位置
- 修复iPhoneX横屏显示问题

查看更多日志：[CHANGELOG](CHANGELOG.md)

# Requirements
- iOS 9.0
- Xcode 10
- Swift 4.2

# Installation

## CocoaPods
更新你的本地仓库以同步最新版本
```
pod repo update
```
在你项目的Podfile中配置
```
pod 'JXPhotoBrowser'
```

![Introduction](https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Introduction.gif)

# Usage

## 初始化 & 展示

类方法直接打开图片浏览器：
```swift
// 直接打开图片浏览器
// delegate: 协议代理
// originPageIndex: 打开时的初始页码
PhotoBrowser.show(delegate: self, originPageIndex: indexPath.item)

```

也可以先创建浏览器，配置好需要的特性，再打开：
```swift
// 创建图片浏览器
let browser = PhotoBrowser(){
// 提供两种动画效果：缩放`.scale`和渐变`.fade`。
// 如果希望`scale`动画不要隐藏关联缩略图，可使用`.scaleNoHiding`。
browser.animationType = .scale
// 浏览器协议实现者
browser.photoBrowserDelegate = self
// 装配页码指示器插件，提供了两种PageControl实现，若需要其它样式，可参照着自由定制
// 光点型页码指示器
browser.plugins.append(DefaultPageControlPlugin())
// 数字型页码指示器
browser.plugins.append(NumberPageControlPlugin())
// 指定打开图片组中的哪张
browser.originPageIndex = index
// 展示
browser.show()
/* 或者自己 present 展示
 viewController.present(browser, animated: true, completion: nil)
 */
```

如果只是浏览本地图片的话，可以更简单。
默认使用`.fade`转场动画，不需要实现任何协议方法，一行代码打开图片浏览器：
```swift
PhotoBrowser.show(localImages: localImages, originPageIndex: index)
```
如果想使用`.scale`转场动画浏览本地图片，只需要传入`delegate`，然后实现`photoBrowser(_:, thumbnailViewForIndex:)`协议方法即可。
```swift
PhotoBrowser.show(localImages: localImages, animationType: .scale, delegate: self, originPageIndex: index)
```

如果想在浏览场景添加一些视图，你可以自己开发插件。
例子给出了添加图片描述和图片删除按钮的做法：
```swift
let browser = PhotoBrowser()
// 装配附加视图插件
let overlayPlugin = OverlayPlugin()
overlayPlugin.dataSourceProvider = { [unowned self] index in
    // 附加视图数据源
    return self.overlayModels[index]
}
overlayPlugin.didTouchDeleteButton = { [unowned self] index in
    // 删除操作
}
browser.cellPlugins.append(overlayPlugin)

```

## 图片浏览器协议

浏览非本地图片时的必选协议方法
```swift
/// 共有多少张图片
func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
    return thumbnailImageUrls.count
}
```

使用缩放式动画的必选协议方法：
```swift
/// 各缩略图所在 view
func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
    return collectionView?.cellForItem(at: IndexPath(item: index, section: 0))
}

```

可选协议方法：
```swift
/// 各缩略图图片，也是图片加载完成前的 placeholder
func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
    let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? MomentsPhotoCollectionViewCell
    return cell?.imageView.image
}

/// 高清图
func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
    return URL(string: highQualityImageUrls[index])
}

/// 原图
func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? {
    return nil
}

/// 加载本地图片，本地图片的展示将优先于网络图片
func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? {
    return nil
}

/// 长按图片。你可以在此处得到当前图片，并可以做些弹个窗，保存图片等操作
func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {
    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let saveImageAction = UIAlertAction(title: "保存图片", style: .default) { (_) in
        print("保存图片：\(image)")
    }
    let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
    actionSheet.addAction(saveImageAction)
    actionSheet.addAction(cancelAction)
    photoBrowser.present(actionSheet, animated: true, completion: nil)
}
```

## 如何选用/禁用加载进度指示器和查看原图按钮
PhotoBrowser 的默认实现是同时选用了加载进度指示器和查看原图按钮：
```swift
browser.cellPlugins = [ProgressViewPlugin(), RawImageButtonPlugin()]
```
只选用加载进度指示器：
```swift
browser.cellPlugins = [ProgressViewPlugin()]
```
只选用查看原图按钮：
```swift
browser.cellPlugins = [RawImageButtonPlugin()]
```

## 如何嵌入导航栏
可以把 PhotoBrowser 嵌进你自己创建的导航控制器中。
注意转场动画类型只能使用`.fade`。假如使用`.scale`类型，会发生转场完成后的顿挫现象，至今未找到解决办法。
Demo示范代码：
```
func openPhotoBrowserWithNavigationController(index: Int) {
    let browser = PhotoBrowser(animationType: .fade, delegate: self, originPageIndex: index)
    let nav = UINavigationController(rootViewController: browser)
    browser.show(wrapped: nav)
}
```

## 如何加载`WebP`格式
本库实现了一个 WebP 版的 KingfisherLoader，只需要指定 Subspec 即可：
```
pod 'JXPhotoBrowser/KingfisherWebP'
```
注意，`pod 'JXPhotoBrowser'`等同于`pod 'JXPhotoBrowser/Kingfisher'`，`Kingfisher`与`KingfisherWebP`两者二选一。


## Install 出错：Error installing libwebp
谷歌家的`libwebp`是放在他家网上的，`pod 'libwebp'`的源指向了谷歌域名的地址，解决办法一是翻墙，二是把本地 repo 源改为放在 Github 上的镜像：
1. `pod search libwebp` 看看有哪些版本，记住你想 install 的版本号，一般用最新的就行，比如 1.0.0。
2. `pod repo` 查看 master 的 path，进入目录搜索 libwebp，进入 libwebp -> 1.0.0，找到`libwebp.podspec.json`
3. 打开`libwebp.podspec.json`，修改 source 地址：
```
"source": {
    "git": "https://github.com/webmproject/libwebp",
    "tag": "v1.0.0
  },
```
4. 回到你的项目目录，可以愉快地`pod install`了~

## 不想使用 Kingfisher，如何自定义加载器
1. 参考`KingfisherPhotoLoader`，写个类/结构体实现`PhotoLoader`协议。
2. 在初始化`PhotoBrowser`时，给`PhotoLoader`参数传入你的加载器实例。
3. 去除`Kingfisher`依赖：在你项目的`Podfile`中，改`pod 'JXPhotoBrowser'`为`pod 'JXPhotoBrowser/Core'`。
