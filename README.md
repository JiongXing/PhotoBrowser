# JXPhotoBrowser
![](https://img.shields.io/badge/platform-ios-lightgrey.svg)
![](https://img.shields.io/badge/swift-3.0-green.svg)
![](https://img.shields.io/badge/pod-v0.2.3-green.svg)

#  缘起
那时，我想要一个这样的图片浏览器：
- 从小图进入大图浏览时，使用转场动画
- 可加载网络图片，且过渡自然，不阻塞操作
- 可各种姿势玩弄图片，且过渡自然，不阻塞操作
- 可以在往下拽时，尺寸随位移缩小，背景半透明，要能看见底下的场景
- 反正就是各种效果啦...

![PhotoBrowser.png](http://upload-images.jianshu.io/upload_images/2419179-9cc2a64dba3c237f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/320)

很遗憾，久寻无果，于是我决定自己造一个。

# Requirements
- iOS 8.0+
- Swift 3.0+
- Xcode 8.1+

# 调起方式
由于我们打算使用转场动画，所以在容器的选择上，只能使用UIViewController，那就让我们的类继承它吧：
```swift
public class PhotoBrowser: UIViewController
```
这样的话，有个方法是躲不开的，必须用它调起我们的图片浏览器：
```
open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Swift.Void)? = nil)
```
写一个库，提供给别人用时，我们总希望对外接口设计得越简单明了越好，当然最好能做到傻瓜式操作。
禀承这一原则，我们把`present`方法的调用，以及各种属性赋值都对外隐藏起来，让用户少操心。
所以，提供个方法给用户`show`一下吧：
```swift
public func show() {
    self.transitioningDelegate = self
    self.modalPresentationStyle = .custom
    presentingVC.present(self, animated: true, completion: nil)
}
```
但是，想要在我们的`PhotoBrowser`类内部`present`出自己的实例，需要一个`ViewController`作为动作执行者，它就是上面`show`方法里面的`presentingVC`。
考虑到这位执行者是不会变化的，只需要告诉我们一次，是谁，就可以了，所以这里可以设计成在`init`创建实例时，就进行绑定：
```swift
public init(showByViewController presentingVC: UIViewController) {
    self.presentingVC = presentingVC
}
```

# 传递数据
作为一个图片浏览器，它需要知道哪些关键信息？
- 一共有多少张图片
- 第n张图片它的缩略图，或者说占位图，是什么
- 第n张图片它的大图，或者URL是什么
- 打开图片浏览器时，显示哪一张图片

我们大概有这么些办法，可以让图片浏览器拿到需要展示的图片信息：
- 在调起浏览器之前，向浏览器正向传入它需要的所有数据
- 预先设置回调block，或者代理，在浏览器需要用到某个数据时，回调block或者向代理反向取数据

对于图片浏览器来说，并不需要保存一份从用户传过来的数据，而是希望在用到的时候再取，这里我们就为它设计代理协议吧。
```swift
public protocol PhotoBrowserDelegate {
    /// 实现本方法以返回图片数量
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int
    
    /// 实现本方法以返回默认图片，缩略图或占位图
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage
    
    /// 实现本方法以返回高质量图片。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityImageForIndex index: Int) -> UIImage?
    
    /// 实现本方法以返回高质量图片的url。可选
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlStringForIndex index: Int) -> URL?
}
```
然后在`init`方法绑定代理对象，变成这样：
```swift
public init(showByViewController presentingVC: UIViewController, delegate: PhotoBrowserDelegate) {
    self.presentingVC = presentingVC
    self.photoBrowserDelegate = delegate
    super.init(nibName: nil, bundle: nil)
}
```

但是有一项关键信息例外，它就是"打开图片浏览器时，显示哪一张图片"。
这一项数据与用户的`show`动作关联性更大，从用户的角度来说，适合在show的同时正向传递给图片浏览器。
从图片浏览器来说，它内部也需要维护一个变量，用来记录当前正在显示哪一张图片，所以这一项数据适合让图片浏览器保存下来。
我们把`show`方法改一下，接收一个参数，并保存在属性`currentIndex`中。
```swift
/// 展示，传入图片序号，从0开始
public func show(index: Int) {
    currentIndex = index
    self.transitioningDelegate = self
    self.modalPresentationStyle = .custom
    self.modalPresentationCapturesStatusBarAppearance = true
    presentingVC.present(self, animated: true, completion: nil)
}
```
# 让用户傻瓜式操作！
现在我们调起图片浏览器的姿势是这样的：
```swift
let browser = PhotoBrowser(showByViewController: self, , delegate: self)
browser.show(index: index)
```
还需要写两行代码，不爽，弄成一行：
```swift
/// 便利的展示方法，合并init和show两个步骤
public class func show(byViewController presentingVC: UIViewController, delegate: PhotoBrowserDelegate, index: Int) {
    let browser = PhotoBrowser(showByViewController: presentingVC, delegate: delegate)
    browser.show(index: index)
}
```
现在，我们调起图片浏览器的姿势是这样的：
```swift
PhotoBrowser.show(byViewController: self, delegate: self, index: indexPath.item)
```

# 横向滑动布局
嗯，这是个横向的`TableView`，我们用`UICollectionView`来做吧。
```swift
/// 容器
fileprivate let collectionView: UICollectionView

override public func viewDidLoad() { 
    super.viewDidLoad()
    collectionView.frame = view.bounds
    collectionView.backgroundColor = UIColor.clear
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(PhotoBrowserCell.self, forCellWithReuseIdentifier: NSStringFromClass(PhotoBrowserCell.self))
    view.addSubview(collectionView)
}
```

布局类继承自UICollectionViewFlowLayout，设置为横向滑动：
```swift
/// 容器layout
private let flowLayout: PhotoBrowserLayout

public class PhotoBrowserLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        scrollDirection = .horizontal
    }
}
```

![CollectionView布局.gif](http://upload-images.jianshu.io/upload_images/2419179-56b4c00fbd767b47.gif?imageMogr2/auto-orient/strip)

# 图间空隙与边缘吸附
注意左右两张图片之间是有空隙的，这是个难点。
先让空隙数值可配置：
```swift
public class PhotoBrowser: UIViewController {
    /// 左右两张图之间的间隙
    public var photoSpacing: CGFloat = 30
}
```

现在考虑一个问题：图片是一页一页左右滑的，那么究竟要怎样实现一页？
已经确定不变的，是每张图片的宽度必须占满屏幕，每页的宽度必须是屏宽+间隙
就有这些可能性：
每个CollectionViewCell的宽度是一个屏宽呢？还是屏宽+间隙？间隙是做为cell的一部分嵌进cell里呢？还是作为layout类的属性？

考虑到手指滑动，离开屏幕后，需要让图片对齐边缘，即吸附，很自然就想到使用collectionView.isPagingEnabled = true。
如果使用这个属性，意味着页宽x页数要刚刚好等于collectionView的contentSize.width，只有这样，collectionView.isPagingEnabled才能正常工作。
1. 假如给layout类设置spacing作为图间隙，则collectionView的contentSize.width值为图片数量x屏宽+(图片数量-1)x间隙，并非页宽的整倍数。
2. 假如把空隙嵌入cell里作为cell的一部分，则需要增大cell的宽度，使其超出屏宽，再控制图片视图小于cell宽。这种办法属于技巧性解决问题的办法，非大道也。因为让cell的职责超出了它的本分，尝试去处理它外部的事情，违反解耦，违反面向对象，导致cell内部增加许多本不属于它的奇怪复杂逻辑。

所以希望使用collectionView.isPagingEnabled = true来实现边缘吸附效果的想法，被否决，我们来另寻办法。

首先，让cell单纯地只做展示图片的行为，让cell的size满屏。两cell之间的空隙由layout控制，当然cell的size也由layout控制：
```swift
override public func viewDidLoad() {
    super.viewDidLoad()
    flowLayout.minimumLineSpacing = photoSpacing
    flowLayout.itemSize = view.bounds.size
}
```



UICollectionViewLayout有一个方法覆盖点，通过重写这个方法，可以重新指定scroll停止的位置，它就是：
```swift
public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint
```
苹果对它的说明，就是告诉我们可以用来实现边缘吸附的：
`If you want the scrolling behavior to snap to specific boundaries, you can override this method and use it to change the point at which to stop. `
这个方法接收一个CGPoint，返回一个CGPoint，接收的是若不做任何处理，就在那里停下来的Point，我们要在方法内做的就是返回一个让它在正确位置停下来的Point。

```swift
public class PhotoBrowserLayout: UICollectionViewFlowLayout {
    /// 一页宽度，算上空隙
    private lazy var pageWidth: CGFloat = {
        return self.itemSize.width + self.minimumLineSpacing
    }()
    
    /// 上次页码
    private lazy var lastPage: CGFloat = {
        guard let offsetX = self.collectionView?.contentOffset.x else {
            return 0
        }
        return round(offsetX / self.pageWidth)
    }()
    
    /// 最小页码
    private let minPage: CGFloat = 0
    
    /// 最大页码
    private lazy var maxPage: CGFloat = {
        guard var contentWidth = self.collectionView?.contentSize.width else {
            return 0
        }
        contentWidth += self.minimumLineSpacing
        return contentWidth / self.pageWidth - 1
    }()

    /// 调整scroll停下来的位置
    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        // 页码
        var page = round(proposedContentOffset.x / pageWidth)
        // 处理轻微滑动
        if velocity.x > 0.2 {
            page += 1
        } else if velocity.x < -0.2 {
            page -= 1
        }
        
        // 一次滑动不允许超过一页
        if page > lastPage + 1 {
            page = lastPage + 1
        } else if page < lastPage - 1 {
            page = lastPage - 1
        }
        if page > maxPage {
            page = maxPage
        } else if page < minPage {
            page = minPage
        }
        lastPage = page
        return CGPoint(x: page * pageWidth, y: 0)
    }
}
```
可以看到，在targetContentOffset方法里，为了实现pagingEnabled属性的效果，我们需要处理好几个细节：
- 轻微滑动时，设定一个阈值，达到则翻页
- 一次滑动时不允许超过一页
- 因为有轻微滑动就翻页的设定，故可能在首尾两页出现超过最小最大页码的情况，此时要进行最后的边界检查

另外，若不启用pagingEnabled，在手势滑动离开屏幕后，默认情况下collectionView会继续滑动很久才会停下来，这时我们需要给它设置一个减速速率，让它快速停下来： 
```swift
collectionView.decelerationRate = UIScrollViewDecelerationRateFast
```
结果我们手动实现了一个与打开pagingEnabled属性一模一样的效果。

# 大图浏览
负责展示图片的类，是UICollectionViewCell。
为了方便让图片进行缩放，可以使用UIScrollView的能力zooming，我们把它作为imageView的容器。
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    /// 图像加载视图
    public let imageView = UIImageView()

    /// 内嵌容器。本类不能继承UIScrollView。
    /// 因为实测UIScrollView遵循了UIGestureRecognizerDelegate协议，而本类也需要遵循此协议，
    /// 若继承UIScrollView则会覆盖UIScrollView的协议实现，故只内嵌而不继承。
    fileprivate let scrollView = UIScrollView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        scrollView.addSubview(imageView)
        imageView.clipsToBounds = true
    }
}
```

![大图浏览.gif](http://upload-images.jianshu.io/upload_images/2419179-4dee84cee03d5c4a.gif?imageMogr2/auto-orient/strip)

什么时候进行cell布局？设置图片后就应该进行。
为什么这么迫切要立即刷新呢？其中有一个原因是下面讲到的转场动画所需的，转场动画需要提前取到即将用于展示的cell。至于另外的原因，于情于理，数据确定后，UI跟着刷新也是没毛病的。
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    /// 取图片适屏size
    private var fitSize: CGSize {
        guard let image = imageView.image else {
            return CGSize.zero
        }
        let width = scrollView.bounds.width
        let scale = image.size.height / image.size.width
        return CGSize(width: width, height: scale * width)
    }
    
    /// 取图片适屏frame
    private var fitFrame: CGRect {
        let size = fitSize
        let y = (scrollView.bounds.height - size.height) > 0 ? (scrollView.bounds.height - size.height) * 0.5 : 0
        return CGRect(x: 0, y: y, width: size.width, height: size.height)
    }

    /// 布局
    private func doLayout() {
        scrollView.frame = contentView.bounds
        scrollView.setZoomScale(1.0, animated: false)
        imageView.frame = fitFrame
        progressView.center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
    }
    
    /// 设置图片。image为placeholder图片，url为网络图片
    public func setImage(_ image: UIImage, url: URL?) {
        guard url != nil else {
            imageView.image = image
            doLayout()
            return
        }
        self.progressView.isHidden = false
        weak var weakSelf = self
        imageView.kf.setImage(with: url, placeholder: image, options: nil, progressBlock: { (receivedSize, totalSize) in
            // TODO
        }, completionHandler: { (image, error, cacheType, url) in
            weakSelf?.doLayout()
        })
        self.doLayout()
    }
}
```

**现在我们让图片放大。**
设计支持两种缩放操作：
- 捏合手势
- 双击缩放

**捏合手势：**
CollectionView是UIScorllView的子类，UIScorllView天生支持pinch捏合手势，只需要实现它的代理方法即可：
```swift
extension PhotoBrowserCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = centerOfContentSize
    }
}
```
viewForZooming方法可以告诉ScrollView在发生zooming时，对哪个视图进行缩放；
然后我们需要在scrollViewDidZoom的时候，重新把图片放在中间，这样调整可以让视觉更美观、体验更良好。

**双击缩放：**
有些用户更乐意单手操作手机，而捏合手势需要两根手指，很难一只手完成操作。虽然通过捏合可以控制缩放比率，但有时候用户要的仅仅是“把图片放大一些，看看细节”这样的需求，于是我们可以折衷一下，通过双击手势把图片固定放大到2倍size：
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    override init(frame: CGRect) {
        ...
        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
    }

    func onDoubleTap() {
        var scale = scrollView.maximumZoomScale
        if scrollView.zoomScale == scrollView.maximumZoomScale {
            scale = 1.0
        }
        scrollView.setZoomScale(scale, animated: true)
    }
}
```

# 转场动画
为了呈现合理的打开/关闭图片浏览器效果，我们决定使用转场动画。
这里使用modal转场，并且使用custom方式，方便灵活定制我们想要的效果。
我们想要怎样的效果？
- 打开图片浏览器时，要从小图逐渐放大进入大图浏览模式
- 关闭图片浏览时，要从大图模式逐渐缩小回原来小图的位置

![Transition-Animation.gif](http://upload-images.jianshu.io/upload_images/2419179-17cde04e2da55abc.gif?imageMogr2/auto-orient/strip)

在转场过程中，我们要妥善处理好的细节包括：
- 小图和大图在转场容器里的坐标位置
- 小图和大图的暗中切换
- 背景蒙板

考虑到无论是presention转场还是dismissal转场，都是缩放式动画，所以我们可以只写一个动画类：
```swift
public class ScaleAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// 动画开始位置的视图
    public var startView: UIView?
    
    /// 动画结束位置的视图
    public var endView: UIView?
    
    /// 用于转场时的缩放视图
    public var scaleView: UIView?
    
    /// 初始化
    init(startView: UIView?, endView: UIView?, scaleView: UIView?) {
        self.startView = startView
        self.endView = endView
        self.scaleView = scaleView
    }
}
```
我们设计它只管动画，同时适配presention和dismissal转场，所以不在类中取presentingView和presentedView，而是由外界调用者传进来，保持动画类功能单纯，只做最需要的事情。
```swift
public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    // 判断是presentataion动画还是dismissal动画
    guard let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to) else {
        return
    }
    let presentation = (toVC.presentingViewController == fromVC)
        
    // dismissal转场，需要把presentedView隐藏，只显示scaleView
    if !presentation, let presentedView = transitionContext.view(forKey: .from) {
        presentedView.isHidden = true
    }
        
    // 取转场中介容器
    let containerView = transitionContext.containerView
        
    // 求缩放视图的起始和结束frame
    guard let startView = self.startView,
        let endView = self.endView,
        let scaleView = self.scaleView else {
        return
    }
    guard let startFrame = startView.superview?.convert(startView.frame, to: containerView) else {
        print("无法获取startFrame")
        return
    }
    guard let endFrame = endView.superview?.convert(endView.frame, to: containerView) else {
        print("无法获取endFrame")
        return
    }
    scaleView.frame = startFrame
    containerView.addSubview(scaleView)

    UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { 
        scaleView.frame = endFrame
    }) { _ in
    // presentation转场，需要把目标视图添加到视图栈
    if presentation, let presentedView = transitionContext.view(forKey: .to) {
        containerView.addSubview(presentedView)
    }
    scaleView.removeFromSuperview()
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }
}
```
这里有个关键的方法，坐标转换方法：
```swift
let startFrame = startView.superview?.convert(startView.frame, to: containerView)
let endFrame = endView.superview?.convert(endView.frame, to: containerView)
```
在调用convert之前，需要确保fromView和toView处于同一个window视图栈内，坐标转换才能成功。
这里把startView和endView的坐标统统转成了容器视图的坐标系坐标，只有在同一个坐标系内，缩放变换、动画执行才是正确无误的。

现在可以为PhotoBrowser提供转场动画类了。
注意这里有至关重要的细节需要处理，即对于转场过程中的startView、endView和scaleView如何取的问题。

**presention转场**
```swift
extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 在本方法被调用时，endView和scaleView还未确定。需于viewDidLoad方法中给animator赋值endView
        let animator = ScaleAnimator(startView: relatedView, endView: nil, scaleView: nil)
        presentationAnimator = animator
        return animator
    }
}
```
在presention转场时，startView毫无疑问就是缩略图，小图，即代码中的`relatedView`，这个视图需要图片浏览器通过代理向用户获取，即：
```swift
public protocol PhotoBrowserDelegate {
    /// 实现本方法以返回默认图所在view，在转场动画完成后将会修改这个view的hidden属性
    /// 比如你可返回ImageView，或整个Cell
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView
}

public class PhotoBrowser: UIViewController {
    /// 当前正在显示视图的前一个页面关联视图
    fileprivate var relatedView: UIView {
        return photoBrowserDelegate.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }
}
```
对于endView，是图片浏览器打开时的大图所在imageView，而这个imageView是某个collectionViewCell的内部子视图，显然按正常逻辑来说，转场动画发生时，collectionView还没完成它的视图渲染，此时是无法取到那一个需要显示的cell的。
而对于scaleView，这是一个只在转场过程中创建，转场结束即销毁的视图，它应是一个ImageView，它的创建需要一张图片，这张图片即为缩放过程中呈现的图片，同时也是大图浏览打开完毕后应展示的图片，endView所用的那一张。所以scaleView也无法在此时创建。

那么在什么时候可以取到浏览器打开时所展示的cell?
实测可以发现，几个关键的生命周期方法有如下执行顺序：
```swift
// 1. 取presentation转场动画
public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? 
// 2. 控制器的viewDidLoad
public func viewDidLoad()
// 3. 动画类的转场方法
public func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
// 4. 控制器的viewDidAppear
public override func viewDidAppear(_ animated: Bool)
```
我们必须要在animateTransition方法执行之前，把endView和scaleView都取到，通过上面的顺序分析，我们可以在viewDidLoad方法里强制刷新collectionView完成这件事：
```swift
override public func viewDidLoad() {
    ...
    // 立即加载collectionView
    let indexPath = IndexPath(item: currentIndex, section: 0)
    collectionView.reloadData()
    collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    collectionView.layoutIfNeeded()
    // 取当前应显示的cell，完善转场动画器的设置
    if let cell = collectionView.cellForItem(at: indexPath) as? PhotoBrowserCell {
        presentationAnimator?.endView = cell.imageView
        let imageView = UIImageView(image: cell.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        presentationAnimator?.scaleView = imageView
    }
}
```

**dismissal转场**
dismissal转场就方便得多了，在关闭图片浏览器时，转场动画的startView即为正在展示中的大图视图，endView即为外界的缩略图视图，scaleView也可以通过取大图图片来马上创建得到：
```swift
extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let cell = collectionView.visibleCells.first as? PhotoBrowserCell else {
            return nil
        }
        let imageView = UIImageView(image: cell.imageView.image)
        imageView.contentMode = imageScaleMode
        imageView.clipsToBounds = true
        return ScaleAnimator(startView: cell.imageView, endView: relatedView, scaleView: imageView)
    }
}
```

# 转场动画协处理类
在iOS8以后，苹果为转场动画加入了新成员`UIPresentationController`，它随着转场动画出现而出现，随着转场动画消失而消失，可以进行动画以外的辅助性操作。

回想我们动画是负责视图的缩放的，但是在这过程中还有一点没有解决，它就是背景蒙板。
我们需要一个纯黑色视图来遮住原页面，且它应在转场过程中不断变更透明度alpha值。

**谁来做蒙板比较好呢？**
如果由图片浏览控制器的view来充当，假如改变viewController.view，那在其上的所有视图都会透明化，显然不合适。
如果由图片浏览控制器创建并持有一个纯黑view，放入视图栈，这样确实可以实现效果。
只是，并不优雅。为何这么说？如果要给蒙板指定一个归属者，它应该属于图片浏览控制器呢还是更应该属于转场动画呢？
我们更希望浏览控制器只做图片浏览的事情，而蒙板的作用是隔离浏览器与原页面，已经超出图片浏览的职责，故不应该由PhotoBrowser来持有。

从另外一个角度来想，因为有转场动画，才会有蒙板出现的必要性，故蒙板与转场动画的相性更高，它应属性转场动画的一部分。
然而我们希望动画类保持单纯，只做缩放动画，蒙板这种动画副产品就与我们的动画协处理类非常之配，一拍即合。

在iOS8下，通过实现UIViewControllerTransitioningDelegate协议，返回一个UIPresentationController，在转场动画过程中，UIPresentationController的`presentationTransitionWillBegin`方法和`dismissalTransitionWillBegin`方法将会被调用。
顾名思义，这两个方法一个在presentation动画执行前调用，一个在dismissal动画执行前调用，我们在这两个方法里面可以通过transitionCoordinator方法取到与动画同步进行的block，就可以让蒙板的透明度变化与转场动画同步起来。
```swift
public class PhotoBrowser: UIViewController {
    /// 转场协调器
    fileprivate weak var animatorCoordinator: ScaleAnimatorCoordinator?
}

extension PhotoBrowser: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let coordinator = ScaleAnimatorCoordinator(presentedViewController: presented, presenting: presenting)
        coordinator.currentHiddenView = relatedView
        animatorCoordinator = coordinator
        return coordinator
    }
}

public class ScaleAnimatorCoordinator: UIPresentationController {
    
    /// 动画结束后需要隐藏的view
    public var currentHiddenView: UIView?
    
    /// 蒙板
    public var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    override public func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = self.containerView else { return }
        
        containerView.addSubview(maskView)
        maskView.frame = containerView.bounds
        maskView.alpha = 0
        currentHiddenView?.isHidden = true
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 1
        }, completion:nil)
    }
    
    override public func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        currentHiddenView?.isHidden = true
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.maskView.alpha = 0
        }, completion: { _ in
            self.currentHiddenView?.isHidden = false
        })
    }
}
```
另外，协处理类还需要干一件事情，就是要在动画完成后，悄悄把原页面中的小图隐藏掉，至于为什么这样做，请看下节`Dismiss方式`。

# Dismiss方式
关于怎样关闭图片浏览器，参考微信，有如下两种操作方式：
- 单击图片就关闭
- 按住图片往下拽，松手即关闭

![Dismissal.gif](http://upload-images.jianshu.io/upload_images/2419179-fa339259d76b777e.gif?imageMogr2/auto-orient/strip)

**单击图片就关闭：**
“单击一下缩略图，放大进行浏览；单击一下大图，缩小回去原图”这是很自然的操作，我们来实现它：
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    override init(frame: CGRect) {
        ...
        // 单击手势
        imageView.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
        imageView.addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)

    func onSingleTap() {
        if let dlg = photoBrowserCellDelegate {
            dlg.photoBrowserCellDidSingleTap(self)
        }
    }
}

extension PhotoBrowser: PhotoBrowserCellDelegate {
    public func photoBrowserCellDidSingleTap(_ view: PhotoBrowserCell) {
        dismiss(animated: true, completion: nil)
    }
}
```
这里的注意点是单击手势和双击手势会有冲突，此时我们需要设置一个相当于优先级的东西，优先响应双击手势：
```swift
singleTap.require(toFail: doubleTap)
```
假如不写这一行，即便用户如何快速双击，都无法进入双击手势响应方法，因为单击手势会立即满足条件，立即执行。
写了这一行后，单击手势会变得相对迟钝一些，在确认没有双击手势发生时，单击手势才会生效。
还有一点细节要提的是，执行dismiss应该由controller类内部代码执行，所以不应该把controller传值给cell，让cell去调用controller的dismiss方法，这样做cell就越权了。
所以这里我们通过代理，把单击事件传递到cell外面去，让controller自己进行dismiss。

**按住图片往下拽，松手即关闭：**
这是个很有意思的效果，下拽图片，让图片随着下拽程度渐渐缩小，同时背景黑色蒙板渐变透明，可以看到之前的缩略图界面，而且正在拖拽的图片位置是空的，一松手图片就归位，给人的感受就是我们确实把这张小图放大来看了。
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    /// 记录pan手势开始时imageView的位置
    private var beganFrame = CGRect.zero
    
    /// 记录pan手势开始时，手势位置
    private var beganTouch = CGPoint.zero

    override init(frame: CGRect) {
        // 拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        imageView.addGestureRecognizer(pan)
    }

    func onPan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: pan.view?.superview)
        case .changed:
            // 拖动偏移量
            let translation = pan.translation(in: self)
            let currentTouch = pan.location(in: pan.view?.superview)
            
            // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
            let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
            
            let theFitSize = fitSize
            let width = theFitSize.width * scale
            let height = theFitSize.height * scale
            
            // 计算x和y。保持手指在图片上的相对位置不变。
            // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
            let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
            let currentTouchDeltaX = xRate * width
            let x = currentTouch.x - currentTouchDeltaX
            
            let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
            let currentTouchDeltaY = yRate * height
            let y = currentTouch.y - currentTouchDeltaY
            
            imageView.frame = CGRect(x: x, y: y, width: width, height: height)
            
            // 通知代理，发生了缩放。代理可依scale值改变背景蒙板alpha值
            if let dlg = photoBrowserCellDelegate {
                dlg.photoBrowserCell(self, didPanScale: scale)
            }
        case .ended, .cancelled:
            if pan.velocity(in: self).y > 0 {
                onSingleTap()
            } else {
                endPan()
            }
        default:
            endPan()
        }
    }

    private func endPan() {
        if let dlg = photoBrowserCellDelegate {
            dlg.photoBrowserCell(self, didPanScale: 1.0)
        }
        // 如果图片当前显示的size小于原size，则重置为原size
        let size = fitSize
        let needResetSize = imageView.bounds.size.width < size.width
            || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.centerOfContentSize
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }
}
```
**控制缩放比例**：
```swift
// 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
```
当往下拽的时候，是线性同时缩小宽度和高度，但是，有一个极限值，不允许缩小到原来的0.3倍以下。至于为什么是0.3，这是N多次实践测试后的结果，这个数值可以有比较良好的视觉体验...

**跟随手势移动**
当手指按住图片往下拖时，如果不改变图片大小，可以非常简单直接让图片下移translation.y的偏移量。但我们的情况略有麻烦，在改变图片位置的同时，也改变着图片的大小，这样会导致手指在拖动时，图片会缩着缩着跑出了手指的触摸区。
我们得完善这个细节，一轮计算，算出相对的位移量，让图片不会跑偏，永远处于手指之下：
```swift
// 计算x和y。保持手指在图片上的相对位置不变。
// 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
let currentTouchDeltaX = xRate * width
let x = currentTouch.x - currentTouchDeltaX
let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
let currentTouchDeltaY = yRate * height
let y = currentTouch.y - currentTouchDeltaY
imageView.frame = CGRect(x: x, y: y, width: width, height: height)
```

**dismissal的发生与取消：**
当松开手时，pan手势是带有速度向量属性的，我们定义的发生dismiss的条件是”用户往下拽的过程中松手“，而我们也允许用户有后悔的机会，给他一个能取消的操作，就是重新往上拽回去时，可以取消dismiss：
```swift
case .ended, .cancelled:
if pan.velocity(in: self).y > 0 {
    // dismiss
    onSingleTap()
} else {
    // 取消dismiss
    endPan()
}
```

**背景蒙板：**
另外，在图片缩放的过程中，背景蒙板也应该随着缩放比例而变化，我们把比例值通过代理传递到外界去，让控制器使用：
```swift
// 通知代理，发生了缩放。代理可依scale值改变背景蒙板alpha值
if let dlg = photoBrowserCellDelegate {
    dlg.photoBrowserCell(self, didPanScale: scale)
}

extension PhotoBrowser: PhotoBrowserCellDelegate {
    public func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        // 实测用scale的平方，效果比线性好些
        animatorCoordinator?.maskView.alpha = scale * scale
    }
}
```

**隐藏/显示关联的缩略图：**
还有一个细节要处理，当蒙板渐渐变得透明时，就看到底下的原页面了，这时原页面中有一个小图视图应该要去掉/隐藏，这个小图应当对应于我们正在浏览的那个大图。
对于隐藏小图的处理，在上节中的转场动画协处理类持有并控制着当前浏览大图所关联的小图。
至于为什么这么费力地让协处理类控制关联小图，而不是图片浏览控制器，还是那个道理，各司其职，让浏览器尽量只做浏览图片的工作，况且小图的隐藏/显示与转场动画的相性更合。

在打开图片浏览器时，所关联的小图就是用户进入浏览器时所点的那一张，然后在浏览过程中，随着collectionView左右滑动，关联小图就应该相应地立即更新：
```swift
public class ScaleAnimatorCoordinator: UIPresentationController {
    /// 更新动画结束后需要隐藏的view
    public func updateCurrentHiddenView(_ view: UIView) {
        currentHiddenView?.isHidden = false
        currentHiddenView = view
        view.isHidden = true
    }
}

public class PhotoBrowser: UIViewController {
    /// 当前显示的图片序号，从0开始
    fileprivate var currentIndex = 0 {
        didSet {
            animatorCoordinator?.updateCurrentHiddenView(relatedView)
            if isShowPageControl {
                pageControl.currentPage = currentIndex
            }
        }
    }
    /// 当前正在显示视图的前一个页面关联视图
    fileprivate var relatedView: UIView {
        return photoBrowserDelegate.photoBrowser(self, thumbnailViewForIndex: currentIndex)
    }
}

extension PhotoBrowser: UICollectionViewDelegate {
    /// 减速完成后，计算当前页
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let width = scrollView.bounds.width + photoSpacing
        currentIndex = Int(offsetX / width)
    }
}
```
PhotoBrowser维护着一个变量currentIndex，而relatedView即为所关联的小图，当currentIndex变化时，协处理类应立即同步新的relatedView为隐藏，旧的relatedView恢复显示，保持状态完整性。

# 加载网络图片
现在我们的图片浏览器还剩下最后一个关键能力：支持加载网络图片。
这里使用著名的Swift网络图片加载框架`Kingfisher`，也是本库唯一依赖框架。
```swift
public class PhotoBrowserCell: UICollectionViewCell {
    /// 设置图片。image为placeholder图片，url为网络图片
    public func setImage(_ image: UIImage, url: URL?) {
        guard url != nil else {
            imageView.image = image
            doLayout()
            return
        }
        self.progressView.isHidden = false
        weak var weakSelf = self
        imageView.kf.setImage(with: url, placeholder: image, options: nil, progressBlock: { (receivedSize, totalSize) in
            if totalSize > 0 {
                weakSelf?.progressView.progress = CGFloat(receivedSize) / CGFloat(totalSize)
            }
        }, completionHandler: { (image, error, cacheType, url) in
            weakSelf?.progressView.isHidden = true
            weakSelf?.doLayout()
        })
        self.doLayout()
    }
}
```
在加载过程中，我们需要一个友好的加载进度指示，即progressView，写一个：
```swfit
public class PhotoBrowserProgressView: UIView {
    /// 进度
    public var progress: CGFloat = 0 {
        didSet {
            fanshapedLayer.path = makeProgressPath(progress).cgPath
        }
    }
    /// 外边界
    private var circleLayer: CAShapeLayer!
    /// 扇形区
    private var fanshapedLayer: CAShapeLayer!

    private func setupUI() {
        backgroundColor = UIColor.clear
        let strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        
        circleLayer = CAShapeLayer()
        circleLayer.strokeColor = strokeColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.path = makeCirclePath().cgPath
        layer.addSublayer(circleLayer)
        
        fanshapedLayer = CAShapeLayer()
        fanshapedLayer.fillColor = strokeColor
        layer.addSublayer(fanshapedLayer)
    }
    ...
}
```

![加载图络图片.gif](http://upload-images.jianshu.io/upload_images/2419179-df7348d08250124f.gif?imageMogr2/auto-orient/strip)

# 隐藏状态栏
图片浏览过程中并不需要状态栏StatusBar，应当隐藏。
iOS7后，能控制状态栏的类有两个，`UIApplication`和`UIViewController`，两者只能取其一，默认情况下，由各`UIViewController`独立控制自己的状态栏。
于是，隐藏状态栏就有两种办法：
- 重写UIViewController的`prefersStatusBarHidden`属性/方法，并返回`true`来隐藏状态栏
- 在`info.plist`中取消`UIViewController`的控制权，即设置`View controller-based status bar appearance`为`NO`，然后再设置`UIApplication.shared.isStatusBarHidden = false`

作为一个框架，不应该设置全局属性，不应该操作UIApplication，而且从解耦角度来说就更不应该了。所以我们只负责自己Controller视图的状态栏：
```swift
public override var prefersStatusBarHidden: Bool {
    return true
}
```

然而这种做法，会导致一个问题：在使用pan手势下拽图片时，背景变半透明后，会看见底下页面的状态栏没有了！这是因为背景半透明时，当前ViewController依然还是图片浏览器，而图片浏览器控制着状态栏隐藏。

我们或许会想着，在背景半透明时，刷新状态栏，让prefersStatusBarHidden返回false，在背景恢复全黑时，再刷新状态栏，让prefersStatusBarHidden返回true。
然而这种做法，还是会有问题，我们是不可以让prefersStatusBarHidden直接就返回true的，因为说不定前一页面的状态栏本身就是隐藏的呢，我们这么做岂不是破坏了现场？

我们或许又会想到，那让用户，让调用者在使用图片浏览器的时候，告诉我们，它原本的状态栏是隐藏还是不隐藏的，这样不就解决了吗？确实这样好像能解决问题，但是不好的地方在于增加了用户使用的难度，毕竟多加了一个参数。
不行！为了把**让用户傻瓜式操作**的理念贯彻到底，参数必须能少一个就少一个！我们来另想办法。

其实我们的目的只是要让状态不要挡住图片浏览，那么除了让状态栏本身隐藏掉，还有办法就是盖住它。
我们知道，状态栏在视图层上的level是非常高的，所以得让我们的视图level比它还要高，才有可能盖住它。没错！就是设置`windowLevel`属性为`UIWindowLevelStatusBar + 1`：

```swift
public class PhotoBrowser: UIViewController {
    /// 保存原windowLevel
    private var originWindowLevel: UIWindowLevel!

    /// 遮盖状态栏。以改变windowLevel的方式遮盖
    fileprivate func coverStatusBar(_ cover: Bool) {
        guard let window = view.window else {
            return
        }
        if originWindowLevel == nil {
            originWindowLevel = window.windowLevel
        }
        if cover {
            if window.windowLevel == UIWindowLevelStatusBar + 1 {
                return
            }
            window.windowLevel = UIWindowLevelStatusBar + 1
        } else {
            if window.windowLevel == originWindowLevel {
                return
            }
            window.windowLevel = originWindowLevel
        }
    }
}
```

我们定义了一个`coverStatusBar`方法，让它控制是否遮盖状态栏。而调用它的地方主要有三处：
1. 页面出现后
```swift
    public override func viewDidAppear(_ animated: Bool) {
        // 遮盖状态栏
        coverStatusBar(true)
    }
```
2. 页面消失前
```swift
    public func photoBrowserCellDidSingleTap(_ view: PhotoBrowserCell) {
        coverStatusBar(false)
        dismiss(animated: true, completion: nil)
    }
```
3. 背景变半透明时 
```swift
    public func photoBrowserCell(_ view: PhotoBrowserCell, didPanScale scale: CGFloat) {
        let alpha = scale * scale
        // 半透明时重现状态栏，否则遮盖状态栏
        coverStatusBar(alpha >= 1.0)
    }
```

#页码指示器#
为了框架适用性，PhotoBrowser内部并没有内嵌PageControl，而是以协议的方式支持装配一个PageControl。

```swift
// MARK: - PhotoBrowserPageControl
public protocol PhotoBrowserPageControlDelegate {
    
    /// 取PageControl，只会取一次
    func pageControlOfPhotoBrowser(_ photoBrowser: PhotoBrowser) -> UIView
    
    /// 添加到父视图上时调用
    func photoBrowserPageControl(_ pageControl: UIView, didMoveTo superView: UIView)
    
    /// 让pageControl布局时调用
    func photoBrowserPageControl(_ pageControl: UIView, needLayoutIn superView: UIView)
    
    /// 页码变更时调用
    func photoBrowserPageControl(_ pageControl: UIView, didChangedCurrentPage currentPage: Int)
}
```

同时为了方便使用，我提供了两个写好的实现了`PhotoBrowserPageControlDelegate`协议的类，它们分别是：
- ```swift 
/// 给图片浏览器提供一个UIPageControl
public class PhotoBrowserDefaultPageControlDelegate: PhotoBrowserPageControlDelegate
```

![UIPageControl.png](http://upload-images.jianshu.io/upload_images/2419179-dd60f14462ea5114.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- ```swift 
/// 给图片浏览器提供一个数字样式的PageControl
public class PhotoBrowserNumberPageControlDelegate: PhotoBrowserPageControlDelegate
```

![数字样式PageControl.png](http://upload-images.jianshu.io/upload_images/2419179-66fc50b9420e69e2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

使用方法是装配式的，只需为图片浏览器指定代理即可：
```swift
let vc = PhotoBrowser(showByViewController: self, delegate: self)
// 装配PageControl，这里示例随机选择一种PageControl实现
if arc4random_uniform(2) % 2 == 0 {
    vc.pageControlDelegate = PhotoBrowserDefaultPageControlDelegate(numberOfPages: imageArray.count)
} else {
    vc.pageControlDelegate = PhotoBrowserNumberPageControlDelegate(numberOfPages: imageArray.count)
}
vc.show(index: indexPath.item)
```

如果框架的两个样式都无法满足需求时，也可自己实现PageControl协议，自由定制。

# CocoaPods
已上传CocoaPods，现可直接导入：
```
pod 'JXPhotoBrowser'
```

# 源码
GitHub地址: [PhotoBrowser](https://github.com/JiongXing/PhotoBrowser)
若使用过程中有任何问题，请拼命issues我。 ^_^
