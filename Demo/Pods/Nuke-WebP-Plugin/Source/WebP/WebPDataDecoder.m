//
//  WebPDataDecoder.m
//  Nuke-WebP-Plugin iOS
//
//  Created by nagisa-kosuge on 2018/04/30.
//  Copyright © 2018年 RyoKosuge. All rights reserved.
//

#import "WebPDataDecoder.h"
#import "webp/decode.h"

void free_image_data(void *info, const void *data, size_t size) {
    if (info != NULL) {
        WebPFreeDecBuffer(&((WebPDecoderConfig *) info)->output);
        free(info);
    }
    
    WebPFree((void *)data);
}

@implementation WebPDataDecoder {
    WebPIDecoder *_idec;
}

- (void)dealloc {
    if (_idec) {
        WebPIDelete(_idec);
        _idec = NULL;
    }
}

- (Image *)incrementallyDecodeData:(NSData *)data isFinal:(BOOL)isFinal {

    if (!_idec) {
        _idec = WebPINewRGB(MODE_rgbA, NULL, 0, 0);
        if (!_idec) {
            return nil;
        }
    }

    Image *image;

    VP8StatusCode status = WebPIUpdate(_idec, [data bytes], [data length]);
    if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) {
        return nil;
    }

    int width, height, last_y, stride = 0;
    uint8_t *rgba = WebPIDecGetRGB(_idec, &last_y, &width, &height, &stride);

    if (0 < width + height && 0 < last_y && last_y <= height) {
        size_t rgbaSize = last_y * stride;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, rgbaSize, NULL);
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

        CGImageRef imageRef = CGImageCreate(width, last_y, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

        if (!imageRef) {
            return nil;
        }

        CGColorSpaceRef canvasColorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, 8, 0, canvasColorSpaceRef, bitmapInfo);
        if (!canvas) {
            CGImageRelease(imageRef);
            CGColorSpaceRelease(colorSpaceRef);
            CGColorSpaceRelease(canvasColorSpaceRef);
            CGDataProviderRelease(provider);
            return nil;
        }

        CGContextDrawImage(canvas, CGRectMake(0, height - last_y, width, last_y), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);

        CGImageRelease(imageRef);
        CGColorSpaceRelease(colorSpaceRef);

        if (!newImageRef) {
            CGDataProviderRelease(provider);
            return nil;
        }

        CGContextRelease(canvas);
        CGColorSpaceRelease(canvasColorSpaceRef);

#if WEBP_PLUGIN_MAC
        image = [[NSImage alloc] initWithCGImage:newImageRef size:CGSizeZero];
#else
        image = [UIImage imageWithCGImage:newImageRef];
#endif
        CGImageRelease(newImageRef);
        CGDataProviderRelease(provider);
    }

    return image;
}

- (Image *)decodeData:(NSData *)data {
    WebPBitstreamFeatures features;
    if (WebPGetFeatures([data bytes], [data length], &features) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = 0, height = 0;
    uint8_t *webpData = NULL;
    int pixelLength = 0;
    
    if (features.has_alpha) {
        webpData = WebPDecodeRGBA([data bytes], [data length], &width, &height);
        pixelLength = 4;
    } else {
        webpData = WebPDecodeRGB([data bytes], [data length], &width, &height);
        pixelLength = 3;
    }
    
    if (!webpData) {
        return nil;
    }
    
    CGDataProviderRef providerRef = CGDataProviderCreateWithData(NULL,
                                                                 webpData,
                                                                 width * height * pixelLength,
                                                                 free_image_data);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (features.has_alpha) {
        bitmapInfo |= kCGImageAlphaLast;
    } else {
        bitmapInfo |= kCGImageAlphaNone;
    }
    
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width,
                                        height,
                                        8,
                                        8 * pixelLength,
                                        pixelLength * width,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        providerRef,
                                        NULL,
                                        NO,
                                        renderingIntent);
    Image *image = nil;
    
#if WEBP_PLUGIN_MAC
    image = [[NSImage alloc] initWithCGImage: imageRef size: CGSizeZero];
#else
    image = [UIImage imageWithCGImage:imageRef];
#endif
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(providerRef);
    
    return image;
}

@end
