//
//  WebPImageMacros.h
//  Nuke-WebP-Plugin
//
//  Created by ryokosuge on 2018/01/17.
//  Copyright © 2018年 RyoKosuge. All rights reserved.
//
#import <TargetConditionals.h>

#ifndef WebPImageMacros_h
#define WebPImageMacros_h

#if !TARGET_OS_IPHONE && !TARGET_OS_IOS && !TARGET_OS_TV && !TARGET_OS_WATCH
    #define WEBP_PLUGIN_MAC 1
#else
    #define WEBP_PLUGIN_MAC 0
#endif

#if TARGET_OS_IOS || TARGET_OS_TV
    #define WEBP_PLUGIN_UIKIT 1
#else
    #define WEBP_PLUGIN_UIKIT 0
#endif

#if TARGET_OS_IOS
    #define WEBP_PLUGIN_IOS 1
#else
    #define WEBP_PLUGIN_IOS 0
#endif

#if TARGET_OS_TV
    #define WEBP_PLUGIN_TV 1
#else
    #define WEBP_PLUGIN_TV 0
#endif

#endif /* WebPImageMacros_h */
