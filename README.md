# JXPhotoBrowser

[![Version](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![License](https://img.shields.io/cocoapods/l/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![Platform](https://img.shields.io/cocoapods/p/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)

<div>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Snip20181017_1.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Snip20181017_2.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Snip20181017_3.png" width = "30%" div/>
</div>

# Version History

## Version 2.0.x
**2018/10/18**
- 重新设计了接口，使用起来更简单易懂。
- 进行了大规模重构，代码更优雅，更易扩展，更易维护。
- 注意如果是从1.x版本升级上来的，遇到无法编译情况，请清除Xcode的`Derived Data`

## Version 1.6.1
1.x版本不再更新功能，若要使用，可参考：[Version_1.x](Version_1.x.md)

## 更多
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
如果需要加载WebP图片，则引入subspec
```
pod 'JXPhotoBrowser/KingfisherWebP'
```

# Usage

## 初始化 
创建图片浏览器需要三个参数，分别是数据源、视图代理、转场代理。
其中数据源是必须自行创建并传入，而视图代理和转场代理是可选的，它们有默认值。
```swift
open class JXPhotoBrowser: UIViewController {
    public init(dataSource: JXPhotoBrowserDataSource,
                delegate: JXPhotoBrowserDelegate = BaseDelegate(),
                transDelegate: JXPhotoBrowserTransitioningDelegate = FadeTransitioning())
}
```

## 打开图片浏览器
打开图片浏览器之前，需要指定所浏览图片的序号：
```swift
photoBrowser.pageIndex = selectedIndex
```
然后通过`UIViewController`的`present`方法打开：
```swift
viewController.present(photoBrowser, animated: true, completion: nil)
```
还有更简洁的代码是这样：
```swift
JXPhotoBrowser(dataSource: dataSource).show(pageIndex: indexPath.item)
```

## 本地图片
项目例子展示了如何浏览本地图片：
```swift
// 数据源
let dataSource = JXPhotoBrowser.LocalDataSource(numberOfItems: {
    // 共有多少项
    return self.dataSource.count
}, localImage: { index -> UIImage? in
    // 每一项的图片对象
    return self.dataSource[index].localName.flatMap({ name -> UIImage? in
        return UIImage(named: name)
    })
})
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource).show(pageIndex: indexPath.item)
```

## 动作事件
默认实现了单击、双击、拖拽、长按事件。可以给视图代理设置长按事件的回调：
```swift
// 视图代理
let delegate = JXPhotoBrowser.BaseDelegate()
// 长按事件
delegate.longPressedCallback = { browser, index, image, gesture in
	// ...
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate).show(pageIndex: indexPath.item)
```

## 光点型页码指示器
可通过自定义视图代理来增加控件
```swift
// 视图代理，实现了光点型页码指示器
let delegate = JXPhotoBrowser.DefaultPageControlDelegate()
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate:delegate).show(pageIndex: indexPath.item)
```

## 数字型页码指示器
```swift
// 视图代理，实现了数字型页码指示器
let delegate = JXPhotoBrowser.NumberPageControlDelegate()
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate:delegate).show(pageIndex: indexPath.item)
```

## 转场动画
打开`JXPhotoBrowser`时，默认使用的转场动画是`Fade`渐变型的，如果想要`Zoom`缩张型，需要返回动画起始/结束位置给`Zoom`动画代理。
本框架提供了两种方案，你可选择返回起始/结束视图，或选择返回起始/结束坐标。
```swift
// 返回起始/结束 视图
let trans = JXPhotoBrowser.ZoomTransitioning { (browser, index, view) -> UIView? in
    let indexPath = IndexPath(item: index, section: 0)
    return collectionView.cellForItem(at: indexPath)
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
	.show(pageIndex: indexPath.item)
```

```swift
// 返回起始/结束 位置
let trans = JXPhotoBrowser.ZoomTransitioning { (browser, index, view) -> CGRect? in
    let indexPath = IndexPath(item: index, section: 0)
    if let cell = collectionView.cellForItem(at: indexPath) {
        return cell.convert(cell.bounds, to: view)
    }
    return nil
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
	.show(pageIndex: indexPath.item)
```

## 网络图片-两级：缩略图和高清图
加载网络图片需要指定网图加载器，本框架以`Kingfisher`为基础实现加载器。
如果你不想使用`Kingfisher`，可自己实现一个网图加载器。
要加载网络图片，需要使用网络资源数据源，本框架实现了一个`NetworkingDataSource`：
```
// 网图加载器
let loader = JXPhotoBrowser.KingfisherLoader()
// 数据源
let dataSource = JXPhotoBrowser.NetworkingDataSource(photoLoader: loader, numberOfItems: { () -> Int in
    return self.dataSource.count
}, localImage: { index -> UIImage? in
    let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell
    return cell?.imageView.image
}) { index -> String? in
    return self.dataSource[index].secondLevelUrl
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
    .show(pageIndex: indexPath.item)
```

## 网络图片-三级：缩略图、高清图和原图
如果资源有三个级别，需要有查看原图功能的话，本框架也实现了一个数据源`RawImageDataSource`：
```swift
// 网图加载器
let loader = JXPhotoBrowser.KingfisherLoader()
// 数据源
let dataSource = JXPhotoBrowser.RawImageDataSource(photoLoader: loader, numberOfItems: { () -> Int in
    return self.dataSource.count
}, localImage: { index -> UIImage? in
    let cell = collectionView.cellForItem(at: indexPath) as? BaseCollectionViewCell
    return cell?.imageView.image
}, autoloadURLString: { index -> String? in
    return self.dataSource[index].secondLevelUrl
}) { index -> String? in
    return self.dataSource[index].thirdLevelUrl
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
    .show(pageIndex: indexPath.item)
```

## GIF图片
`Kingfisher`已支持加载`GIF`格式，所以可直接使用`KingfisherLoader`：
```swift
// 网图加载器
let loader = JXPhotoBrowser.KingfisherLoader()
let dataSource = JXPhotoBrowser.NetworkingDataSource(photoLoader: loader, ...)
```

## WebP图片
要加载`WebP`图片，本框架实现了一个网图加载器`KingfisherWebPLoader`，需要在`podfile`文件引入subspec：
```
pod 'JXPhotoBrowser/KingfisherWebP'
```
然后使用它作为网图加载器：
```swift
// 网图加载器，WebP加载器
let loader = JXPhotoBrowser.KingfisherWebPLoader()
let dataSource = JXPhotoBrowser.NetworkingDataSource(photoLoader: loader, ...)
```

# 常见问题

## Install 错误：Error installing libwebp
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

# 初版实现思路

记录了初版实现思路：[ARTICLE](ARTICLE.md)

# 感谢

若使用过程中有任何问题，请issues我。 ^_^
