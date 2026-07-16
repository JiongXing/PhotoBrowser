# JXPhotoBrowser 技术方案实现文档

## 1. 文档目标

本文档说明 JXPhotoBrowser 当前版本的技术设计，重点覆盖以下内容：

- 本框架的复用边界和职责划分；
- 交互能力在代码层的实现方式；
- 同一套内核覆盖全屏浏览、Banner、图片/视频混排、SwiftUI 桥接等场景的原因；
- 后续演进时可以继续沿用的设计基础。

在当前版本中，JXPhotoBrowser 将图片浏览能力收敛为一个轻量内核，并通过协议将数据、媒体加载、附加 UI、宿主界面和转场来源外置。这一设计降低了框架对业务代码的侵入程度，使其既可用于独立全屏图片浏览，也可用于页面内嵌的 Banner 或媒体浏览容器。

---

## 2. 方案总览

### 2.1 设计定位

JXPhotoBrowser 可以理解为一个浏览器内核。内核主要负责 4 件事：

1. 用 `UICollectionView` 管理分页与复用；
2. 用 `UIScrollView` 管理单页缩放与居中；
3. 用独立动画器管理展示和消失转场；
4. 用协议把 Cell、Overlay、缩略图来源和媒体内容交给业务层实现。

这套结构可以覆盖以下场景：

- 相册预览、社交 feed 大图查看；
- 商品详情 Banner、营销头图轮播；
- 图片/视频混排浏览；
- UIKit 工程直接接入；
- SwiftUI 工程通过桥接层调用；
- 需要自定义转场来源、定制 Cell、接第三方加载器的业务项目。

### 2.2 架构分层

```text
宿主页面 / 业务数据
        |
        v
JXPhotoBrowserDelegate
        |
        v
JXPhotoBrowserViewController
  |          |            |
  |          |            +-- Overlay 插件体系
  |          +-- 转场动画器（Zoom/Fade/None）
  +-- UICollectionView 分页与复用
              |
              +-- JXPhotoBrowserCellProtocol
                      |
                      +-- JXZoomImageCell
                      +-- JXImageCell
                      +-- 自定义 Cell（如 VideoPlayerCell）
```

这套结构的职责边界如下：

- 浏览器控制器不持有业务模型；
- Cell 不处理数据源组织；
- 动画器不处理图片加载；
- Overlay 不进入浏览器主流程；
- Demo 中的视频播放能力通过自定义 Cell 横向扩展，没有放入浏览器核心。

---

## 3. 核心设计与实现

## 3.1 零数据模型依赖的浏览器内核

JXPhotoBrowser 没有定义媒体模型，也不要求业务使用统一的数据容器。内核通过 `JXPhotoBrowserDelegate` 获取三类能力：

- 数据总数；
- 指定索引的 Cell；
- 生命周期与转场支持。

这种宿主驱动的设计具有以下特征：

- 不绑定图片、视频、本地资源或远程资源的数据结构；
- 不预设加载策略，可兼容 Kingfisher、SDWebImage 或自研加载器；
- 业务方可以自行控制预加载、取消加载、资源释放、视频停止等生命周期动作；
- 对外接口只保留浏览器运行所需的最小集合。

与将模型、下载、展示、指示器、手势集中到单个组件中的实现方式相比，这种内核结构的耦合度更低。

## 3.2 极简 Cell 协议与扩展接缝

`JXPhotoBrowserCellProtocol` 包含两个核心约束：

- `browser`
- `transitionImageView`

另有一个交互回调：

- `photoBrowserDismissInteractionDidChange(isInteracting:)`

这组接口满足浏览器运行所需的最小闭环：

- 浏览器可以回传自身给 Cell，便于 Cell 主动触发关闭等行为；
- 浏览器可以获取参与 Zoom 转场的视图；
- 浏览器在下拉关闭过程中可以通知 Cell 调整子状态。

基于这个协议，当前版本已经形成三类接入路径：

- 图片场景使用 `JXZoomImageCell`；
- 嵌入 Banner 场景使用 `JXImageCell`；
- 图片/视频混排场景通过 `VideoPlayerCell` 继承 `JXZoomImageCell` 进行扩展。

该协议只定义浏览器与 Cell 之间的必要接缝，没有引入额外的业务假设。

## 3.3 基于 UICollectionView 的统一分页引擎

在 4.x 版本中，JXPhotoBrowser 回归 `UICollectionView`。当前版本依赖 `UICollectionView` 提供以下基础能力：

- Cell 复用；
- 水平和垂直滚动的统一建模；
- 与 `UICollectionViewFlowLayout` 配合提供统一的整页 Cell 尺寸；
- 嵌入式场景与全屏场景共用同一套渲染引擎；
- 无限循环和自动轮播建立在统一的滚动容器之上。

这里有两个关键实现机制。

### 机制 A：虚拟数据源实现无限循环

JXPhotoBrowser 采用“真实索引 + 虚拟索引”双层映射，而不在滚动到边界时直接重置索引：

- `realCount` 表示真实数据数量；
- `virtualCount = realCount * loopMultiplier`；
- 对外展示页码时使用 `realIndex(fromVirtual:)` 回映射。

这种实现的直接结果包括：

- 用户滚动方向保持连续；
- 自动轮播只需要继续向后滚动一个虚拟索引；
- 对宿主业务暴露的仍然是真实索引。

该策略通过虚拟数据源换取滚动连续性，适用于图片浏览和 Banner 等连续分页场景。

### 机制 B：通过扩展 collectionView 尺寸处理分页间距

浏览器支持 `itemSpacing`，而原生 `isPagingEnabled` 的分页单位是 scroll view 的 bounds。当前版本的处理方式如下：

- 水平滚动时扩大 `collectionView.frame.width += itemSpacing`；
- 垂直滚动时扩大 `collectionView.frame.height += itemSpacing`；
- 通过 `contentInset` 给最后一个 item 补齐缺失间距。

处理后的分页单位等于“浏览器整页尺寸 + 间距”。4.1 删除逐项自定义尺寸，使分页、页码计算和循环重定位共享同一几何模型，因此可以同时满足以下条件：

- 保持原生分页行为；
- 支持自定义间距；
- 不需要额外实现自定义分页逻辑。

## 3.4 单页缩放交互的状态与布局

`JXZoomImageCell` 基于 `UIScrollView + UIImageView` 实现单页缩放，内部还处理了布局和状态切换。

### 机制 A：初始态采用长边铺满逻辑

初始布局根据图片和容器的宽高比计算缩放比例，默认使用接近 `AspectFit` 的逻辑，使图片完整进入视野，并作为后续双击切换的基准状态。

### 机制 B：双击切换两种阅读模式

双击行为定义为：

- 初始状态下，在“长边铺满”和“短边铺满”之间切换；
- 非初始缩放状态下，回到初始状态。

这套定义将双击行为建模为状态切换，固定倍率缩放不作为默认语义。

### 机制 C：双击放大以点击点为锚

4.0.2 的双击优化将点击位置纳入偏移量计算。实现过程包括：

1. 记录点击在 `scrollView` 和缩放内容容器中的位置；
2. 切换缩放模式并计算新的基础内容尺寸；
3. 基于点击点在旧图和新图中的比例换算出新内容坐标；
4. 计算目标 `contentOffset` 并做边界钳制；
5. 在动画过程中同步缩放容器尺寸、`contentSize` 和 offset。

该处理使放大后的内容位置与用户点击位置保持一致的几何关系。

### 机制 D：通过缩放内容容器做静态居中

当前版本在 `UIScrollView` 内增加了专用的缩放内容容器，由 scroll view 负责缩放几何，Cell 只在静态布局阶段计算基础内容尺寸，并通过更新缩放内容容器的 frame/origin 实现居中。这样可以避免在 active pinch 期间频繁修改 `contentInset/contentOffset`，减少缩放过程中的位置抖动和异常偏移。

## 3.5 下拉关闭交互的实现方式

浏览器控制器在全局层面处理下拉关闭，变换对象是当前 Cell 的 `transitionImageView`，同时同步调整背景透明度。

下拉手势可通过 `isDismissGestureEnabled` 显式关闭。内嵌 Banner 默认关闭该能力；手势开始前还会验证转场视图和坐标容器，所有取消路径统一恢复滚动、裁剪和 Cell 状态。

核心过程如下：

- 开始交互时锁定当前可见 Cell；
- 禁用 collectionView 与内部 scrollView 的滚动，避免手势冲突；
- 记录初始触点与图片中心点；
- 根据位移计算缩放比例；
- 根据“触点相对图片中心的向量”计算补偿位移；
- 使用背景 alpha 表示退出进度。

其中，补偿位移用于处理图片缩小时几何中心变化带来的触点偏移问题。这样可以让缩小过程和手指位置保持稳定的相对关系。

当前版本还包括以下手势边界控制：

- 垂直滚动模式下禁用下拉关闭；
- 只有向下且竖直分量更大的手势才允许开始；
- 下拉关闭仅在图片处于最小缩放状态时触发，放大后的纵向手势优先交给内部 scroll view 处理；
- 下拉交互期间临时关闭外层容器裁剪，避免最小缩放状态下图片被宿主容器截断。

## 3.6 独立动画器与转场降级

JXPhotoBrowser 将转场拆分为以下独立动画器：

- `JXZoomPresentAnimator`
- `JXZoomDismissAnimator`
- `JXFadeAnimator`
- `JXNoneAnimator`

对应关系由浏览器控制器通过 `UIViewControllerTransitioningDelegate` 进行路由。该结构的结果是：

- 每种动画的职责单一；
- 浏览器控制器不承载具体动画细节；
- 后续扩展新的动画类型时接入点明确。

Zoom 动画包含两个关键机制。

### 机制 A：条件不满足时降级为 Fade

Zoom 转场依赖两个前提：

- 源缩略图视图存在；
- 目标大图视图或其几何信息可用。

任一条件不满足时，当前版本回退到 Fade。这样可以避免在缩略图或目标视图缺失时进入不完整的 Zoom 动画。

### 机制 B：转场临时视图自动生成

动画器内部自动构造临时 `zoomView`：

- 源视图是 `UIImageView` 时，直接取其 image；
- 源视图不是 `UIImageView` 时，对源视图做快照渲染。

因此，业务层不需要额外提供 snapshot 逻辑。

## 3.7 Overlay 机制

附加 UI 通过 `JXPhotoBrowserOverlay` 协议接入。协议包含三个方法：

- `setup(with:)`
- `reloadData(numberOfItems:pageIndex:)`
- `didChangedPageIndex(_:)`

浏览器主控制器的职责是：

- 装载 Overlay；
- 在布局变化时通知刷新；
- 在页码变化时广播状态。

其余展示逻辑由 Overlay 自行维护。基于当前结构可以得到以下结果：

- 默认不装载任何附加视图；
- 页码指示器只是一个插件示例；
- 标题栏、关闭按钮、操作菜单、下载按钮等组件都可以沿用同一接入方式。

## 3.8 同一内核覆盖全屏浏览器与 Banner 场景

`PhotoBannerView` 直接复用 `JXPhotoBrowserViewController` 作为嵌入式滚动引擎，配置方式包括：

- 设置 `transitionType = .none`；
- 注册 `JXImageCell`；
- 开启循环和自动轮播；
- 装载页码 Overlay；
- 将浏览器 view 作为普通子视图嵌入。

由此可以看出，浏览器内核不依赖全屏场景假设。相同内核可以用于：

- 头图 Banner；
- 商品详情轮播；
- 营销活动卡片翻页区；
- 局部媒体浏览容器。

## 3.9 自定义视频 Cell 的扩展方式

Demo 中的 `VideoPlayerCell` 通过继承 `JXZoomImageCell` 扩展出视频浏览能力，包含以下内容：

- AVPlayer 播放；
- 加载状态指示；
- 双击缩放时同步更新 `AVPlayerLayer`；
- 下拉关闭时隐藏 loading；
- 前后台切换时恢复播放器图层；
- 长按保存视频到相册。

该实现说明浏览器核心与媒体内容之间已经形成明确分层：

- 浏览器负责翻页、转场和手势边界；
- 自定义 Cell 负责媒体播放生命周期；
- Delegate 决定每个索引对应图片还是视频。

这一扩展方式也适用于继续接入其他媒体类型。

## 3.10 SwiftUI 桥接方式

JXPhotoBrowser 的核心实现基于 UIKit。当前版本通过 `PhotoBrowserPresenter` 作为桥接层：

- SwiftUI 页面负责网格、设置面板和状态管理；
- Presenter 持有数据并实现 `JXPhotoBrowserDelegate`；
- 通过查找当前顶层 `UIViewController` 调用 `present(from:)`。

这类桥接方案的特点是：

- 继续复用 UIKit 浏览器能力；
- 不需要在 SwiftUI 中重新实现转场和手势；
- SwiftUI 页面保持自身的状态和视图组织方式；
- 浏览器适配逻辑集中在 Presenter 中。

---

## 4. 关键实现机制拆解

## 4.1 页面展示链路

```text
宿主页面点击缩略图
    ->
创建 JXPhotoBrowserViewController
    ->
设置 delegate / initialIndex / scrollDirection / transitionType
    ->
present(from:)
    ->
转场动画器介入
    ->
浏览器布局 collectionView
    ->
滚动到初始虚拟索引
    ->
delegate 提供 Cell
    ->
willDisplay 中由业务填充媒体内容
```

该链路的几个要点如下：

- 控制器创建阶段只做配置；
- 媒体加载发生在 `willDisplay`；
- 浏览器本身不区分媒体是同步、本地、网络还是视频；
- Zoom 转场所需的缩略图来源由宿主提供。

## 4.2 页码与缩略图状态同步

浏览器使用 `pageIndex` 作为统一状态源，并在 `didSet` 中完成两类同步：

- 切换 Zoom 转场对应缩略图的显隐；
- 通知所有 Overlay 更新状态。

这种做法将主内容状态和附加 UI 状态收敛到同一个索引源上，有助于减少页码、缩略图和转场状态之间的偏差。

## 4.3 当前可见 Cell 的判定方式

JXPhotoBrowser 提供的 `visibleCell()` 通过计算所有可见 Cell 到屏幕中心点的距离，选取最接近视觉中心的那个，没有直接使用 `indexPathsForVisibleItems.first`。该处理适用于以下情况：

- 滚动动画尚未结束；
- 有 itemSpacing；
- 分页过程中同时可见多个 Cell；
- 嵌入式浏览场景需要稳定获取当前主 Cell。

## 4.4 自动轮播的暂停与恢复

Banner 场景中，自动轮播与用户手势之间需要明确边界。当前策略如下：

- 用户开始拖动时暂停；
- 减速结束或拖动结束后恢复；
- 非循环模式到最后一页时停止。

这组规则对应 `scrollViewWillBeginDragging`、`scrollViewDidEndDecelerating`、`scrollViewDidEndDragging` 和 `scrollViewDidEndScrollingAnimation` 等时机。

---

## 5. 工程化考量

## 5.1 依赖与分发边界

框架核心只依赖 `UIKit`，没有第三方依赖。当前分发方式覆盖：

- CocoaPods；
- SwiftPM；
- Carthage。

这种分发边界可以降低框架与宿主项目之间的依赖冲突。

## 5.2 隐私清单

当前版本已经包含 `PrivacyInfo.xcprivacy`，并在 SwiftPM、CocoaPods 与主 framework target 中显式携带，确保 Carthage XCFramework 也包含该发布资产。

## 5.3 Demo 的工程角色

三个 Demo 的分工如下：

- `Demo-UIKit`：展示主能力、图片/视频混排、列表转场；
- `Demo-SwiftUI`：展示桥接方式；
- `Demo-Carthage`：展示分发兼容性。

其中，`Demo-UIKit` 中的 `VideoPlayerCell` 和 `PhotoBannerView` 同时承担扩展示例的作用。

---

## 6. 适用场景与复用建议

## 6.1 适用场景

当前设计可用于以下业务：

- 社交、内容社区的图片/视频浏览；
- 电商详情页 Banner；
- 相册、图库、素材管理类应用；
- 需要从缩略图过渡到大图的媒体浏览场景；
- UIKit 为主且局部使用 SwiftUI 的项目。

## 6.2 推荐复用方式

如果将 JXPhotoBrowser 作为业务组件接入，建议按以下方式使用：

1. 图片浏览优先复用 `JXZoomImageCell`；
2. 纯展示轮播优先复用 `JXImageCell`；
3. 视频或其他媒体能力通过自定义 Cell 横向扩展；
4. 页码、按钮、文案通过 Overlay 装载；
5. 图片加载、缓存、取消任务放在业务侧的 `willDisplay` / `didEndDisplaying` 中管理；
6. SwiftUI 工程通过 Presenter 或桥接层封装调用入口。

这种方式有助于保持内核边界稳定。

---

## 7. 可演进方向

当前版本已经具备继续演进的基础，后续可以优先考虑以下方向。

## 7.1 将下拉关闭升级为交互式转场

当前下拉关闭属于“手势驱动视图变换 + 最终 dismiss”。如果后续引入 `UIPercentDrivenInteractiveTransition`，可以进一步统一：

- 手势进度；
- 转场取消；
- 背景与目标页面联动。

## 7.2 补充 Overlay 官方示例

Overlay 机制已经具备稳定接缝，后续可以增加官方内置示例：

- 关闭按钮；
- 标题/描述 Overlay；
- 下载/分享操作条；
- 顶部工具栏。

## 7.3 增加资源预取与取消加载建议接口

当前业务可以通过生命周期自行处理加载。若后续需要进一步优化大图浏览过程中的资源切换，可以考虑增加“即将出现索引”的预取辅助接口。

## 7.4 视情况开放旋转支持

当前版本固定竖屏。如果后续覆盖相册、设计稿预览或平板场景，可以评估引入可选旋转支持，同时保持默认行为不变。

---

## 8. 结论

JXPhotoBrowser 当前版本具有以下特征：

1. 浏览器能力被收敛为低耦合、可扩展的内核；
2. 缩放、下拉关闭、Zoom 转场、循环滚动等交互能力在内核中统一实现；
3. 同一套内核可以复用到 Banner、视频混排和 SwiftUI 桥接场景。

从框架设计角度看，JXPhotoBrowser 的关键点在于边界划分：

- 内核只处理浏览器通用能力；
- 扩展能力通过协议接缝暴露；
- 业务复杂性留在业务层；
- 交互细节在组件内部统一处理。

---

## 9. 附录：关键源码定位

为了方便后续维护和二次开发，建议优先从以下文件进入源码：

- `Sources/JXPhotoBrowserViewController.swift`
  浏览器内核，负责分页、循环、Overlay 管理、自动轮播、下拉关闭、转场路由。
- `Sources/JXZoomImageCell.swift`
  可缩放图片 Cell，负责图片布局、双击缩放、居中策略。
- `Sources/JXImageCell.swift`
  轻量图片 Cell，适合 Banner 等嵌入式展示。
- `Sources/JXPhotoBrowserDelegate.swift`
  浏览器对业务层暴露的数据和生命周期接缝。
- `Sources/JXPhotoBrowserCellProtocol.swift`
  自定义 Cell 接入浏览器的最小协议约束。
- `Sources/JXPhotoBrowserOverlay.swift`
  Overlay 插件协议定义。
- `Sources/JXPageIndicatorOverlay.swift`
  官方内置 Overlay 示例，可作为其他附加组件模板。
- `Sources/JXZoomPresentAnimator.swift`
  Zoom 展示转场实现与 Fade 降级逻辑。
- `Sources/JXZoomDismissAnimator.swift`
  Zoom 消失转场实现。
- `Sources/JXFadeAnimator.swift`
  Fade 转场实现。
- `Demo-UIKit/Demo/HomePage/VideoPlayerCell.swift`
  图片 Cell 横向扩展为视频播放 Cell 的完整示例。
- `Demo-UIKit/Demo/HomePage/PhotoBannerView.swift`
  复用浏览器内核实现 Banner 的示例。
- `Demo-SwiftUI/Demo/PhotoBrowserPresenter.swift`
  SwiftUI 桥接入口示例。
