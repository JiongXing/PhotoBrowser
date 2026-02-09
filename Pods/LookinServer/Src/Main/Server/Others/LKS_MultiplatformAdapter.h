#ifdef SHOULD_COMPILE_LOOKIN_SERVER
//
//  LKS_MultiplatformAdapter.h
//  
//
//  Created by nixjiang on 2024/3/12.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKS_MultiplatformAdapter : NSObject

+ (UIWindow *)keyWindow;

+ (NSArray<UIWindow *> *)allWindows;

+ (CGRect)mainScreenBounds;

+ (CGFloat)mainScreenScale;

+ (BOOL)isiPad;

@end

NS_ASSUME_NONNULL_END

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
