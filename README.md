# JXPhotoBrowser

[![Version](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![License](https://img.shields.io/cocoapods/l/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![Platform](https://img.shields.io/cocoapods/p/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)

# Features
- [x] 支持本地图片
- [x] 支持初始图、高清图和原图三个级别
- [x] 支持`GIF`格式
- [x] 支持`WebP`格式
- [x] 支持Fade渐变转场动画
- [x] 支持Zoom缩放转场动画
- [x] 支持下滑手势关闭浏览器
- [x] 支持单击、双击、放大缩小、长按
- [x] 支持屏幕旋转
- [x] 支持修改数据源，重载数据
- [x] 支持代码调用图片切换
- [x] 支持继承图片浏览器
- [x] 支持自定义页视图Cell
- [x] 支持自定义图片加载器
- [x] 提供了基于`Kingfisher`的图片加载器实现
- [x] 提供了基于`KingfisherWebP`的WebP图片加载器实现
- [x] 提供了光点型的页码指示器的实现
- [x] 提供了数字型的页码指示器的实现
- [x] 提供了图片加载进度指示器的实现
- [x] 提供了查看原图按钮的实现
- [x] 提供了多种数据源代理、视图代理和转场动画代理的实现，自由搭配选用
- [ ] 纯视频、视频与图片混合（待开发）


<div>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Home.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Transition.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Browser.png" width = "30%" div/>
</div>

# Change Log

## Version 2.1.1
**2018/11/29**
- 优化横屏模式的显示效果，横屏时显示全图

## Version 2.1.0
**2018/10/27**
- 现可通过泛型的方式向三种默认的数据源指定要使用的Cell，并增加一个泛型方法在复用时直接返回所设置的Cell。
- 支持修改数据源，重载数据
- 支持代码调用图片切换
- 对传入的`pageIndex`保护，越界时自动修正为安全值。
- 可禁止添加长按手势。
- `JXNetworkingDataSource`和`JXRawImageDataSource`的初始化方法中，`localImage`重命名为`placeholder`，表意更清晰。
- 删除`JXPhotoBrowserBaseCell`的`setupViews`方法，子类应重写`init(frame: CGRect)`方法，然后作进一步初始化。

## Version 2.0.x
**2018/10/18**
- 重新设计了接口，使用起来更简单易懂。
- 进行了大规模重构，代码更优雅，更易扩展，更易维护。
- 注意如果是从1.x版本升级上来的，遇到无法编译情况，请清除Xcode的`Derived Data`。

## Version 1.6.1
1.x版本不再更新功能，若要使用，可参考：[Version_1.x](Version_1.x.md)。

## 更多
查看更多日志：[CHANGELOG](CHANGELOG.md)

# Requirements
- iOS 9.0
- Swift 4.2
- Xcode 10
> - 如需要用在Swift4.2之下的项目使用，请自行修改为相应Swift版本的语法。
> - 改为Swift4.0或4.1的语法，修改的地方只有几处，工作量不大。

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

## 手动导入
1. 请把`Source/Core`下的所有文件拷贝到你的项目。
2. 如果需要使用`Kingfisher`来加载网络图片，就把`Source/Kingfisher`下的文件也拷贝到你的项目，并导入`Kingfisher`库。
3. 如果需要加载`WebP`图片，就把`Source/KingfisherWebP`下的文件也拷贝到你的项目，并导入`KingfisherWebP`库。

# Usage

## 初始化 
创建图片浏览器需要三个参数，分别是数据源、视图代理、转场代理。
其中数据源是必须自行创建并传入，而视图代理和转场代理是可选的，它们有默认值。
```swift
open class JXPhotoBrowser: UIViewController {
    public init(dataSource: JXPhotoBrowserDataSource,
                delegate: JXPhotoBrowserDelegate = JXPhotoBrowserBaseDelegate(),
                transDelegate: JXPhotoBrowserTransitioningDelegate = JXPhotoBrowserFadeTransitioning())
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
let dataSource = JXLocalDataSource(numberOfItems: {
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
let delegate = JXPhotoBrowserBaseDelegate()
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
let delegate = JXDefaultPageControlDelegate()
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate:delegate).show(pageIndex: indexPath.item)
```

## 数字型页码指示器
```swift
// 视图代理，实现了数字型页码指示器
let delegate = JXNumberPageControlDelegate()
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate:delegate).show(pageIndex: indexPath.item)
```

## 转场动画
打开`JXPhotoBrowser`时，默认使用的转场动画是`Fade`渐变型的，如果想要`Zoom`缩张型，需要返回动画起始/结束位置给`Zoom`动画代理。
本框架提供了两种方案，你可选择返回起始/结束视图，或选择返回起始/结束坐标。
```swift
// 返回起始/结束 视图
let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> UIView? in
    let indexPath = IndexPath(item: index, section: 0)
    return collectionView.cellForItem(at: indexPath)
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
	.show(pageIndex: indexPath.item)
```

```swift
// 返回起始/结束 位置
let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> CGRect? in
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
let dataSource = JXNetworkingDataSource(photoLoader: loader, numberOfItems: { () -> Int in
    return self.dataSource.count
}, placeholder: { index -> UIImage? in
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
let dataSource = JXRawImageDataSource(photoLoader: loader, numberOfItems: { () -> Int in
    return self.dataSource.count
}, placeholder: { index -> UIImage? in
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
let loader = JXKingfisherLoader()
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
let loader = JXKingfisherWebPLoader()
let dataSource = JXPhotoBrowser.NetworkingDataSource(photoLoader: loader, ...)
```

## 自定义Cell
如果需要对页视图作更多自定义，可继承`JXPhotoBrowserBaseCell`创建你的Cell。
然后在创建数据源代理时，通过泛型的方式设置你的Cell：
```swift
// 数据源，通过泛型指定使用的<Cell>
let dataSource = JXNetworkingDataSource<CustomCell>(...)
// Cell复用回调
dataSource.configReusableCell { (cell, index) in
    // 给复用Cell刷新数据
}
```


## 禁用长按手势
可通过自定义Cell重写`isNeededLongPressGesture`属性以禁止：
```swift
class CustomCell: JXPhotoBrowserBaseCell {
    /// 是否需要添加长按手势。返回`false`即可避免添加长按手势
    override var isNeededLongPressGesture: Bool {
        return false
    }
}
```


# 常见问题

## Archive 打包错误
如果出现：
```
While deserializing SIL vtable for ...
abort trap 6
```
请升级你的工程到Swift4.2，即可解决。

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
