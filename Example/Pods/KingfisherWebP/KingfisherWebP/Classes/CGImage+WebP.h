//
//  CGImage+WebP.h
//  Pods
//
//  Created by yeatse on 2016/10/20.
//
//

#import <CoreGraphics/CoreGraphics.h>

CF_IMPLICIT_BRIDGING_ENABLED
CF_ASSUME_NONNULL_BEGIN

// still image
CGImageRef __nullable WebPImageCreateWithData(CFDataRef webpData);
CFDataRef __nullable WebPDataCreateWithImage(CGImageRef image);

// animated image
CG_EXTERN const CFStringRef kWebPAnimatedImageDuration;
CG_EXTERN const CFStringRef kWebPAnimatedImageLoopCount;
CG_EXTERN const CFStringRef kWebPAnimatedImageFrames; // CFArrayRef of CGImageRef

NSUInteger WebPImageFrameCountGetFromData(CFDataRef webpData);
CFDictionaryRef __nullable WebPAnimatedImageInfoCreateWithData(CFDataRef webpData);
CFDataRef __nullable WebPDataCreateWithAnimatedImageInfo(CFDictionaryRef imageInfo);

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED
