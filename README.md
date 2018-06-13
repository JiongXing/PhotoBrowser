# JXPhotoBrowser
![](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![](https://img.shields.io/badge/pod-v1.3.1-blue.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Features
- [x] 支持缩放式转场动画
- [x] 支持淡入淡出式转场动画
- [x] 支持下滑手势渐变关闭浏览器
- [x] 支持初始图、大图和原图三个级别
- [x] 支持 GIF
- [x] 支持 WebP
- [x] 支持本地图片
- [x] 支持自定义图片加载器
- [x] 支持屏幕旋转
- [x] 支持修改数据源，刷新浏览器
- [x] 支持长按返回当前图片对象
- [x] 支持在浏览场景自由添加视图
- [x] 支持插件开发，自由扩展功能
- [x] 插件式集成光点型的页码指示器
- [x] 插件式集成数字型的页码指示器
- [x] 插件式集成图片加载进度指示器
- [x] 插件式集成查看原图按钮
- [ ] 自定义图片加载器时不必引入`Kingfisher`
- [ ] 支持浏览短视频
- [ ] 支持 React Native 

# Version History

> v1.0版本相比初版的实现已经发生较大的变化，除核心功能基本不变以外，我对外围代码作了大量重构。
如果是从旧版升级而来的同学，有不明白的地方请留言或联系我，我会尽可能提供帮助~

## Version 1.3.1
**2018/06/11**
- 修复取`TopMostViewController`可能不正确的问题。

## Version 1.3.0
**2018/06/04**
- 在`scale`转场模式下，可选择不隐藏关联缩略图。设置`animationType = .scaleNoHiding`即可。
- 对于浏览本地图片，现在同时支持传图片组和通过代理取本地图片两种方式。

## Version 1.2.0
**2018/5/26**
- 优化`DefaultPageControlPlugin.centerBottomY`和`NumberPageControlPlugin.centerY`为可选属性。在这两个属性为`nil`时，将使用默认值，并进行`iPhoneX`适配。如果用户为这两个属性赋了值，则框架认为用户自行完成了适配，将直接使用所赋值。

查看更多日志：[CHANGELOG](CHANGELOG.md)

# Requirements
- iOS 8.0+
- Swift 4

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

## Carthage
本库依赖Kingfisher，需一并引入。在你项目的Cartfile中配置
```
github "onevcat/Kingfisher"
github "JiongXing/PhotoBrowser"
```

![Introduction](https://github.com/JiongXing/PhotoBrowser/raw/master/resources/Introduction.gif)

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

# 初版实现思路

记录了初版实现思路：[ARTICLE](ARTICLE.md)

# 感谢

若使用过程中有任何问题，请issues我。 ^_^
