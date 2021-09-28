//
//  XCCustomAlertMaker.m
//  lib-ui
//
//  Created by jinfeng on 2021/1/29.
//

#import "XCCustomAlertMaker.h"
#import "XCAlertMaker.h"
#import "XCCustomAlertView.h"
#import "XCCustomSheetView.h"
#import "UIColor+XCAlertColor.h"

@interface XCCustomAlertMaker ()
@property (nonatomic, strong) XCAlertMaker *alertMaker;
@end

@implementation XCCustomAlertMaker

+ (XCCustomAlertMaker *)alert {
    return [self alertWithStyle:XCCustomAlertUIStyleFollowSystem];
}

+ (XCCustomAlertMaker *)alertWithStyle:(XCCustomAlertUIStyle)style {
    XCCustomAlertMaker *instance = XCCustomAlertMaker.new;
    XCCustomAlertView *alert = [[XCCustomAlertView alloc] initWithStyle:style];
    instance.alertMaker = XCAlertMaker.custom(alert);
    return instance;
}

+ (XCCustomAlertMaker *)sheet {
    return [self sheetWithStyle:XCCustomAlertUIStyleFollowSystem];
}

+ (XCCustomAlertMaker *)sheetWithStyle:(XCCustomAlertUIStyle)style {
    XCCustomAlertMaker *instance = XCCustomAlertMaker.new;
    XCCustomSheetView *sheet = [[XCCustomSheetView alloc] initWithStyle:style];
    instance.alertMaker = XCAlertMaker.custom(sheet);
    return instance;
}

- (XCCustomAlertMaker *)setTitle:(NSString *)title {
    self.alertMaker.title(title);
    return self;
}

- (XCCustomAlertMaker *)setContent:(NSString *)content {
    self.alertMaker.message(content);
    return self;
}

- (XCCustomAlertMaker *)addDefaultAction:(NSString *)title action:(void (^ _Nullable)(void))action {
    self.alertMaker.addDefaultAction(title, action);
    return self;
}

- (XCCustomAlertMaker *)addDestructiveAction:(NSString *)title action:(void (^ _Nullable)(void))action {
    self.alertMaker.addDestructiveAction(title, action);
    return self;
}

- (XCCustomAlertMaker *)addCancelAction:(NSString *)title action:(void (^ _Nullable)(void))action {
    self.alertMaker.addCancelAction(title, action);
    return self;
}

- (XCCustomAlertMaker *)addSystemAction:(NSString *)title action:(void (^)(void))action {
    return [self addGeneralAction:title uiSetting:nil action:action];
}

- (XCCustomAlertMaker *)addGeneralAction:(NSString *)title uiSetting:(void (^)(XCCustomUISetting * _Nonnull))uiSetting action:(void (^)(void))action {
    XCCustomUISetting *setting = [XCCustomUISetting new];
    setting.textColor = UIColorHex(0x536FF6);
    setting.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    if (uiSetting) {
        uiSetting(setting);
    }
    self.alertMaker.addCustomAction(title, setting, action);
    return self;
}

- (XCCustomAlertMaker *)dismissOnTap:(BOOL)onTapDismiss {
    self.alertMaker.dimissTapOnTemp(onTapDismiss);
    return self;
}

- (void)presentFrom:(id)viewOrViewController {
    self.alertMaker.presentFrom(viewOrViewController);
}

- (void)dismiss {
    [self.alertMaker dismissAlert];
}

@end
