//
//  XCButtonAttribute.h
//  BundleFastlane
//
//  Created by jinfeng on 2020/8/31.
//  Copyright © 2020 jinfeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCButtonAttribute : NSObject

/// 最小左右间距
@property (nonatomic, assign) CGFloat minimumSpace;

/// 按钮标题
@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) CAGradientLayer *backgroundLayer;

@property (nonatomic, strong, nullable) NSArray *backgroundColors;

@property (nonatomic, strong, nullable) NSArray *pressBackgroundColors;

@property (nonatomic, strong, nullable) NSArray *disableBackgroundColors;

@property (nonatomic, strong) UIColor *textColor;

@property (nonatomic, strong, nullable) UIColor *pressTextColor;

@property (nonatomic, strong, nullable) UIColor *disableTextColor;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, strong, nullable) UIColor *borderLineColor;

@property (nonatomic, strong, nullable) UIColor *pressBorderLineColor;

@property (nonatomic, strong, nullable) UIColor *disableBorderLineColor;

@property (nonatomic, strong, nullable) UIColor *pressMaskColor;

@property (nonatomic, assign) CGFloat disalbeAlpha;

@end

NS_ASSUME_NONNULL_END
