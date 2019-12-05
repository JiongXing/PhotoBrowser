//
//  JXPhotoBrowserTransDelegate.swift
//  
//
//  Created by JiongXing on 2019/12/3.
//

import UIKit

public class JXPhotoBrowserTransDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        JXPhotoBrowserLog.high("dlg dismiss!")
        return nil
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        JXPhotoBrowserLog.high("dlg present!")
        return nil
    }
}
