//
//  XCCustomUIHelper.h
//  lib-ui
//
//  Created by jinfeng on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XCCustomAlertUIStyle) {
    /// 追随系统样式，默认
    XCCustomAlertUIStyleFollowSystem,
    /// 白色样式
    XCCustomAlertUIStyleLight,
    /// 暗黑样式
    XCCustomAlertUIStyleDark,
};


NS_ASSUME_NONNULL_BEGIN

@interface XCCustomUIHelper : NSObject

/// 背景色
/// @param style *
+ (UIColor *)backgroundColorWithStyle:(XCCustomAlertUIStyle)style;

/// 标题色
/// @param style *
+ (UIColor *)titleColorWithStyle:(XCCustomAlertUIStyle)style;

/// 内容色
/// @param style *
+ (UIColor *)contentColorWithStyle:(XCCustomAlertUIStyle)style;

/// 分割线颜色
/// @param style *
+ (UIColor *)lineColorWithStyle:(XCCustomAlertUIStyle)style;

/// 按钮按压色
/// @param style *
+ (UIColor *)pressBackgroundColorWithStyle:(XCCustomAlertUIStyle)style;

/// 红色
/// @param style *
+ (UIColor *)destructiveColorWithStyle:(XCCustomAlertUIStyle)style;

/// 取消色
/// @param style *
+ (UIColor *)cancelColorWithStyle:(XCCustomAlertUIStyle)style;

/// 默认色
/// @param style *
+ (UIColor *)defaultColorWithStyle:(XCCustomAlertUIStyle)style;

@end

NS_ASSUME_NONNULL_END
