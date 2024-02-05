# JXPhotoBrowser

[![Version](https://img.shields.io/cocoapods/v/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![License](https://img.shields.io/cocoapods/l/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)
[![Platform](https://img.shields.io/cocoapods/p/JXPhotoBrowser.svg?style=flat)](https://cocoapods.org/pods/JXPhotoBrowser)


<div>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Home.gif" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Transition.png" width = "30%" div/>
	<img src="https://github.com/JiongXing/PhotoBrowser/raw/master/Assets/Browser.png" width = "30%" div/>
</div>

(更多演示请看Demo)


## 特性

- [x] 支持图片、视频、图片与视频混合浏览
- [x] 支持横向和竖向滚动
- [x] 支持嵌入导航栏
- [x] 支持`push`和`present`打开
- [x] 支持数据源实时变更，框架不持有数据源
- [x] 支持自定义转场动画，框架提供了`Fade`、`Zoom`、`SoomthZoom`三个转场动画的实现
- [x] 支持自定义Cell，框架提供了常用的图片展示Cell的实现
- [x] 支持网络图片加载、查看原图加载，由用户自由选择其他框架进行图片加载与缓存
- [x] 支持添加附加控件，框架提供了两种页面指示器的实现，以及在例子工程提供了加载进度环的实现

## 近期版本更新

### Version 3.1.5

> 2024/02/05

- 优化和修复已知问题，包括#213 #216 #217 #221 #224 #225

### 历史更新记录

- [CHANGELOG](CHANGELOG.md)


## 环境要求

- iOS 11.0 及以上

## 安装方法

### Cocoapods

在`podfile`配置

```
pod 'JXPhotoBrowser'
```

### Swift Package Manager (Xcode 11+)

使用Xcode的包管理器添加本仓库URL。

`File -> Swift Packages -> Add Package Dependency`

添加URL：`https://github.com/JiongXing/PhotoBrowser`

### Manual

把本仓库下载到你本地，然后把`Sources`文件夹下的`JXPhotoBrowser`文件夹整个拖入Xcode，勾选拷贝文件选项即可，没有其它第三方依赖。

## 使用方法

> 以下代码取自项目Example例子工程，更详细完整的代码请打开例子工程查看，下文是其关键代码的讲解。

### 基本用法

#### 1.先实例化一个图片浏览器对象。

注意每次打开图片浏览，都应该重新实例化（重新实例化的开销很小，不必担心）。

```swift
let browser = JXPhotoBrowser()
```

#### 2.实时提供图片总量。

因考虑到数据源有可能是在浏览过程中变化的，所以JXPhotoBrowser框架（以下简称'框架'）将会在适当时机调用闭包动态获取当前用户的数据源数量，类似`UITableView`的机制。

```swift
browser.numberOfItems = {
    self.dataSource.count
}
```

#### 3.刷新项视图。

框架的项视图(展示单张图片的View)是复用的，由最多3个视图重复使用来实现无限数量的图片浏览。

在每个项视图需要被刷新时，`reloadCellAtIndex`闭包将会被调用，用户应当在此时更新对应数据源的视图展示。

框架默认实现并使用了`JXPhotoBrowserImageCell`作为项视图，用户也可以自由定制项视图，更多细节在下文介绍。

`JXPhotoBrowserImageCell`有一个`imageView`视图，用户只需要对其加载图片即可正常使用。

```swift
browser.reloadCellAtIndex = { context in
    let browserCell = context.cell as? JXPhotoBrowserImageCell
    let indexPath = IndexPath(item: context.index, section: indexPath.section)
    browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
}
```

#### 4.指定打开图片浏览器时定位到哪一页。

所赋的值应当在用户数据源的范围内，如数据源共有10项，则`pageIndex`允许范围是`0~9`。

```swift
browser.pageIndex = indexPath.item
```

#### 5.显示图片浏览器

浏览器主类`JXPhotoBrowser`是一个`UIViewController`，支持导航栏`push`，也支持模态`present`。
框架提供的`show()`方法封装实现了常见的打开方式。

无参调用`show()`方法的时候，默认使用了`present`模态打开一个不带导航栏的图片浏览器。

```swift
browser.show()
```

### 转场动画

用户可自由编写自己的转场动画，也可以使用框架已实现的三种动画。
框架的转场动画实现类是一个遵循了`JXPhotoBrowserAnimatedTransitioning`协议的对象。只需要把动画实现类赋值给`PhotoBrowser`的`transitionAnimator`属性，即可生效。
如果用户不指定动画，`transitionAnimator`属性将会使用默认赋值的`fade`渐变动画。

```swift
lazy var transitionAnimator: JXPhotoBrowserAnimatedTransitioning = JXPhotoBrowserFadeAnimator()
```

框架实现了图片打开时从小图位置放大，关闭时缩小回原位置的动画效果（以下简称Zoom动画），有两种实现，分别是：`JXPhotoBrowserZoomAnimator`和`JXPhotoBrowserSmoothZoomAnimator`。

`JXPhotoBrowserZoomAnimator`提供了最简便的方法让用户快速获得Zoom动画，只需要告诉框架，所浏览大图对应的缩略图视图即可。

```swift
browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
    let path = IndexPath(item: index, section: indexPath.section)
    let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell
    return cell?.imageView
})
```

`JXPhotoBrowserSmoothZoomAnimator`提供了更丝滑流畅的Zoom动画，但是使用上会复杂一点，需要用户自己给出转场视图以及缩略图的位置大小。

```swift
browser.transitionAnimator = JXPhotoBrowserSmoothZoomAnimator(transitionViewAndFrame: { (index, destinationView) -> JXPhotoBrowserSmoothZoomAnimator.TransitionViewAndFrame? in
    let path = IndexPath(item: index, section: indexPath.section)
    guard let cell = collectionView.cellForItem(at: path) as? BaseCollectionViewCell else {
        return nil
    }
    let image = cell.imageView.image
    let transitionView = UIImageView(image: image)
    transitionView.contentMode = cell.imageView.contentMode
    transitionView.clipsToBounds = true
    let thumbnailFrame = cell.imageView.convert(cell.imageView.bounds, to: destinationView)
    return (transitionView, thumbnailFrame)
})
```

现在讲解更详细的用法。

`JXPhotoBrowserAnimatedTransitioning`协议继承自`UIViewControllerAnimatedTransitioning`，协议声明的3个计算属性都是可选实现。

```swift
protocol JXPhotoBrowserAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    var isForShow: Bool { get set }
    var photoBrowser: JXPhotoBrowser? { get set }
    var isNavigationAnimation: Bool { get set }
}
```

用户需要自定义转场动画时，关注点仅在实现`UIViewControllerAnimatedTransitioning`上。`isForShow`和`photoBrowser`的值将由JXPhotoBrowser注入，用户可在编写自己的动画实现时获取到它们的值以帮助开发。

Zoom转场动画如果需要百分百过渡顺滑，需要小图和大图的尺寸比例一致，拉伸方式、对齐方式也一致才可以达到视觉上的自然。

具体在代码实现上，需要转场的视图在小尺寸时和缩略图吻合，同时要在放大后和浏览大图吻合。如果缩略图是居中显示的，大图是顶端对齐的，那么转场视图也需要在动画过程中同时调整对齐方式。由于框架无法预实现所有应用场景，同时也为了让用户更灵活地针对自己的应用场景做定制，所以对于这种完美转场效果的需求，`JXPhotoBrowserSmoothZoomAnimator`要求用户自行创建转场动画视图，以及计算出前后两端的`Frame`。

关于`转场动画视图前后两端的Frame`，是指基于PhotoBrowser.view的坐标系的Frame。

对于大图端的Frame，只要图片浏览的的项视图遵循了`JXPhotoBrowserZoomSupportedCell`协议，告诉框架其内容视图对象是哪个，框架即可自动计算出大图端的Frame。

```swift
/// 支持Zoom转场的Cell
protocol JXPhotoBrowserZoomSupportedCell: UIView {
    /// 内容视图
    var showContentView: UIView { get }
}
```

框架提供的作为默认项视图载体的`JXPhotoBrowserImageCell`已经遵循了SupportedCell协议，如果用户需要自定义Cell，同时希望应用ZoomAnimator，那么需要这个自定义Cell遵循`JXPhotoBrowserZoomSupportedCell`协议。

对于小图端的Frame，用户需要自行计算出Frame给SmoothZoomAnimator使用。

而实际应用环境中，有可能图片尺寸过大，缩略图被裁剪，这种情况下转场的前后两端是没办法吻合，框架为此做了一种折中方案，分别取小图和大图两端截图，作为两张转场视图叠加在一起，然后同时渐变加缩放，这就是`JXPhotoBrowserZoomAnimator`，不带`Smooth`。

其实最理想最万能的方案是使用一张图片（视图），让这张图片前期和缩略图重合，随着转场过程逐渐变化，向着大图的形态拟合，结束时和大图重合。遗憾的是我暂时没有高效的实现方案，若有朋友能指点一二，万分感谢~

### 网图加载

框架不再集成网络图片加载功能，而是让用户自由决定使用适合于自己项目的图片加载方案，比如`SDWebImage`和`Kingfisher`，例子工程皆有基本的使用示范。

```swift
// 用SDWebImage加载
browserCell?.imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [], completed: { (_, _, _, _) in
    browserCell?.setNeedsLayout()
})

// 用Kingfisher加载
browserCell?.imageView.kf.setImage(with: url, placeholder: placeholder, options: [], completionHandler: { _ in
    browserCell?.setNeedsLayout()
})
```

### 图片加载进度指示器

框架出于业务无关的考虑，对容易受因场景而变更的UI控件都不再集成，但会把示例实现放在例子工程中。

图片加载进度指示器就是这种UI，用户若有需要可自行下载[JXPhotoBrowserProgressView](Example/Example/JXPhotoBrowserProgressView.swift)。

要给项视图(Cell)添加UI，最好是自定义自己的Cell。例子工程示范了如何通过自定义Cell，添加一个图片加载指示器。

```swift
class LoadingImageCell: JXPhotoBrowserImageCell {

    let progressView = JXPhotoBrowserProgressView()
    
    override func setup() {
        super.setup()
        addSubview(progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    func reloadData(placeholder: UIImage?, urlString: String?) {
        progressView.progress = 0
        let url = urlString.flatMap { URL(string: $0) }
        imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [], progress: { [weak self] (received, total, _) in
            if total > 0 {
                self?.progressView.progress = CGFloat(received) / CGFloat(total)
            }
        }) { [weak self] (_, error, _, _) in
            self?.progressView.progress = error == nil ? 1.0 : 0
            self?.setNeedsLayout()
        }
    }
}

```

### 查看原图按钮

查看原图按钮也像图片加载指示器一样是附加UI，框架本身不集成，但是例子工程有实现，用户可结合自己项目修改使用。难点在于控制按钮的隐藏和显现，以及加载使用原图缓存的问题。
详情参考[RawImageViewController](Example/Example/RawImageViewController.swift)

### 页码指示器

考虑到页码指示器的样式基本变化不大，所以框架选择把它们的实现集成进来。
只要是遵循了`JXPhotoBrowserPageIndicator`协议的类都可以成为PhotoBrowser的页面指示器，把实现类的对象赋值给`pageIndicator`属性即可。

```
open var pageIndicator: JXPhotoBrowserPageIndicator?
```

框架提供了两种页面指示器的实现，当然用户觉得都不满足需求，也可以自己编写，只需要遵循`JXPhotoBrowserPageIndicator`协议即可。
两种默认实现分别是`JXPhotoBrowserDefaultPageIndicator`和`JXPhotoBrowserNumberPageIndicator`。

```swift
// UIPageIndicator样式的页码指示器
browser.pageIndicator = JXPhotoBrowserDefaultPageIndicator()
// 数字样式的页码指示器
browser.pageIndicator = JXPhotoBrowserNumberPageIndicator()
```

### GIF/WebP图片格式

由于框架把图片加载的权力完全交给了用户，所以加载各种各样图片格式的方案都由用户去选择。各大图片框架皆有特殊图片格式加载的实现，或是自身有实现，或是第三方的实现，用户都可以找到解决方案。

### 变更数据源

框架支持数据源动态变化，可增加删除数据，然后刷新图片浏览器，就像`UITableView`一样。

```swift
browser.reloadData()
```

变更数据源的关键在于用户控制好自己的数据一致性，包括要同步缩略图控制器的刷新。

详情查看例子工程的[DataSourceDeleteViewController](Example/Example/DataSourceDeleteViewController.swift)和[DataSourceAppendViewController](Example/Example/DataSourceAppendViewController.swift)

### 跨Section浏览图片

曾经有同学问我这种场景下怎么做，所以我特地举例示范。

这里的意思是指像微信朋友圈（相册）那样，缩略图所在是UICollectionView，有许多个Section，每个Section里有许多图片，当打开图片浏览器的时候需要把所有Section的图片全部一起浏览。

其实这个与PhotoBrowser本身能力无关，PhotoBrowser都是支持的，难点在于用户自己对数据源的处理，要处理好图片浏览器里图片的索引号与数据源里数据的IndexPath的映射关系。

详情可查看[MultipleSectionViewController](Example/Example/MultipleSectionViewController.swift)

### 竖向浏览

框架除了支持像微信图片那样的横向浏览外，还支持像抖音视频那样的竖向浏览。仅设置一个属性即可改变方向，它的默认值是水平横向。

```swift
open var scrollDirection: JXPhotoBrowser.ScrollDirection = .horizontal
```

### 视频浏览

无论是图片浏览还是视频浏览，于PhotoBrowser来说都是等同的，PhotoBrowser并不知道它的项视图(Cell)承载了什么内容。用户可通过自定义带有播放视频功能的Cell的来达到视频浏览的目的。

框架提供了项视图的生命周期方法，可帮助用户更好地控制视频的播放与停止。

```swift
open lazy var cellWillAppear: (JXPhotoBrowserCell, Int) -> Void = { _, _ in }

open lazy var cellWillDisappear: (JXPhotoBrowserCell, Int) -> Void = { _, _ in }

open lazy var cellDidAppear: (JXPhotoBrowserCell, Int) -> Void = { _, _ in }
```

例子工程有简单的本地视频播放实现，详情可参考[VideoPhotoViewController](Example/Example/VideoPhotoViewController.swift)

### 图片与视频混合浏览

框架允许多个不同的Cell同时存在，允许给每一个项配置不同的类。

任何遵循了`JXPhotoBrowserCell`协议的类都可以作为PhotoBrowser的项视图。协议仅有一个方法需要实现，就是要求提供生产实例的类方法，框架将会在适当时机通过此方法实例化Cell。

```swift
public protocol JXPhotoBrowserCell: UIView {
    static func generate(with browser: JXPhotoBrowser) -> Self
}
```

对于自定义Cell，遵循了`JXPhotoBrowserCell`协议后，通过以下方法告诉PhotoBrowser每个`index`对应使用的类。

```swift
browser.cellClassAtIndex = { index in
	// 视频与图片交替展示
	index % 2 == 0 ? VideoCell.self : JXPhotoBrowserImageCell.self
}
```

框架内部实现了对`JXPhotoBrowserCell`的复用，即便是同时存在多个自定义Cell类，也只会最小量地生成实例。

视频与图片混合的例子[VideoPhotoViewController](Example/Example/VideoPhotoViewController.swift)

某些业务场景需要在最后一页浏览结束后，展示"更多推荐"视图，也是可以的，查看例子[MultipleCellViewController](Example/Example/MultipleCellViewController.swift)

### 打开方式

框架支持`present`和`push`。通过PhotoBrowser的`show(method:)`方法打开时，可以传入框架定义的枚举类型。

```
/// 通过本回调，把图片浏览器嵌套在导航控制器里
public typealias PresentEmbedClosure = (JXPhotoBrowser) -> UINavigationController
    
/// 打开方式类型
public enum ShowMethod {
    case push(inNC: UINavigationController?)
    case present(fromVC: UIViewController?, embed: PresentEmbedClosure?)
}

```

#### push
考虑到实际应用场景中，图片浏览器可能需要被嵌入在一个导航控制器里，而且要求使用已有的导航控制器，此时`.push`枚举能满足这中需求。

```swift
// 获取当前导航控制器
let nav = topVC.navigationController 
browser.show(method: .push(inNC: nav))
```

inNC 可以传`nil`，此时框架将会尝试自己获取当前顶层的导航控制器，方便用户。

```swift
browser.show(method: .push(inNC: nil))
```

#### present
如果没有嵌入当前导航控制器里的需要，那么可以使用`present`。

`fromVC`是`present`的发起者，允许传`nil`值，此时框架将会尝试自己获取当前顶层控制器。
`embed`允许传入一个新建的导航控制器，也允许`nil`值，空值时PhotoBrowser将不会嵌入任何导航控制器里。

`show(method:)`的默认传参是参数皆为`nil`的`present`枚举。


## 历史版本

2.0版本请参考：[Version2.x](Version2.x.md)

1.0版本请参考：[Version1.x](Version1.x.md)

初稿文章：[ARTICLE](ARTICLE.md)

## 感谢

若使用过程中有任何问题，请issues我。感谢支持 ^_^
