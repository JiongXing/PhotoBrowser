//
//  JXPhotoBrowserBaseDelegate.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/14.
//

import Foundation
import UIKit

open class JXPhotoBrowserBaseDelegate: NSObject, JXPhotoBrowserDelegate {
    
    /// 弱引用 PhotoBrowser
    open weak var browser: JXPhotoBrowser?
    
    /// 图片内容缩张模式
    open var contentMode: UIView.ContentMode = .scaleAspectFill
    
    /// 长按回调。回传参数分别是：浏览器，图片序号，图片对象，手势对象
    open var longPressedCallback: ((JXPhotoBrowser, Int, UIImage?, UILongPressGestureRecognizer) -> Void)?
    
    /// 是否Right to left语言
    open lazy var isRTLLayout = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    
    //
    // MARK: - 处理状态栏
    //
    
    /// 是否需要遮盖状态栏。默认true
    open var isNeedCoverStatusBar = true
    
    /// 保存原windowLevel
    open var originWindowLevel: UIWindow.Level?
    
    /// 遮盖状态栏。以改变windowLevel的方式遮盖
    /// - parameter cover: true-遮盖；false-不遮盖
    open func coverStatusBar(_ cover: Bool) {
        guard isNeedCoverStatusBar else {
            return
        }
        guard let window = browser?.view.window ?? UIApplication.shared.keyWindow else {
            return
        }
        if originWindowLevel == nil {
            originWindowLevel = window.windowLevel
        }
        guard let originLevel = originWindowLevel else {
            return
        }
        window.windowLevel = cover ? .statusBar : originLevel
    }
    
    //
    // MARK: - UICollectionViewDelegate
    //
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? JXPhotoBrowserBaseCell else {
            return
        }
        cell.imageView.contentMode = contentMode
        // 绑定 Cell 回调事件
        // 单击
        cell.clickCallback = { _ in
            self.dismiss()
        }
        // 拖
        cell.panChangedCallback = { scale in
            // 实测用scale的平方，效果比线性好些
            let alpha = scale * scale
            self.browser?.transDelegate.maskAlpha = alpha
            // 半透明时重现状态栏，否则遮盖状态栏
            self.coverStatusBar(scale > 0.95)
        }
        // 拖完松手
        cell.panReleasedCallback = { isDown in
            if isDown {
                self.dismiss()
            } else {
                self.browser?.transDelegate.maskAlpha = 1.0
                self.coverStatusBar(true)
            }
        }
        // 长按
        weak var weakCell = cell
        cell.longPressedCallback = { gesture in
            if let browser = self.browser {
                self.longPressedCallback?(browser, indexPath.item, weakCell?.imageView.image, gesture)
            }
        }
    }
    
    /// 关闭
    private func dismiss() {
        self.browser?.dismiss(animated: true, completion: nil)
    }
    
    /// scrollView滑动
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var value: CGFloat = 0
        if isRTLLayout {
            value = (scrollView.contentSize.width - scrollView.contentOffset.x - scrollView.bounds.width / 2) / scrollView.bounds.width
        } else {
            value = (scrollView.contentOffset.x + scrollView.bounds.width / 2) / scrollView.bounds.width
        }
        browser?.pageIndex = max(0, Int(value))
    }
    
    /// 取当前显示页的内容视图。比如是 ImageView.
    open func displayingContentView(_ browser: JXPhotoBrowser, pageIndex: Int) -> UIView? {
        let indexPath = IndexPath.init(item: pageIndex, section: 0)
        let cell = browser.collectionView.cellForItem(at: indexPath) as? JXPhotoBrowserBaseCell
        return cell?.imageView
    }
    
    /// 取转场动画视图
    open func transitionZoomView(_ browser: JXPhotoBrowser, pageIndex: Int) -> UIView? {
        let indexPath = IndexPath.init(item: pageIndex, section: 0)
        let cell = browser.collectionView.cellForItem(at: indexPath) as? JXPhotoBrowserBaseCell
        return UIImageView(image: cell?.imageView.image)
    }
    
    open func photoBrowser(_ browser: JXPhotoBrowser, pageIndexDidChanged pageIndex: Int) {
        // Empty.
    }
    
    open func photoBrowserViewDidLoad(_ browser: JXPhotoBrowser) {
        // Empty.
    }
    
    open func photoBrowser(_ browser: JXPhotoBrowser, viewWillAppear animated: Bool) {
        // 遮盖状态栏
        coverStatusBar(true)
    }
    
    open func photoBrowserViewWillLayoutSubviews(_ browser: JXPhotoBrowser) {
        // Empty.
    }
    
    open func photoBrowserViewDidLayoutSubviews(_ browser: JXPhotoBrowser) {
        // Empty.
    }
    
    open func photoBrowser(_ browser: JXPhotoBrowser, viewDidAppear animated: Bool) {
        // Empty.
    }
    
    open func photoBrowser(_ browser: JXPhotoBrowser, viewWillDisappear animated: Bool) {
        // 还原状态栏
        coverStatusBar(false)
    }
    
    open func photoBrowser(_ browser: JXPhotoBrowser, viewDidDisappear animated: Bool) {
        // Empty.
    }
    
    open func dismissPhotoBrowser(_ browser: JXPhotoBrowser) {
        self.dismiss()
    }
    
    open func photoBrowserDidReloadData(_ browser: JXPhotoBrowser) {
        // Empty.
    }
}
