//
//  XCCustomUIHelper.m
//  lib-ui
//
//  Created by jinfeng on 2021/4/14.
//

#import "XCCustomUIHelper.h"
#import "UIColor+XCAlertColor.h"

@implementation XCCustomUIHelper

+ (UIColor *)color:(UIColor *)light dark:(UIColor *)dark style:(XCCustomAlertUIStyle)style {
    if (style == XCCustomAlertUIStyleLight) {
        return light;
    } else if (style == XCCustomAlertUIStyleDark) {
        return dark;
    } else {
        return [self colorWithNormalColor:light darkStyleColor:dark];
    }
}

+ (UIColor *)backgroundColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = [UIColor whiteColor];
    UIColor *dark = UIColorHex(0x222531);
    return [self color:light dark:dark style:style];
}

+ (UIColor *)titleColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = UIColorHex(0x333333);
    UIColor *dark = [UIColor whiteColor];
    return [self color:light dark:dark style:style];
}

+ (UIColor *)contentColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = UIColorHex(0x333333);
    UIColor *dark = UIColorHex(0xA8B0CC);
    return [self color:light dark:dark style:style];
}

+ (UIColor *)lineColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = [[UIColor blackColor] colorWithAlphaComponent:0.08];
    UIColor *dark = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    return [self color:light dark:dark style:style];
}

+ (UIColor *)pressBackgroundColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = UIColorHex(0xe2e2e2);
    UIColor *dark = [[UIColor colorWithRed:34/255.0 green:40/255.0 blue:55/255.0 alpha:1.0] colorWithAlphaComponent:0.8];
    return [self color:light dark:dark style:style];
}

+ (UIColor *)destructiveColorWithStyle:(XCCustomAlertUIStyle)style {
    return UIColorHex(0xF20000);
}

+ (UIColor *)cancelColorWithStyle:(XCCustomAlertUIStyle)style {
    UIColor *light = UIColorHex(0x666666);
    UIColor *dark = UIColorHex(0xA8B0CC);
    return [self color:light dark:dark style:style];
}

+ (UIColor *)defaultColorWithStyle:(XCCustomAlertUIStyle)style {
    [self colorWithNormalColor:UIColorHex(0x333333) darkStyleColor:[UIColor whiteColor]];
    UIColor *light = UIColorHex(0x333333);
    UIColor *dark = [UIColor whiteColor];
    return [self color:light dark:dark style:style];
}

+ (UIColor *)colorWithNormalColor:(UIColor *)color darkStyleColor:(UIColor *)darkColor {
    if (!darkColor) {
        return color;
    }
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return darkColor;
        } else {
            return color;
        }
    } else {
        return color;
    }
}

@end
