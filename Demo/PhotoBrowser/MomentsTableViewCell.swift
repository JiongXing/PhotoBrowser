//
//  MomentsTableViewCell.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2018/5/21.
//  Copyright © 2018 JiongXing. All rights reserved.
//  

import UIKit
import Kingfisher
import JXPhotoBrowser

class MomentsTableViewCell: UITableViewCell {

    private struct CalculateInfo {
        var sideLength: CGFloat = 0.0
        var lineSpacing: CGFloat = 0.0
        var interitemSpacing: CGFloat = 0.0
        var frame: CGRect = .zero
        var totalHeight: CGFloat = 0.0
    }

    var thumbnailImageUrls: [String] = []
    var highQualityImageUrls: [String] = []
    var overlayModels: [OverlayModel] = []

    /// 点删除按钮回调
    var didTouchDeleteButton: ((_ index: Int) -> Void)?

    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.registerCell(MomentsPhotoCollectionViewCell.self)
        view.backgroundColor = UIColor.white
        return view
    }()

    private weak var showingBrowser: PhotoBrowser?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        collectionView.dataSource = self
        collectionView.delegate = self
        contentView.addSubview(collectionView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let result = calculate(maxWidth: bounds.size.width)
        collectionView.frame = result.frame
        flowLayout.minimumLineSpacing = result.lineSpacing
        flowLayout.minimumInteritemSpacing = result.interitemSpacing
        flowLayout.itemSize = CGSize(width: result.sideLength, height: result.sideLength)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func calculate(maxWidth: CGFloat) -> CalculateInfo {
        let colCount = 3
        let rowCount = 3

        let xMargin: CGFloat = 60.0
        let interitemSpacing: CGFloat = 10.0
        let width: CGFloat = maxWidth - xMargin * 2
        let sideLength: CGFloat = (width - 2 * interitemSpacing) / CGFloat(colCount)

        let lineSpacing: CGFloat = 10.0
        let height = sideLength * CGFloat(rowCount) + lineSpacing * 2
        let y: CGFloat = 30

        let frame = CGRect(x: xMargin, y: y, width: width, height: height)
        var info = CalculateInfo()
        info.sideLength = sideLength
        info.lineSpacing = lineSpacing
        info.interitemSpacing = interitemSpacing
        info.frame = frame
        info.totalHeight = frame.maxY + y
        return info
    }

    func height(for width: CGFloat) -> CGFloat {
        return calculate(maxWidth: width).totalHeight
    }

    func reloadData() {
        collectionView.reloadData()
        showingBrowser?.reloadData()
    }

    func deleteItem(at index: Int) {
        collectionView.reloadData()
        showingBrowser?.deleteItem(at: index)
    }
}

extension MomentsTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnailImageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(MomentsPhotoCollectionViewCell.self, for: indexPath)
        cell.imageView.kf.setImage(with: URL(string: thumbnailImageUrls[indexPath.row]))
        return cell
    }
}

extension MomentsTableViewCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 直接打开图片浏览器
        // PhotoBrowser.show(delegate: self, originPageIndex: indexPath.item)

        // 也可以先创建，然后传参，再打开
        openPhotoBrowserWithInstanceMethod(index: indexPath.item)

        // 浏览本地图片
        // openPhotoBrowserWithLocalImage(index: indexPath.item)
        
        // 带导航栏
        // openPhotoBrowserWithNavigationController(index: indexPath.item)
    }

    /// 逐个属性配置
    private func openPhotoBrowserWithInstanceMethod(index: Int) {
        // 创建图片浏览器
        let browser = PhotoBrowser()
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
        // 装配附加视图插件
        setupOverlayPlugin(on: browser, index: index)
        // 指定打开图片组中的哪张
        browser.originPageIndex = index
        // 展示
        browser.show()
        showingBrowser = browser

        // 可主动关闭图片浏览器
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            browser.dismiss(animated: false)
        }*/
    }

    /// 本地图片
    private func openPhotoBrowserWithLocalImage(index: Int) {
        var localImages: [UIImage] = []
        (0..<9).forEach { _ in
            localImages.append(UIImage(named: "xingkong")!)
        }
        
        // 默认使用 .fade 转场动画，不需要实现任何协议方法
        // PhotoBrowser.show(localImages: localImages, originPageIndex: index)
        
        // 如果要使用 .scale，需要实现协议
        PhotoBrowser.show(localImages: localImages, animationType: .scale, delegate: self, originPageIndex: index)
    }
    
    /// 带导航栏
    private func openPhotoBrowserWithNavigationController(index: Int) {
        let browser = PhotoBrowser(animationType: .fade, delegate: self, originPageIndex: index)
        let nav = UINavigationController(rootViewController: browser)
        browser.show(wrapped: nav)
    }

    /// 装配附加视图插件
    private func setupOverlayPlugin(on browser: PhotoBrowser, index: Int) {
        guard overlayModels.count > index else {
            return
        }
        let overlayPlugin = OverlayPlugin()
        overlayPlugin.dataSourceProvider = { [unowned self] index in
            return self.overlayModels[index]
        }
        overlayPlugin.didTouchDeleteButton = { [unowned self] index in
            self.didTouchDeleteButton?(index)
        }
        browser.cellPlugins.append(overlayPlugin)
    }
}

// 实现浏览器代理协议
extension MomentsTableViewCell: PhotoBrowserDelegate {
    /// 共有多少张图片
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return thumbnailImageUrls.count
    }

    /// 各缩略图图片，也是图片加载完成前的 placeholder
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage? {
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? MomentsPhotoCollectionViewCell
        return cell?.imageView.image
    }

    /// 各缩略图所在 view
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView? {
        return collectionView.cellForItem(at: IndexPath(item: index, section: 0))
    }

    /// 高清图
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlForIndex index: Int) -> URL? {
        /*
        // 测试Gif
        if index == 1 {
            return URL(string: "http://img.gaoxiaogif.cn/GaoxiaoGiffiles/images/2015/07/10/maomiqiangqianbuhuan.gif")
        }*/
        return URL(string: highQualityImageUrls[index])
    }

    /// 原图
    func photoBrowser(_ photoBrowser: PhotoBrowser, rawUrlForIndex index: Int) -> URL? {
        /*
        // 测试原图
        if index == 1 {
            return URL(string: "http://seopic.699pic.com/photo/00040/8565.jpg_wh1200.jpg")
        }*/
        /*
        // 测试WebP
        if index == 1 {
            return URL(string: "https://raw.githubusercontent.com/JiongXing/PhotoBrowser/master/resources/testwebp.webp")
        }*/
        return nil
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, localImageForIndex index: Int) -> UIImage? {
        return index == 2 ? UIImage(named: "xingkong") : nil
    }

    /// 长按图片。你可以在此处得到当前图片，并可以做弹窗，保存图片等操作
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let saveImageAction = UIAlertAction(title: "保存图片", style: .default) { (_) in
            print("保存图片：\(image)")
        }
        /*let loadRawAction = UIAlertAction(title: "查看原图", style: .default) { (_) in
            // 加载长按的原图
            photoBrowser.loadRawImage(at: index)
        }*/
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)

        actionSheet.addAction(saveImageAction)
        actionSheet.addAction(cancelAction)
        photoBrowser.present(actionSheet, animated: true, completion: nil)
    }

    func photoBrowser(_ photoBrowser: PhotoBrowser, didDismissWithIndex index: Int, image: UIImage?) {
        showingBrowser = nil
    }
}

private extension UICollectionView {
    func registerCell<T: UICollectionViewCell>(_ type: T.Type) {
        let identifier = String(describing: type.self)
        register(type, forCellWithReuseIdentifier: identifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("\(type.self) was not registered")
        }
        return cell
    }
}
