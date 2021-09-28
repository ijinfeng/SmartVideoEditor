//
//  XCButton.h
//  BundleFastlane
//
//  Created by jinfeng on 2020/8/31.
//  Copyright © 2020 jinfeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XCButtonAttribute.h"

NS_ASSUME_NONNULL_BEGIN
@class XCButton;

typedef XCButton *_Nullable(^XCButtonActionBlock)(void(^action)(XCButton *button));

/// 按钮组件
/// https://app.mockplus.cn/app/ff3_KMmvH/specs/lljRFnBI_R
@interface XCButton : UIControl

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/// 设置标题
@property (nonatomic, copy) NSString *title;

/// 添加单点操作
@property (nonatomic, copy, readonly) XCButtonActionBlock addTapAction;

/// 自动切圆角，默认YES
@property (nonatomic, assign) BOOL autoClipsRound;

/// 设置自定义的样式
/// @param maker 在block中设置attribute的属性
- (void)setCustomAttribute:(void(^)(XCButtonAttribute *attribute))maker;

/// 绑定一个新的样式
/// @param attribute 按钮样式
- (void)bindCustomAttribute:(XCButtonAttribute *)attribute;

/// 当前的按钮样式
@property (nonatomic, strong, readonly) XCButtonAttribute *attribute;

/// 自定义样式，这种用于重写按钮时用到，效果和'bindCustomAttribute'一致
+ (Class)buttonAttributeClass;

@end

NS_ASSUME_NONNULL_END
