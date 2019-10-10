//
//  CGImage+WebP.m
//  Pods
//
//  Created by yeatse on 2016/10/20.
//
//

#import "CGImage+WebP.h"

#import <Accelerate/Accelerate.h>
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"

#pragma mark - Helper Functions

static void WebPFreeInfoReleaseDataCallback(void *info, const void *data, size_t size) {
    if (info) {
        free(info);
    }
}

static CGColorSpaceRef WebPColorSpaceForDeviceRGB() {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

/**
 Decode an image to bitmap buffer with the specified format.
 
 @param srcImage   Source image.
 @param dest       Destination buffer. It should be zero before call this method.
 If decode succeed, you should release the dest->data using free().
 @param destFormat Destination bitmap format.
 
 @return Whether succeed.
 
 @warning This method support iOS7.0 and later. If call it on iOS6, it just returns NO.
 CG_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
 */
static BOOL WebPCGImageDecodeToBitmapBufferWithAnyFormat(CGImageRef srcImage, vImage_Buffer *dest, vImage_CGImageFormat *destFormat) {
    if (!srcImage || (((long)vImageConvert_AnyToAny) + 1 == 1) || !destFormat || !dest) return NO;
    size_t width = CGImageGetWidth(srcImage);
    size_t height = CGImageGetHeight(srcImage);
    if (width == 0 || height == 0) return NO;
    dest->data = NULL;
    
    vImage_Error error = kvImageNoError;
    CFDataRef srcData = NULL;
    vImageConverterRef convertor = NULL;
    vImage_CGImageFormat srcFormat = {0};
    srcFormat.bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(srcImage);
    srcFormat.bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(srcImage);
    srcFormat.colorSpace = CGImageGetColorSpace(srcImage);
    srcFormat.bitmapInfo = CGImageGetBitmapInfo(srcImage) | CGImageGetAlphaInfo(srcImage);
    
    convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, destFormat, NULL, kvImageNoFlags, NULL);
    if (!convertor) goto fail;
    
    CGDataProviderRef srcProvider = CGImageGetDataProvider(srcImage);
    srcData = srcProvider ? CGDataProviderCopyData(srcProvider) : NULL; // decode
    size_t srcLength = srcData ? CFDataGetLength(srcData) : 0;
    const void *srcBytes = srcData ? CFDataGetBytePtr(srcData) : NULL;
    if (srcLength == 0 || !srcBytes) goto fail;
    
    vImage_Buffer src = {0};
    src.data = (void *)srcBytes;
    src.width = width;
    src.height = height;
    src.rowBytes = CGImageGetBytesPerRow(srcImage);
    
    error = vImageBuffer_Init(dest, height, width, 32, kvImageNoFlags);
    if (error != kvImageNoError) goto fail;
    
    error = vImageConvert_AnyToAny(convertor, &src, dest, NULL, kvImageNoFlags); // convert
    if (error != kvImageNoError) goto fail;
    
    CFRelease(convertor);
    CFRelease(srcData);
    return YES;
    
fail:
    if (convertor) CFRelease(convertor);
    if (srcData) CFRelease(srcData);
    if (dest->data) free(dest->data);
    dest->data = NULL;
    return NO;
}

/**
 Decode an image to bitmap buffer with the 32bit format (such as ARGB8888).
 
 @param srcImage   Source image.
 @param dest       Destination buffer. It should be zero before call this method.
 If decode succeed, you should release the dest->data using free().
 @param bitmapInfo Destination bitmap format.
 
 @return Whether succeed.
 */
static BOOL WebPCGImageDecodeToBitmapBufferWith32BitFormat(CGImageRef srcImage, vImage_Buffer *dest, CGBitmapInfo bitmapInfo) {
    if (!srcImage || !dest) return NO;
    size_t width = CGImageGetWidth(srcImage);
    size_t height = CGImageGetHeight(srcImage);
    if (width == 0 || height == 0) return NO;
    
    BOOL hasAlpha = NO;
    BOOL alphaFirst = NO;
    BOOL alphaPremultiplied = NO;
    BOOL byteOrderNormal = NO;
    
    switch (bitmapInfo & kCGBitmapAlphaInfoMask) {
        case kCGImageAlphaPremultipliedLast: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
        } break;
        case kCGImageAlphaPremultipliedFirst: {
            hasAlpha = YES;
            alphaPremultiplied = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaLast: {
            hasAlpha = YES;
        } break;
        case kCGImageAlphaFirst: {
            hasAlpha = YES;
            alphaFirst = YES;
        } break;
        case kCGImageAlphaNoneSkipLast: {
        } break;
        case kCGImageAlphaNoneSkipFirst: {
            alphaFirst = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    switch (bitmapInfo & kCGBitmapByteOrderMask) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: {
            return NO;
        } break;
    }
    
    /*
     Try convert with vImageConvert_AnyToAny() (avaliable since iOS 7.0).
     If fail, try decode with CGContextDrawImage().
     CGBitmapContext use a premultiplied alpha format, unpremultiply may lose precision.
     */
    vImage_CGImageFormat destFormat = {0};
    destFormat.bitsPerComponent = 8;
    destFormat.bitsPerPixel = 32;
    destFormat.colorSpace = WebPColorSpaceForDeviceRGB();
    destFormat.bitmapInfo = bitmapInfo;
    dest->data = NULL;
    if (WebPCGImageDecodeToBitmapBufferWithAnyFormat(srcImage, dest, &destFormat)) return YES;
    
    CGBitmapInfo contextBitmapInfo = bitmapInfo & kCGBitmapByteOrderMask;
    if (!hasAlpha || alphaPremultiplied) {
        contextBitmapInfo |= (bitmapInfo & kCGBitmapAlphaInfoMask);
    } else {
        contextBitmapInfo |= alphaFirst ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaPremultipliedLast;
    }
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, WebPColorSpaceForDeviceRGB(), contextBitmapInfo);
    if (!context) goto fail;
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), srcImage); // decode and convert
    size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t length = height * bytesPerRow;
    void *data = CGBitmapContextGetData(context);
    if (length == 0 || !data) goto fail;
    
    dest->data = malloc(length);
    dest->width = width;
    dest->height = height;
    dest->rowBytes = bytesPerRow;
    if (!dest->data) goto fail;
    
    if (hasAlpha && !alphaPremultiplied) {
        vImage_Buffer tmpSrc = {0};
        tmpSrc.data = data;
        tmpSrc.width = width;
        tmpSrc.height = height;
        tmpSrc.rowBytes = bytesPerRow;
        vImage_Error error;
        if (alphaFirst && byteOrderNormal) {
            error = vImageUnpremultiplyData_ARGB8888(&tmpSrc, dest, kvImageNoFlags);
        } else {
            error = vImageUnpremultiplyData_RGBA8888(&tmpSrc, dest, kvImageNoFlags);
        }
        if (error != kvImageNoError) goto fail;
    } else {
        memcpy(dest->data, data, length);
    }
    
    CFRelease(context);
    return YES;
    
fail:
    if (context) CFRelease(context);
    if (dest->data) free(dest->data);
    dest->data = NULL;
    return NO;
    return NO;
}

static int WebPPictureImportCGImage(WebPPicture *picture, CGImageRef image) {
    vImage_Buffer buffer = {0};
    int result = 0;
    if (WebPCGImageDecodeToBitmapBufferWith32BitFormat(image, &buffer, kCGImageAlphaLast | kCGBitmapByteOrderDefault)) {
        picture->width = (int)buffer.width;
        picture->height = (int)buffer.height;
        picture->use_argb = 1;
        result = WebPPictureImportRGBA(picture, buffer.data, (int)buffer.rowBytes);
        free(buffer.data);
    }
    return result;
}

#pragma mark - Still Images

CGImageRef WebPImageCreateWithData(CFDataRef webpData) {
    WebPData webp_data;
    WebPDataInit(&webp_data);
    webp_data.bytes = CFDataGetBytePtr(webpData);
    webp_data.size = CFDataGetLength(webpData);
    
    WebPAnimDecoderOptions dec_options;
    WebPAnimDecoderOptionsInit(&dec_options);
    dec_options.use_threads = 1;
    dec_options.color_mode = MODE_rgbA;
    
    WebPAnimDecoder *dec = WebPAnimDecoderNew(&webp_data, &dec_options);
    if (!dec) {
        return NULL;
    }
    
    WebPAnimInfo anim_info;
    uint8_t *buf;
    int timestamp;
    if (!WebPAnimDecoderGetInfo(dec, &anim_info) || !WebPAnimDecoderGetNext(dec, &buf, &timestamp)) {
        WebPAnimDecoderDelete(dec);
        return NULL;
    }
    
    const size_t bufSize = anim_info.canvas_width * 4 * anim_info.canvas_height;
    void *bufCopy = malloc(bufSize);
    memcpy(bufCopy, buf, bufSize);
    WebPAnimDecoderDelete(dec);
        
    CGDataProviderRef provider = CGDataProviderCreateWithData(bufCopy, bufCopy, bufSize, WebPFreeInfoReleaseDataCallback);
    CGImageRef image = CGImageCreate(anim_info.canvas_width, anim_info.canvas_height, 8, 32, anim_info.canvas_width * 4, WebPColorSpaceForDeviceRGB(), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    
    return image;
}

CFDataRef WebPDataCreateWithImage(CGImageRef image) {
    WebPConfig config;
    WebPConfigInit(&config);
    WebPConfigLosslessPreset(&config, 0);
    
    WebPPicture picture;
    WebPPictureInit(&picture);
    
    WebPMemoryWriter writer;
    WebPMemoryWriterInit(&writer);
    picture.writer = WebPMemoryWrite;
    picture.custom_ptr = &writer;
    
    if (!(WebPPictureImportCGImage(&picture, image))) {
        goto fail;
    }
    
    if (!WebPEncode(&config, &picture)) {
        goto fail;
    }
    
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, writer.mem, writer.size);
    WebPMemoryWriterClear(&writer);
    WebPPictureFree(&picture);
    return data;
    
fail:
    WebPMemoryWriterClear(&writer);
    WebPPictureFree(&picture);
    return NULL;
}

#pragma mark - Animated Images

const CFStringRef kWebPAnimatedImageDuration = CFSTR("kWebPAnimatedImageDuration");
const CFStringRef kWebPAnimatedImageLoopCount = CFSTR("kWebPAnimatedImageLoopCount");
const CFStringRef kWebPAnimatedImageFrames = CFSTR("kWebPAnimatedImageFrames");

uint32_t WebPImageFrameCountGetFromData(CFDataRef webpData) {
    WebPData webp_data;
    WebPDataInit(&webp_data);
    webp_data.bytes = CFDataGetBytePtr(webpData);
    webp_data.size = CFDataGetLength(webpData);
    
    WebPDemuxer *dmux = WebPDemux(&webp_data);
    if (!dmux) {
        return 0;
    }
    
    uint32_t frameCount = WebPDemuxGetI(dmux, WEBP_FF_FRAME_COUNT);
    WebPDemuxDelete(dmux);
    
    return frameCount;
}

CFDictionaryRef WebPAnimatedImageInfoCreateWithData(CFDataRef webpData) {
    WebPData webp_data;
    WebPDataInit(&webp_data);
    webp_data.bytes = CFDataGetBytePtr(webpData);
    webp_data.size = CFDataGetLength(webpData);
    
    WebPAnimDecoderOptions dec_options;
    WebPAnimDecoderOptionsInit(&dec_options);
    dec_options.use_threads = 1;
    dec_options.color_mode = MODE_rgbA;
    
    WebPAnimDecoder *dec = WebPAnimDecoderNew(&webp_data, &dec_options);
    if (!dec) {
        return NULL;
    }
    
    WebPAnimInfo anim_info;
    if (!WebPAnimDecoderGetInfo(dec, &anim_info)) {
        WebPAnimDecoderDelete(dec);
        return NULL;
    }
    
    CFMutableDictionaryRef imageInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFMutableArrayRef imageFrames = CFArrayCreateMutable(kCFAllocatorDefault, anim_info.frame_count, &kCFTypeArrayCallBacks);
    
    int duration = 0;
    while (WebPAnimDecoderHasMoreFrames(dec)) {
        uint8_t *buf;
        
        if (!WebPAnimDecoderGetNext(dec, &buf, &duration)) {
            break;
        }
        
        const size_t bufSize = anim_info.canvas_width * 4 * anim_info.canvas_height;
        void *bufCopy = malloc(bufSize);
        memcpy(bufCopy, buf, bufSize);
        
        CGDataProviderRef provider = CGDataProviderCreateWithData(bufCopy, bufCopy, bufSize, WebPFreeInfoReleaseDataCallback);
        CGImageRef image = CGImageCreate(anim_info.canvas_width, anim_info.canvas_height, 8, 32, anim_info.canvas_width * 4, WebPColorSpaceForDeviceRGB(), kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
        CFArrayAppendValue(imageFrames, image);
        CGImageRelease(image);
        CGDataProviderRelease(provider);
    }
    
    // add last frame's duration
    const WebPDemuxer *dmux = WebPAnimDecoderGetDemuxer(dec);
    WebPIterator iter;
    if (WebPDemuxGetFrame(dmux, 0, &iter)) {
        duration += iter.duration;
        WebPDemuxReleaseIterator(&iter);
    }
    WebPAnimDecoderDelete(dec);
    
    CFDictionarySetValue(imageInfo, kWebPAnimatedImageFrames, imageFrames);
    CFRelease(imageFrames);
    
    CFNumberRef loopCount = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &anim_info.loop_count);
    CFDictionarySetValue(imageInfo, kWebPAnimatedImageLoopCount, loopCount);
    CFRelease(loopCount);
    
    double durationInSec = ((double)duration) / 1000;
    CFNumberRef durationRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &durationInSec);
    CFDictionarySetValue(imageInfo, kWebPAnimatedImageDuration, durationRef);
    CFRelease(durationRef);
    
    return imageInfo;
}



CFDataRef WebPDataCreateWithAnimatedImageInfo(CFDictionaryRef imageInfo) {
    CFNumberRef loopCount = CFDictionaryGetValue(imageInfo, kWebPAnimatedImageLoopCount);
    CFNumberRef durationRef = CFDictionaryGetValue(imageInfo, kWebPAnimatedImageDuration);
    CFArrayRef imageFrames = CFDictionaryGetValue(imageInfo, kWebPAnimatedImageFrames);
    
    if (!imageFrames || CFArrayGetCount(imageFrames) < 1) {
        return NULL;
    }
    
    WebPAnimEncoderOptions enc_options;
    WebPAnimEncoderOptionsInit(&enc_options);
    if (loopCount) {
        CFNumberGetValue(loopCount, kCFNumberSInt32Type, &enc_options.anim_params.loop_count);
    }
    
    CGImageRef firstImage = (CGImageRef)CFArrayGetValueAtIndex(imageFrames, 0);
    WebPAnimEncoder *enc = WebPAnimEncoderNew((int)CGImageGetWidth(firstImage), (int)CGImageGetHeight(firstImage), &enc_options);
    if (!enc) {
        return NULL;
    }
    
    int frameDurationInMilliSec = 100;
    if (durationRef) {
        double totalDurationInSec;
        CFNumberGetValue(durationRef, kCFNumberDoubleType, &totalDurationInSec);
        frameDurationInMilliSec = (int)(totalDurationInSec * 1000 / CFArrayGetCount(imageFrames));
    }
    
    for (CFIndex i = 0; i < CFArrayGetCount(imageFrames); i ++) {
        WebPPicture frame;
        WebPPictureInit(&frame);
        if (WebPPictureImportCGImage(&frame, (CGImageRef)CFArrayGetValueAtIndex(imageFrames, i))) {
            WebPConfig config;
            WebPConfigInit(&config);
            WebPConfigLosslessPreset(&config, 0);
            WebPAnimEncoderAdd(enc, &frame, (int)(frameDurationInMilliSec * i), &config);
        }
        WebPPictureFree(&frame);
    }
    WebPAnimEncoderAdd(enc, NULL, (int)(frameDurationInMilliSec * CFArrayGetCount(imageFrames)), NULL);
    
    WebPData webp_data;
    WebPDataInit(&webp_data);
    WebPAnimEncoderAssemble(enc, &webp_data);
    WebPAnimEncoderDelete(enc);
    
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, webp_data.bytes, webp_data.size);
    WebPDataClear(&webp_data);
    
    return data;
}
