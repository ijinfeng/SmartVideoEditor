//
//  XCCustomAlertMaker.h
//  lib-ui
//
//  Created by jinfeng on 2021/1/29.
//

#import <Foundation/Foundation.h>
#import "XCCustomUISetting.h"
#import "XCCustomUIHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCCustomAlertMaker : NSObject

+ (XCCustomAlertMaker *)alert;
+ (XCCustomAlertMaker *)alertWithStyle:(XCCustomAlertUIStyle)style;

+ (XCCustomAlertMaker *)sheet;
+ (XCCustomAlertMaker *)sheetWithStyle:(XCCustomAlertUIStyle)style;

/// 添加标题
/// @param title *
- (XCCustomAlertMaker *)setTitle:(NSString *)title;

/// 添加内容
/// @param content *
- (XCCustomAlertMaker *)setContent:(NSString *)content;

/// 添加一个正常的按钮
/// @param title 按钮名字
/// @param action 点击回调
- (XCCustomAlertMaker *)addDefaultAction:(NSString *)title action:(void(^_Nullable)(void))action;

/// 添加一个红色的按钮
/// @param title 按钮名字
/// @param action 点击回调
- (XCCustomAlertMaker *)addDestructiveAction:(NSString *)title action:(void(^_Nullable)(void))action;

/// 添加一个取消按钮
/// @param title 按钮名字
/// @param action 点击回调
- (XCCustomAlertMaker *)addCancelAction:(NSString *)title action:(void(^_Nullable)(void))action;

/// 添加一个蓝色的按钮
/// @param title 按钮名字
/// @param action 点击回调
- (XCCustomAlertMaker *)addSystemAction:(NSString *)title action:(void(^_Nullable)(void))action;

/// 添加一个自定义样式的按钮
/// @param title 按钮名字
/// @param uiSetting 按钮样式设置
/// @param action 点击回调
- (XCCustomAlertMaker *)addGeneralAction:(NSString *)title uiSetting:(void(^_Nullable)(XCCustomUISetting *setting))uiSetting action:(void(^_Nullable)(void))action;

/// 点击空白处是否关闭
/// @param onTapDismiss *
- (XCCustomAlertMaker *)dismissOnTap:(BOOL)onTapDismiss;

/// 展示弹窗
/// @param viewOrViewController 传入view或控制器都可
- (void)presentFrom:(id)viewOrViewController;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
