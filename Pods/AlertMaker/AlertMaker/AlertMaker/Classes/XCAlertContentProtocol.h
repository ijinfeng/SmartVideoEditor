//
//  XCAlertContentProtocol.h
//  XCAlertController
//
//  Created by JinFeng on 2019/4/23.
//  Copyright © 2019 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIViewControllerTransitioning.h>

typedef NS_ENUM(NSInteger, XCAlertAnimation) {
    /// pop like system alert,it is Default style
    XCAlertAnimationPopAlert,
    /// animation like system sheet
    XCAlertAnimationSheet,
    XCAlertAnimationPullDown,
};

NS_ASSUME_NONNULL_BEGIN
@class XCAlertAction;
@protocol XCAlertContentProtocol <NSObject>

@required
- (CGRect)frameForViewContent;

@optional
- (void)installWithTitle:(nullable NSString *)title
                 message:(nullable NSString *)message
                 actions:(NSArray <XCAlertAction *>*)actions;

/// custom Transition
- (void)customAnimateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;

/// default 'XCAlertAnimationPopAlert'.If you need not any animation for alert,you can return animationDuration 0.
- (XCAlertAnimation)alertAnimation;

/// animation bg color to black 50%(Default).You can custom bg color
- (UIColor *)animationTransitionColor;

/// default is 0.25s
- (NSTimeInterval)animationDuration;

/// is set animate YES, default 0.25
- (NSTimeInterval)setNeedsUpdateFrameAnimationDuration;

/// called when alert show on view
- (void)alertDidShow;

/// called when alert remove from superview
- (void)alertDidDismiss;

/// set mask view's insets, default {0, 0, 0, 0}
- (UIEdgeInsets)insetsForMaskView;

/// whether the gesture can through the mask view
- (BOOL)canGestureRecognizerThroughTheMaskView;

@end

NS_ASSUME_NONNULL_END
