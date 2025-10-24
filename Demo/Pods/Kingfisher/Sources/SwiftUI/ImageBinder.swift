//
//  ImageBinder.swift
//  Kingfisher
//
//  Created by onevcat on 2019/06/27.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {

    /// Represents a binder for `KFImage`. It takes responsibility as an `ObjectBinding` and performs
    /// image downloading and progress reporting based on `KingfisherManager`.
    @MainActor
    class ImageBinder: ObservableObject {
        
        init() {}

        var downloadTask: DownloadTask?
        private var loading = false

        var loadingOrSucceeded: Bool {
            return loading || loadedImage != nil
        }

        // Do not use @Published due to https://github.com/onevcat/Kingfisher/issues/1717. Revert to @Published once
        // we can drop iOS 12.
        private(set) var loaded = false

        private(set) var animating = false

        var loadedImage: KFCrossPlatformImage? = nil { willSet { objectWillChange.send() } }
        var failureView: (() -> AnyView)? = nil { willSet { objectWillChange.send() } }
        var progress: Progress = .init()

        func markLoading() {
            loading = true
        }

        func markLoaded(sendChangeEvent: Bool) {
            loaded = true
            if sendChangeEvent {
                objectWillChange.send()
            }
        }

        func start<HoldingView: KFImageHoldingView>(context: Context<HoldingView>) where HoldingView: Sendable {
            guard let source = context.source else {
                CallbackQueueMain.currentOrAsync {
                    context.onFailureDelegate.call(KingfisherError.imageSettingError(reason: .emptySource))
                    if let view = context.failureView {
                        self.failureView = view
                    } else if let image = context.options.onFailureImage {
                        self.loadedImage = image
                    }
                    self.loading = false
                    self.markLoaded(sendChangeEvent: false)
                }
                return
            }

            loading = true
            
            progress = .init()
            downloadTask = KingfisherManager.shared
                .retrieveImage(
                    with: source,
                    options: context.options,
                    progressBlock: { size, total in
                        self.updateProgress(downloaded: size, total: total)
                        context.onProgressDelegate.call((size, total))
                    },
                    progressiveImageSetter: { image in
                        CallbackQueueMain.currentOrAsync {
                            self.markLoaded(sendChangeEvent: true)
                            self.loadedImage = image
                        }
                    },
                    completionHandler: { [weak self] result in

                        guard let self else { return }

                        CallbackQueueMain.currentOrAsync {
                            self.downloadTask = nil
                            self.loading = false
                        }
                        
                        switch result {
                        case .success(let value):
                            CallbackQueueMain.currentOrAsync {
                                if context.swiftUITransition != nil,
                                   context.shouldApplyFade(cacheType: value.cacheType) {
                                    // Apply SwiftUI loadTransition with custom animation (higher priority than fade)
                                    self.animating = true
                                    let animation = context.swiftUIAnimation ?? .default
                                    withAnimation(animation) {
                                        self.markLoaded(sendChangeEvent: true)
                                    }
                                } else if let fadeDuration = context.fadeTransitionDuration(cacheType: value.cacheType) {
                                    self.animating = true
                                    let animation = Animation.linear(duration: fadeDuration)
                                    withAnimation(animation) {
                                        // Trigger the view render to apply the animation.
                                        self.markLoaded(sendChangeEvent: true)
                                    }
                                } else {
                                    self.markLoaded(sendChangeEvent: false)
                                }
                                self.loadedImage = value.image
                                self.animating = false
                            }

                            CallbackQueueMain.async {
                                context.onSuccessDelegate.call(value)
                            }
                        case .failure(let error):
                            CallbackQueueMain.currentOrAsync {
                                if let view = context.failureView {
                                    self.failureView = view
                                } else if let image = context.options.onFailureImage {
                                    self.loadedImage = image
                                }
                                self.markLoaded(sendChangeEvent: false)
                            }
                            
                            CallbackQueueMain.async {
                                context.onFailureDelegate.call(error)
                            }
                        }
                })
        }
        
        private func updateProgress(downloaded: Int64, total: Int64) {
            progress.totalUnitCount = total
            progress.completedUnitCount = downloaded
            objectWillChange.send()
        }

        /// Cancels the download task if it is in progress.
        func cancel() {
            downloadTask?.cancel()
            downloadTask = nil
            loading = false
        }
        
        /// Restores the download task priority to default if it is in progress.
        func restorePriorityOnAppear() {
            guard let downloadTask = downloadTask, loading == true else { return }
            downloadTask.sessionTask?.task.priority = URLSessionTask.defaultPriority
        }
        
        /// Reduce the download task priority if it is in progress.
        func reducePriorityOnDisappear() {
            guard let downloadTask = downloadTask, loading == true else { return }
            downloadTask.sessionTask?.task.priority = URLSessionTask.lowPriority
        }
    }
}
#endif
