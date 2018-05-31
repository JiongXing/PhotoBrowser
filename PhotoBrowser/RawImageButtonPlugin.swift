//
//  RawImageButtonPlugin.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/5/17.
//

import Foundation

/// 查看原图插件
open class RawImageButtonPlugin: PhotoBrowserCellPlugin {

    public func photoBrowserCellDidReused(_ cell: PhotoBrowserCell, at index: Int) {
        if rawImageButton(for: cell) == nil {
            cell.associatedObjects["RawImageButton"] = makeRawImageButton()
        }
    }

    public func photoBrowserCellSetImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, highQualityUrl: URL?, rawUrl: URL?) {
        // 隐藏按钮
        rawImageButton(for: cell)?.isHidden = true
    }

    public func photoBrowserCellDidLayout(_ cell: PhotoBrowserCell) {
        if let button = rawImageButton(for: cell), !button.isHidden {
            cell.contentView.addSubview(button)
            button.sizeToFit()
            button.bounds.size.width += 14
            button.center = CGPoint(x: cell.contentView.bounds.midX,
                                    y: cell.contentView.bounds.height - 25 - button.bounds.height)
        }
    }

    public func photoBrowserCellDidLoadImage(_ cell: PhotoBrowserCell, placeholder: UIImage?, url: URL?) {
        if let rawUrl = cell.rawUrl {
            if let url = url, url != rawUrl {
                // 显示按钮
                rawImageButton(for: cell)?.isHidden = false
            }
        }
    }

    private func rawImageButton(for cell: PhotoBrowserCell) -> UIButton? {
        return cell.associatedObjects["RawImageButton"] as? UIButton
    }

    private func makeRawImageButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.setTitle("查看原图", for: .normal)
        button.setTitle("查看原图", for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(onRawImageButton), for: .touchUpInside)
        return button
    }

    /// 响应查看原图按钮
    @objc open func onRawImageButton(_ button: UIButton) {
        var photoBrowserCell: PhotoBrowserCell? = nil
        var view: UIView? = button
        while let sView = view?.superview {
            if let cell = sView as? PhotoBrowserCell {
                photoBrowserCell = cell
                break
            }
            view = sView
        }
        button.isHidden = true
        photoBrowserCell?.loadRawImage()
    }
}
