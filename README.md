# JXPhotoBrowser

[![Version](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![License](https://img.shields.io/cocoapods/l/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![Platform](https://img.shields.io/cocoapods/p/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)

# Features
- [x] 支持本地图片
- [x] 支持初始图、高清图和原图三个级别
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
- [x] 视频与图片混合展示


<div>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Home.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Transition.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Browser.png" width = "30%" div/>
</div>

# Change Log

## Version 3.0.0

**2019/12/06**

- 项目重构完成，更灵活，易扩展，适应性更强，无第三方库依赖。

> 各种需求场景的使用方法均有举例，请下载Example查看。
> 3.0版本说明文档正在完善，敬请期待。

## Version 2.1.6 (iOS9 +) & Version 2.2.6 (iOS 10 +)

**2019/11/10**

- 修复图片加载失败可能引发崩溃的问题

## Version 2.1.5/2.2.5

**2019/10/11**

> v2.1.5支持到iOS9，使用Kingfisher 4.x版本。v2.2.5因为使用了 Kingfisher 5.x，最低只能支持到iOS10。

> Kingfisher 5.x 的图片缓存与先前版本不太一样，可能在这里有问题。

> 未来版本增加SDWebImage支持示例，对网络图片的加载会进一步解耦，甚至加载视频。

- 现在`imageMaximumZoomScale`属性已启用。
- 数字页码添加半透背景，解决预览白图时数字消失问题。
- 现在自动支持`Swift 5`编译。

## Version 2.2.3（iOS9: 2.1.4）

**2019/04/30**

- 支持RTL语言的布局
- 优化弱网环境下加载网络图片的进度指示显示

## Version 2.2.1

**2019/04/12**

- 优化屏幕旋转时的闪烁问题

## Version 2.2.0
**2019/04/01**

- 支持Kingfisher 5.x，同时最低支持iOS 10.0
- `JXPhotoLoader`协议替换`imageCached(on:, url:)`为`hasCached(with url:)`

## Version 2.1.3

**2019/01/06**
- 优化长图转场动画，视觉更流畅

## Version 2.1.2
**2018/12/07**

- 修复显示长图时可能发生的交互BUG

## Version 2.1.1
**2018/11/29**
- 优化横屏模式的显示效果，横屏时显示全图

## Version 1.6.1
1.x版本不再更新功能，若要使用，可参考：[Version_1.x](Version_1.x.md)。

## 更多
查看更多日志：[CHANGELOG](CHANGELOG.md)

# Requirements
- iOS 9.0 +
- Swift 4.2 +

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

## 手动导入

1. 请把`Source/Core`下的所有文件拷贝到你的项目。
2. 如果需要使用`Kingfisher`来加载网络图片，就把`Source/Kingfisher`下的文件也拷贝到你的项目，并导入`Kingfisher`库。
3. 如果需要加载`WebP`图片，就把`Source/KingfisherWebP`下的文件也拷贝到你的项目，并导入`KingfisherWebP`库。

# Usage

> 3.0版本说明文档正在完善，敬请期待。

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
打开图片浏览器之前，可以指定显示图片组中的哪张图片，计数从0开始：
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
打开`JXPhotoBrowser`时，默认使用的转场动画是`Fade`渐变型的，如果想要`Zoom`缩张型，需要返回动画"起始/结束"的前置视图位置给`Zoom`动画代理。
本框架提供了两种方案，你可选择返回起始/结束视图，或选择返回起始/结束视图的Frame。
```swift
// 返回"起始/结束"的前置视图
let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> UIView? in
    let indexPath = IndexPath(item: index, section: 0)
    // 获取前置视图
    let cell = collectionView.cellForItem(at: indexPath) as? CustomCell
    return cell?.imageView
}
// 打开浏览器
JXPhotoBrowser(dataSource: dataSource, delegate: delegate, transDelegate: trans)
	.show(pageIndex: indexPath.item)
```

```swift
// 返回"起始/结束"的前置视图位置
let trans = JXPhotoBrowserZoomTransitioning { (browser, index, view) -> CGRect? in
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? CustomCell else {
        return nil
    }
    // 这里提供了一个方法，用于获取前置视图在转场容器中的Frame。
    // 你也可以自己实现需要的Frame。
    return JXPhotoBrowserZoomTransitioning.resRect(oriRes: cell.imageView, to: view)
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
