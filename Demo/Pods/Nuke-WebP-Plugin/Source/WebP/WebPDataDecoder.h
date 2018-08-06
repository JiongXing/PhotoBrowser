//
//  WebPDataDecoder.h
//  Nuke-WebP-Plugin iOS
//
//  Created by nagisa-kosuge on 2018/04/30.
//  Copyright © 2018年 RyoKosuge. All rights reserved.
//

#import "WebPImageMacros.h"

#if WEBP_PLUGIN_MAC
#import <AppKit/AppKit.h>
#define Image   NSImage
#else
#import <UIKit/UIKit.h>
#define Image   UIImage
#endif

@interface WebPDataDecoder : NSObject

- (nullable Image *)incrementallyDecodeData:(nonnull NSData *)data isFinal:(BOOL)isFinal;
- (nullable Image *)decodeData:(nonnull NSData *)data;

@end
