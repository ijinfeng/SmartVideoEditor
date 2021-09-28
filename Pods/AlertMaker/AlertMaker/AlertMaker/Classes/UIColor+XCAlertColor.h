//
//  UIColor+XCAlertColor.h
//  AlertMaker
//
//  Created by jinfeng on 2021/8/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef UIColorHex
#define UIColorHex(_hex_)   [UIColor colorWithHexString:((__bridge NSString *)CFSTR(#_hex_))]
#endif

@interface UIColor (XCAlertColor)
+ (nullable UIColor *)colorWithHexString:(NSString *)hexStr;
@end

NS_ASSUME_NONNULL_END
