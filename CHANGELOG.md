# Change Log

## Version 4.1.0

> 2026/07/10

- 修复循环模式程序化跳页未选择最近虚拟项的问题
- 新增 `reloadData(preservingCurrentPage:)`，统一处理动态数据、页码钳制、循环重定位、Overlay 与自动轮播
- 删除 `JXPhotoBrowserDelegate.photoBrowser(_:sizeForItemAt:)`，Cell 统一使用浏览器整页尺寸
- 新增 `isDismissGestureEnabled`；下拉关闭统一校验与清理交互状态
- 自动轮播仅在浏览器完成定位且可见时启动，间隔下限为 0.5 秒，运行时修改会重新调度
- 修复程序化滚动未产生实际动画时，自动轮播状态无法恢复的问题
- 修复页码 Overlay 从单页隐藏状态无法恢复的问题，并阻止重复装载同一 Overlay
- 完善转场取消路径，恢复真实视图与缩略图状态
- UIKit Banner 改用标准 View Controller containment；SwiftUI Demo 改为引用仓库本地 Package
- SwiftUI Banner 仅在图片数据变化时刷新，避免无关视图更新触发重复加载
- CocoaPods、SwiftPM、Carthage 统一携带隐私清单，发布版本统一为 4.1.0
- README 精简并拆分详细指南，新增 4.0 到 4.1 迁移文档

- `JXZoomImageCell` 新增 `doubleTapZoomScale`：可指定双击放大的固定倍数（相对适配尺寸，以点击点为中心）；为 `nil` 时保持原有的「长边铺满 ↔ 短边铺满」模式切换行为
- 双击放大倍数受 `scrollView.maximumZoomScale`（默认 `3.0`）上限约束，与捏合缩放天花板解耦；如需更大倍数请自行调高 `maximumZoomScale`
- `JXPhotoBrowserViewController` 新增 `scrollToPage(at:animated:)`：支持代码直接跳转到指定页，兼容无限循环模式，`animated: false` 可连续快速调用
- 修复无限循环模式下连续单向滑动耗尽虚拟数据源导致循环终止、自动轮播永久停止的问题（滚动结束后自动回中）
- 修复 Zoom 转场降级为淡出关闭时，列表缩略图未恢复显示、永久隐藏的问题
- 修复运行时切换 `scrollDirection` 后丢失当前页、跳回第 0 页的问题
- 修复下拉关闭时图片跟手补偿的坐标系错位，信箱式居中图片下拉不再漂移
- 优化下拉关闭判定：下拉超过 1/4 屏高或松手速度足够快即关闭，手势被取消时不再误触发关闭
- 修复 Banner 嵌入外层滚动列表时，列表滚动期间自动轮播卡住的问题（Timer 挂载至 `.common` mode）
- 修复 `JXZoomImageCell` 从 XIB/Storyboard 实例化时未执行初始化的问题
- 修复业务方传入越界 `initialIndex` 时，Zoom 转场可能引发 delegate 侧数组越界的问题
- **行为变化**：`setThumbnailHidden` 的默认实现由空操作改为自动切换 `thumbnailViewAt` 返回视图的 `isHidden`。未实现该方法的宿主现在开箱即用：浏览期间当前页缩略图保持隐藏（与系统相册一致）。Zoom 转场动画器不再直接操作缩略图视图，显隐统一经由 delegate 通道

---

## Version 4.0.3

> 2026/03/27

- 修复 `JXZoomImageCell` 首次展示时图片可能出现在左上角、未能居中的问题
- 重写 `JXZoomImageCell` 的基础布局与居中逻辑，改为由专用缩放容器承载缩放内容
- 优化下拉关闭交互：仅在最小缩放状态下触发，避免放大后下拉引起的位移异常
- 修复最小缩放状态下下拉关闭时图片被外层容器裁剪的问题

---

## Version 4.0.2

> 2026/02/16

- 优化双击放大体验：以点击位置为锚点放大，而非固定从左上角开始
- 优化双击缩小动画：从当前滚动位置平滑过渡回居中状态，消除闪跳

---

## Version 4.0.1

> 2026/02/10

**全面重构，不兼容 3.x 版本。**

### 核心设计变更

- **回归 `UICollectionView`**：3.x 弃用的 `UICollectionView` 重新回归，利用系统 Cell 复用机制，支持无限循环滚动。
- **Delegate 驱动**：以 `JXPhotoBrowserDelegate` 取代 3.x 的多种 DataSource，框架不定义任何数据模型，不内置图片加载逻辑，业务方拥有完全的数据和加载自主权。
- **极简 Cell 协议**：`JXPhotoBrowserCellProtocol` 仅 2 个属性（`browser` + `transitionImageView`），内置 `JXZoomImageCell`（可缩放）和 `JXImageCell`（轻量级），也支持完全自定义。
- **Overlay 按需装载**：`JXPhotoBrowserOverlay` 协议统一接入附加 UI 组件，默认零装载、零开销，内置 `JXPageIndicatorOverlay` 页码指示器。
- **独立转场动画器**：Fade / Zoom / None 三种转场动画各自独立实现 `UIViewControllerAnimatedTransitioning`，Zoom 不满足前置条件时自动降级为 Fade。

---

### Version 3.1.6

> 2025/10/23

- 修复已知问题：#228, #232

### Version 3.1.5

> 2024/02/05

- 优化和修复已知问题，包括#213 #216 #217 #221 #224 #225

### Version 3.1.4

> 2023/10/15

- 更新 Deprecated 方法，消除 Warnings
- 变更 JXPhotoBrowserZoomSupportedCell 权限修饰符为 public

### Version 3.1.3

> 2021/02/20

- 优化JXPhotoBrowserImageCell，监听imageView的image赋值，自动layout

### Version 3.1.2

> 2020/05/30

- 优化JXPhotoBrowserImageCell，暴露方法支持子类自定义创建视图

### Version 3.1.1

> 2020/05/08

- 修复嵌入导航栏场景下的转场动画Bug.

### Version 3.1.0

> 2020/05/06

- 更好支持嵌入导航栏场景下的转场动画
- 修复转场过程中可能出现的崩溃

### Version 3.0.9

> 2020/02/20

- 修复：非嵌入导航栏的Fade动画Dismiss问题

### Version 3.0.8

> 2020/02/09

- 修复：嵌入导航控制器后的Fade动画显示问题
- 优化：deinit时还原导航控制器的delegate

### Version 3.0.7

> 2020/02/04

- 修复屏幕旋转后的滑动问题

### Version 3.0.6

> 2020/01/13

- 适配Swift低版本的语法

### Version 3.0.5

> 2019/12/18

- 补充完善已有功能

### Version 3.0.0

> 2019/12/06

- 设计重构整个项目，精简了过于复杂的设计，去除所有第三方依赖，弃用UICollectionView改为更轻量自由的实现
- 框架接口更合理，扩展更容易，用户定制潜力更大，各种业务场景的适应性更强

## Version 2.1.6 (iOS9 +) & Version 2.2.6 (iOS 10 +)

** 2019/11/10 **

- 修复图片加载失败可能引发崩溃的问题

## Version 2.2.5/2.1.5

**2019/10/11**

> v2.1.5支持到iOS9，使用Kingfisher 4.x版本。v2.2.5因为使用了 Kingfisher 5.x，最低只能支持到iOS10。

> Kingfisher 5.x 的图片缓存与先前版本不太一样，可能在这里有问题。

> 未来版本增加SDWebImage支持示例，对网络图片的加载会进一步解耦，甚至加载视频。

- 现在`imageMaximumZoomScale`属性已启用。
- 数字页码添加半透背景，解决预览白图时数字消失问题。
- 现在自动支持`Swift 5`编译。

## Version 2.2.3

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
## Version 2.1.2
**2018/12/07**

- 修复显示长图时可能发生的交互BUG

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

## Version 1.4.0
**2018/07/15**
- 现在可以自由选用Cell插件
- 支持嵌入导航栏
- 支持谷歌`WebP`格式
- Cell 插件协议增加 CellWillDisplay 和 CellDidEndDisplaying 回调
- 图片下拉手势现在改为加在`cell.contentView`上
- 增加`scrollToItem()`方法，可随时控制滑动到哪张图片

## Version 1.3.3
**2018/07/02**
- 让查看原图按钮插件暴露一些常用属性，增加背景色，提高在白图上的辨识度。
- 现在可以通过PhotoBrowser类主动调用加载原图方法。

## Version 1.3.2
**2018/06/17**
- 修复`locationInView`返回`nan`导致 crash 的问题。

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

## Version 1.1.2
**2018/5/24**
- 修复`.fade模式`下的`originPageIndex`无效问题

## Version 1.1.1
**2018/5/23**
- 修正`DefaultPageControlPlugin`和`NumberPageControlPlugin`在`iPhoneX`上的偏移

## Version 1.1.0 
**2018/5/22**
- 重构本地图片浏览方法
    - 由原来的通过协议方式取本地图片，改为直接在打开图片浏览时传入图片组：
    ```swift
    PhotoBrowser.show(localImages: localImages, originPageIndex: index)
    ```
    - 删除`PhotoBrowserDelegate.photoBrowser(_:, localImageForIndex:)`
    - 新增`PhotoBrowser.localImages`属性，接收传入的图片组
    - 新增`PhotoBrowser.show(localImages:)`类方法，一行代码打开图片浏览器
- 新增`PhotoBrowser.deleteItem(at index: Int)`，支持删除动画
- 优化`PhotoBrowser.reloadData`，更好支持数据源删减操作
- 优化`PhotoBrowser.viewWillTransition`，处理屏幕旋转
- 优化`PhotoBrowser.viewDidLayoutSubviews`
- 优化`PhotoBrowser.dismiss`，修复状态栏显示问题
- `PhotoBrowser.photoLoader`属性不再是可选，必须给值
- 为了更准确表达方法含义，重命名以下协议方法（请原谅我再一次改方法名 >o<）：
    - `PhotoBrowserPlugin`协议：`photoBrowser(_:, scrollView:)`重命名为`photoBrowser(_:, scrollViewDidScroll:)`
    - `PhotoPhotoBrowserDelegate`协议：`photoBrowser(_:, originViewForIndex:)`重命名为`photoBrowser(_:, thumbnailViewForIndex:)`
    - `PhotoPhotoBrowserDelegate`协议：`photoBrowser(_:, originImageForIndex:)`重命名为`photoBrowser(_:, thumbnailImageForIndex:)`

## Version 1.0.0 
**2018/5/17**
- 稳定主要API，完成大部分功能的设计与实现

## Version 0.0.1
**2017/4/13**
- 完成初版实现
