//
//  MomentsViewController.swift
//  PhotoBrowser
//
//  Created by JiongXing on 2017/3/9.
//  Copyright © 2017年 JiongXing. All rights reserved.
//

import UIKit
import Kingfisher
import JXPhotoBrowser

class MomentsViewController: UIViewController {
    
    fileprivate lazy var imageArray: [UIImage] = {
        return [UIImage(named: "photo1")!,
                UIImage(named: "photo2")!,
                UIImage(named: "photo3")!,
                UIImage(named: "photo4")!,
                UIImage(named: "photo5")!,
                UIImage(named: "photo6")!,
                UIImage(named: "photo7")!,
                UIImage(named: "photo8")!,
                UIImage(named: "photo9")!]
    }()
    
    fileprivate lazy var thumbnailImageUrls: [String] = {
        return ["http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                "http://wx1.sinaimg.cn/thumbnail/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                "http://wx2.sinaimg.cn/thumbnail/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                "http://wx4.sinaimg.cn/thumbnail/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                "http://wx3.sinaimg.cn/thumbnail/bfc243a3gy1febm7usmc8j20i543zngx.jpg",]
    }()
    
    fileprivate lazy var highQualityImageUrls: [String] = {
        return ["http://wx1.sinaimg.cn/large/bfc243a3gy1febm7n9eorj20i60hsann.jpg",
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7nzbz7j20ib0iek5j.jpg",
                "http://wx1.sinaimg.cn/large/bfc243a3gy1febm7orgqfj20i80ht15x.jpg",
                "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7pmnk7j20i70jidwo.jpg",
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7qjop4j20i00hw4c6.jpg",
                "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7rncxaj20ek0i74dv.jpg",
                "http://wx2.sinaimg.cn/large/bfc243a3gy1febm7sdk4lj20ib0i714u.jpg",
                "http://wx4.sinaimg.cn/large/bfc243a3gy1febm7tekewj20i20i4aoy.jpg",
                "http://wx3.sinaimg.cn/large/bfc243a3gy1febm7usmc8j20i543zngx.jpg",]
    }()
    
    weak fileprivate var selectedCell: MomentsPhotoCollectionViewCell?
    
    fileprivate var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        let colCount = 3
        let rowCount = 3
        
        let xMargin: CGFloat = 60.0
        let interitemSpacing: CGFloat = 10.0
        let width: CGFloat = self.view.bounds.size.width - xMargin * 2
        let itemSize: CGFloat = (width - 2 * interitemSpacing) / CGFloat(colCount)
        
        let lineSpacing: CGFloat = 10.0
        let height = itemSize * CGFloat(rowCount) + lineSpacing * 2
        let y: CGFloat = 60.0
        
        let frame = CGRect(x: xMargin, y: y, width: width, height: height)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = lineSpacing
        layout.minimumInteritemSpacing = interitemSpacing
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.scrollDirection = .vertical
        
        let cv = UICollectionView(frame: frame, collectionViewLayout: layout)
        cv.register(MomentsPhotoCollectionViewCell.self, forCellWithReuseIdentifier: MomentsPhotoCollectionViewCell.defalutId)
        
        view.addSubview(cv)
        
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = UIColor.white
        collectionView = cv
    }
}

extension MomentsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MomentsPhotoCollectionViewCell.defalutId, for: indexPath) as! MomentsPhotoCollectionViewCell
        cell.imageView.kf.setImage(with: URL(string: thumbnailImageUrls[indexPath.row]))
        return cell
    }
}

extension MomentsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MomentsPhotoCollectionViewCell else {
            return
        }
        selectedCell = cell
        // 开始图片浏览之前，所有thumbnailImage必须都能取得到
        let vc = PhotoBrowser(showByViewController: self, delegate: self)
        // 装配PageControl，提供了两种PageControl实现，若需要其它样式，可参照着自由定制
        if arc4random_uniform(2) % 2 == 0 {
            vc.pageControlDelegate = PhotoBrowserDefaultPageControlDelegate(numberOfPages: imageArray.count)
        } else {
            vc.pageControlDelegate = PhotoBrowserNumberPageControlDelegate(numberOfPages: imageArray.count)
        }
        vc.show(index: indexPath.item)
    }
}

// 实现浏览器代理协议
extension MomentsViewController: PhotoBrowserDelegate {
    func numberOfPhotos(in photoBrowser: PhotoBrowser) -> Int {
        return imageArray.count
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailViewForIndex index: Int) -> UIView {
        return collectionView!.cellForItem(at: IndexPath(item: index, section: 0))!
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, thumbnailImageForIndex index: Int) -> UIImage {
        let cell = collectionView!.cellForItem(at: IndexPath(item: index, section: 0)) as! MomentsPhotoCollectionViewCell
        // 取thumbnailImage
        return cell.imageView.image!
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityUrlStringForIndex index: Int) -> URL? {
        return URL(string: highQualityImageUrls[index])
    }
    
    func photoBrowser(_ photoBrowser: PhotoBrowser, didLongPressForIndex index: Int, image: UIImage) {
        print("长按，图片size:\(image.size)")
    }
    
    /*// 指定本地图片作为highQualityImage
     func photoBrowser(_ photoBrowser: PhotoBrowser, highQualityImageForIndex index: Int) -> UIImage? {
     return imageArray[index]
     }*/
}


