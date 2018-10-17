//
//  FadeTransitioning.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/10/16.
//

import Foundation

extension JXPhotoBrowser {
    public class FadeTransitioning: JXPhotoBrowser.Transitioning {
        public override init() {
            super.init()
            self.presentingAnimator = JXPhotoBrowser.FadePresentingAnimator()
            self.dismissingAnimator = JXPhotoBrowser.FadeDismissingAnimator()
        }
    }
}
