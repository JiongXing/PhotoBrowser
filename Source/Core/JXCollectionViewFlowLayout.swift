//
//  JXCollectionViewFlowLayout.swift
//  JXPhotoBrowser
//
//  Created by 刘靖禹 on 2019/4/6.
//

import UIKit

open class JXCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    open var indexPathForFocusItem: IndexPath?
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let indexPath = self.indexPathForFocusItem {
            if let layoutAttrs = self.layoutAttributesForItem(at: indexPath),
                let collectionView = self.collectionView {
                return CGPoint(x: layoutAttrs.frame.origin.x - collectionView.contentInset.left,
                               y: layoutAttrs.frame.origin.y - collectionView.contentInset.top)
            }
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        } else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }
    }
    
}

