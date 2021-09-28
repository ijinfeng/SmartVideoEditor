//  XCAlertController
//
//  Created by JinFeng on 2019/4/23.
//  Copyright © 2019 Netease. All rights reserved.
//

#import "XCAlertMaker.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>

static const float kPresentDelay = 0.3;
static const void *kSetNeedsUpdateFrameKey = &kSetNeedsUpdateFrameKey;

typedef NS_ENUM(int, XCAlertControllerStyle) {
    XCAlertControllerStyleAlert,
    XCAlertControllerStyleSheet,
    XCAlertControllerStyleCustom,
};

#pragma mark - PresentTranstion

@interface XCPresentTransition : UIPresentationController<UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) BOOL dismissTapOnTemp;

@property (nonatomic, assign) XCAlertAnimation animationStyle;

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController
                       presentingViewController:(nullable UIViewController *)presentingViewController
                                          style:(XCAlertControllerStyle)style;
- (void)dismiss;

@end

@interface XCPresentTransition ()
@property (nonatomic, assign) XCAlertControllerStyle style;
@property (nonatomic, strong) UIView *backgroundView;
@end

@implementation XCPresentTransition

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController style:(XCAlertControllerStyle)style {
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self) {
        _style = style;
        _dismissTapOnTemp = NO;
        _animationStyle = XCAlertAnimationPopAlert;
        presentedViewController.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)presentationTransitionWillBegin {
    UIViewController *customAlert = self.presentedViewController;
    UIColor *backgroundColor = [UIColor blackColor];
    if ([customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)]
        && [customAlert respondsToSelector:@selector(animationTransitionColor)]) {
        backgroundColor = [(id<XCAlertContentProtocol>)customAlert animationTransitionColor];
    }
    
    self.backgroundView = [[UIView alloc] initWithFrame:self.containerView.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = backgroundColor;
    self.backgroundView.alpha = 0;
    [self.containerView addSubview:self.backgroundView];
    
    if (self.dismissTapOnTemp) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionForTapOnTemp)];
        [self.backgroundView addGestureRecognizer:tap];
    }
    
    [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.backgroundView.alpha = 0.5;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if ([customAlert respondsToSelector:@selector(alertDidShow)]) {
            [((id<XCAlertContentProtocol>)customAlert) alertDidShow];
        }
    }];
}

- (void)actionForTapOnTemp {
    [self dismiss];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dismissalTransitionWillBegin {
    UIViewController *customAlert = self.presentedViewController;
    [self.presentingViewController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.backgroundView.alpha = 0;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if ([customAlert respondsToSelector:@selector(alertDidShow)]) {
            [((id<XCAlertContentProtocol>)customAlert) alertDidShow];
        }
    }];
}

- (void)dismissalTransitionDidEnd:(BOOL)completed {
    if (completed) {
        [self.backgroundView removeFromSuperview];
        self.backgroundView = nil;
    }
}

- (void)containerViewDidLayoutSubviews {
    UIViewController *toVC = self.presentedViewController;
    if ([toVC conformsToProtocol:@protocol(XCAlertContentProtocol)]
        && [toVC respondsToSelector:@selector(frameForViewContent)]) {
        CGRect rect = [(id<XCAlertContentProtocol>)toVC frameForViewContent];
        BOOL animate = [objc_getAssociatedObject(toVC, kSetNeedsUpdateFrameKey) boolValue];
        NSTimeInterval duration = 0;
        if (animate) {
            if ([toVC conformsToProtocol:@protocol(XCAlertContentProtocol)]
                && [toVC respondsToSelector:@selector(setNeedsUpdateFrameAnimationDuration)]) {
                duration = [(id<XCAlertContentProtocol>)toVC setNeedsUpdateFrameAnimationDuration];
            } else {
                duration = 0.25;
            }
        }
        [UIView animateWithDuration:duration animations:^{
            toVC.view.frame = rect;
        }];
        objc_setAssociatedObject(self, kSetNeedsUpdateFrameKey, @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark UIViewControllerTransitioningDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

- (UIPresentationController* )presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    return self;
}

#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    BOOL presenting = fromVC == self.presentingViewController;
    UIViewController *alertVC = presenting ? toVC : fromVC;
    if ([alertVC respondsToSelector:@selector(animationDuration)]) {
        return [(id<XCAlertContentProtocol>)alertVC animationDuration];
    }
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    BOOL presenting = fromVC == self.presentingViewController;
    UIViewController *alertVC = presenting ? toVC : fromVC;
    // custom animation
    if ([alertVC conformsToProtocol:@protocol(XCAlertContentProtocol)]
        && [alertVC respondsToSelector:@selector(customAnimateTransition:)]) {
        [(id<XCAlertContentProtocol>)alertVC customAnimateTransition:transitionContext];
        return;
    }
    
    // system animation
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *containerView = [transitionContext containerView];
    
    // begin animation
    CGRect finalFrame = CGRectZero, initialFrame = CGRectZero;
    XCAlertAnimation animation = self.animationStyle;
    if ([alertVC conformsToProtocol:@protocol(XCAlertContentProtocol)]) {
        if ([alertVC respondsToSelector:@selector(alertAnimation)]) {
            animation = [(id<XCAlertContentProtocol>)alertVC alertAnimation];
        }
    }
    
    if ([alertVC conformsToProtocol:@protocol(XCAlertContentProtocol)]) {
        if ([alertVC respondsToSelector:@selector(frameForViewContent)]) {
            finalFrame = [(id<XCAlertContentProtocol>)alertVC frameForViewContent];
        }
    }
    
    if (animation == XCAlertAnimationPopAlert) {
        if (presenting) {
            toView.alpha = 0;
            toView.transform = CGAffineTransformMakeScale(1.3, 1.3);
            CGRect rect = finalFrame;
            initialFrame = rect;
        } else {
            initialFrame = finalFrame;
        }
    } else if (animation == XCAlertAnimationSheet) {
        CGRect rect = finalFrame;
        rect.origin.y = rect.origin.y + finalFrame.size.height;
        initialFrame = rect;
    } else if (animation == XCAlertAnimationPullDown) {
        CGRect rect = finalFrame;
        rect.origin.y = rect.origin.y - finalFrame.size.height;
        initialFrame = rect;
    }
    
    if (presenting) {
        toView.frame = initialFrame;
        [containerView addSubview:toView];
    }
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (presenting) {
            toView.frame = finalFrame;
            toView.alpha = 1;
            toView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } else {
            fromView.frame = initialFrame;
            fromView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        if (wasCancelled) {
            [toView removeFromSuperview];
        }
        [transitionContext completeTransition:!wasCancelled];
    }];
}

@end

#pragma mark - View Transition

@interface XCAlertBackgroundView : UIControl
@property (nonatomic, weak) UIView *customAlert;
@property (nonatomic, assign) UIEdgeInsets maskViewInsets;
@property (nonatomic, strong) UIControl *bgMaskView;
@end

@implementation XCAlertBackgroundView

- (UIControl *)bgMaskView {
    if (!_bgMaskView) {
        _bgMaskView = [UIControl new];
        _bgMaskView.userInteractionEnabled = YES;
        [self addSubview:_bgMaskView];
    }
    return _bgMaskView;
}

- (void)layoutSubviews {
    CGRect finalRect = CGRectZero;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(frameForViewContent)]) {
        finalRect = [(id<XCAlertContentProtocol>)self.customAlert frameForViewContent];
    }
    self.customAlert.frame = finalRect;
}

- (void)setMaskViewInsets:(UIEdgeInsets)maskViewInsets {
    [self.bgMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(maskViewInsets);
    }];
}

@end

static char *kCustomAlertBindViewTransitionKey = "kCustomAlertBindViewTransitionKey";

@interface XCAlertViewTransition : NSObject

- (instancetype)initWithCustomAlertView:(UIView *)customAlert onView:(UIView *)onView;

@property (nonatomic, assign) BOOL dismissTapOnTemp;

@property (nonatomic, assign) XCAlertAnimation animationStyle;

@property (nonatomic, assign) BOOL slideClose;

- (void)show;

- (void)dismiss;

- (void)setHidden:(BOOL)hidden;

- (void)setNeedsUpdateFrameWithAnimate:(BOOL)animate;

@end

@interface XCAlertViewTransition ()

@property (nonatomic, weak) UIView *customAlert;

@property (nonatomic, weak) UIView *onView;

@property (nonatomic, strong) XCAlertBackgroundView *backgroundView;

@end

@implementation XCAlertViewTransition

- (instancetype)initWithCustomAlertView:(UIView *)customAlert onView:(UIView *)onView {
    self = [super init];
    if (self) {
        _customAlert = customAlert;
        _onView = onView;
    }
    return self;
}

- (void)show {
    if (!self.customAlert) {
        return;
    }
    objc_setAssociatedObject(self.customAlert, kCustomAlertBindViewTransitionKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    XCAlertBackgroundView *backgroundView = [[XCAlertBackgroundView alloc] init];
    self.backgroundView = backgroundView;
    backgroundView.userInteractionEnabled = YES;
    backgroundView.clipsToBounds = YES;
    backgroundView.bgMaskView.clipsToBounds = YES;
    backgroundView.backgroundColor = [UIColor clearColor];
    [self.onView addSubview:backgroundView];
    [backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(insetsForMaskView)]) {
            UIEdgeInsets insets = [(id<XCAlertContentProtocol>)self.customAlert insetsForMaskView];
            // 设置不能穿透和没有设置，那么都是从顶部开始
            if ([self.customAlert respondsToSelector:@selector(canGestureRecognizerThroughTheMaskView)] && [(id<XCAlertContentProtocol>)self.customAlert canGestureRecognizerThroughTheMaskView]) {
                make.edges.mas_equalTo(insets);
            } else {
                make.edges.equalTo(self.onView);
            }
        } else {
            make.edges.equalTo(self.onView);
        }
    }];
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(insetsForMaskView)]) {
        UIEdgeInsets insets = [(id<XCAlertContentProtocol>)self.customAlert insetsForMaskView];
        // 明确设置不能穿透或没设置，那么都是不能穿透
        if ([self.customAlert respondsToSelector:@selector(canGestureRecognizerThroughTheMaskView)] && [(id<XCAlertContentProtocol>)self.customAlert canGestureRecognizerThroughTheMaskView]) {
            backgroundView.maskViewInsets = UIEdgeInsetsZero;
        } else {
            backgroundView.maskViewInsets = insets;
        }
    } else {
        backgroundView.maskViewInsets = UIEdgeInsetsZero;
    }
    [backgroundView.bgMaskView addSubview:self.customAlert];
    backgroundView.customAlert = self.customAlert;
    
    
    if (self.dismissTapOnTemp) {
        [backgroundView addTarget:self action:@selector(actionForTapOnTemp:) forControlEvents:UIControlEventTouchUpInside];
        [backgroundView.bgMaskView addTarget:self action:@selector(actionForTapOnTemp:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGRect finalRect = CGRectZero;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(frameForViewContent)]) {
        finalRect = [(id<XCAlertContentProtocol>)self.customAlert frameForViewContent];
    }
    
    NSTimeInterval duration = 0.25;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(animationDuration)]) {
        duration = [(id<XCAlertContentProtocol>)self.customAlert animationDuration];
    }
    
    UIColor *finalBackgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(animationTransitionColor)]) {
        finalBackgroundColor = [(id<XCAlertContentProtocol>)self.customAlert animationTransitionColor];
    }
    
    XCAlertAnimation animation = self.animationStyle;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(alertAnimation)]) {
        animation = [(id<XCAlertContentProtocol>)self.customAlert alertAnimation];
    }

    CGRect beginRect = finalRect;
    if (animation == XCAlertAnimationSheet) {
        beginRect.origin.y = CGRectGetHeight(self.onView.frame);
    } else if (animation == XCAlertAnimationPullDown) {
        beginRect.origin.y = CGRectGetMinY(self.onView.frame) - CGRectGetHeight(finalRect);
    }
    self.customAlert.frame = beginRect;
    if (animation == XCAlertAnimationPopAlert) {
        self.customAlert.alpha = 0;
        self.customAlert.transform = CGAffineTransformMakeScale(1.3, 1.3);
    }
    [UIView animateWithDuration:duration animations:^{
        self.backgroundView.bgMaskView.backgroundColor = finalBackgroundColor;
        self.customAlert.alpha = 1;
        self.customAlert.transform = CGAffineTransformMakeScale(1.0, 1.0);
        self.customAlert.frame = finalRect;
    } completion:^(BOOL finished) {
        if ([self.customAlert respondsToSelector:@selector(alertDidShow)]) {
            [((id<XCAlertContentProtocol>)self.customAlert) alertDidShow];
        }
    }];
}

- (void)dismiss {
    CGRect finalRect = CGRectZero;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(frameForViewContent)]) {
        finalRect = [(id<XCAlertContentProtocol>)self.customAlert frameForViewContent];
    }
    
    NSTimeInterval duration = 0.25;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(animationDuration)]) {
        duration = [(id<XCAlertContentProtocol>)self.customAlert animationDuration];
    }
    
    XCAlertAnimation animation = self.animationStyle;
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(alertAnimation)]) {
        animation = [(id<XCAlertContentProtocol>)self.customAlert alertAnimation];
    }

    if (animation == XCAlertAnimationSheet) {
        finalRect.origin.y += finalRect.size.height;
    } else if (animation == XCAlertAnimationPullDown) {
        finalRect.origin.y -= finalRect.size.height;
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.backgroundView.bgMaskView.backgroundColor = [UIColor clearColor];
        self.customAlert.frame = finalRect;
        if (animation == XCAlertAnimationPopAlert) {
            self.customAlert.alpha = 0;
        }
    } completion:^(BOOL finished) {
        [self.customAlert removeFromSuperview];
        [self.backgroundView removeFromSuperview];
        if ([self.customAlert respondsToSelector:@selector(alertDidDismiss)]) {
            [((id<XCAlertContentProtocol>)self.customAlert) alertDidDismiss];
        }
    }];
}

- (void)setHidden:(BOOL)hidden {
    self.backgroundView.hidden = hidden;
}

- (void)actionForTapOnTemp:(UIControl *)control {
    [self dismiss];
}

- (void)setNeedsUpdateFrameWithAnimate:(BOOL)animate {
    if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)] && [self.customAlert respondsToSelector:@selector(frameForViewContent)]) {
        CGRect rect = [(id<XCAlertContentProtocol>)self.customAlert frameForViewContent];
        NSTimeInterval duration = 0;
        if (animate) {
            if ([self.customAlert conformsToProtocol:@protocol(XCAlertContentProtocol)]
                && [self.customAlert respondsToSelector:@selector(setNeedsUpdateFrameAnimationDuration)]) {
                duration = [(id<XCAlertContentProtocol>)self.customAlert setNeedsUpdateFrameAnimationDuration];
            } else {
                duration = 0.25;
            }
        }
        [UIView animateWithDuration:duration animations:^{
            self.customAlert.frame = rect;
        }];
    }
}

@end


#pragma mark - Alert Action

@implementation XCAlertAction

@end


#pragma mark - Alert Maker

@interface XCAlertMaker ()<UIViewControllerTransitioningDelegate>

- (instancetype)initWithAlertStyle:(XCAlertControllerStyle)style;
- (instancetype)initWithAlertStyle:(XCAlertControllerStyle)style
                            custom:(id<XCAlertContentProtocol>)viewController;

@property (nonatomic, readonly) XCAlertControllerStyle alertStyle;

@property (nonatomic, strong) NSString *title_;

@property (nonatomic, strong) NSString *message_;

@property (nonatomic) BOOL dimissTapOnTemp_;

@property (nonatomic) XCAlertAnimation animationStyle_;

@property (nonatomic) BOOL slideClose_;

@property (nonatomic, strong) NSMutableArray *actions;

@property (nonatomic, strong) XCPresentTransition *presentTransition;

@property (nonatomic, strong) XCAlertViewTransition *viewTransition;

@property (nonatomic, strong) id<XCAlertContentProtocol> customAlert;

@end

@implementation XCAlertMaker

- (void)dealloc {
    NSLog(@"XCAlertMaker dealloc");
}

- (NSMutableArray *)actions {
    if (!_actions) {
        _actions = [NSMutableArray array];
    }
    return _actions;
}

+ (XCAlertMaker *)alert {
    return [[XCAlertMaker alloc] initWithAlertStyle:XCAlertControllerStyleAlert];
}

+ (XCAlertMaker *)sheet {
    return [[XCAlertMaker alloc] initWithAlertStyle:XCAlertControllerStyleSheet];
}

- (instancetype)initWithAlertStyle:(XCAlertControllerStyle)style {
    return [self initWithAlertStyle:style custom:nil];
}

- (instancetype)initWithAlertStyle:(XCAlertControllerStyle)style custom:(id<XCAlertContentProtocol>)customAlert {
    if (self = [super init]) {
        _alertStyle = style;
        _customAlert = customAlert;
        _dimissTapOnTemp_ = style == XCAlertControllerStyleSheet;
        _animationStyle_ = XCAlertAnimationPopAlert;
    }
    return self;
}

- (XCAlertMaker * (^)(NSString *))title {
    XCAlertMaker *(^maker)(NSString *) = ^XCAlertMaker *(NSString *x) {
        self.title_ = x;
        return self;
    };
    return maker;
}

- (XCAlertMaker * (^)(NSString *))message {
    XCAlertMaker *(^maker)(NSString *) = ^XCAlertMaker *(NSString *x) {
        self.message_ = x;
        return self;
    };
    return maker;
}

- (XCActionBlock)addDestructiveAction {
    XCAlertMaker *(^maker)(NSString *, void(^)(void)) = ^XCAlertMaker *(NSString *x, void(^b)(void)) {
        XCAlertAction *a = [[XCAlertAction alloc] init];
        a.title = x;
        a.action = b;
        a.actionStyle = XCAlertActionStyleDestructive;
        [self.actions addObject:a];
        return self;
    };
    return maker;
}

- (XCActionBlock)addDefaultAction {
    XCAlertMaker *(^maker)(NSString *, void(^)(void)) = ^XCAlertMaker *(NSString *x, void(^b)(void)) {
        XCAlertAction *a = [[XCAlertAction alloc] init];
        a.title = x;
        a.action = b;
        a.actionStyle = XCAlertActionStyleDefault;
        [self.actions addObject:a];
        return self;
    };
    return maker;
}

- (XCActionBlock)addForbidAction {
    XCAlertMaker *(^maker)(NSString *, void(^)(void)) = ^XCAlertMaker *(NSString *x, void(^b)(void)) {
        XCAlertAction *a = [[XCAlertAction alloc] init];
        a.title = x;
        a.action = b;
        a.actionStyle = XCAlertActionStyleForbid;
        [self.actions addObject:a];
        return self;
    };
    return maker;
}

- (XCActionBlock)addCancelAction {
    XCAlertMaker *(^maker)(NSString *, void(^)(void)) = ^XCAlertMaker *(NSString *x, void(^b)(void)) {
        XCAlertAction *a = [[XCAlertAction alloc] init];
        a.title = x;
        a.action = b;
        a.actionStyle = XCAlertActionStyleCancel;
        [self.actions addObject:a];
        return self;
    };
    return maker;
}

- (XCCustomActionBlock)addCustomAction {
    XCAlertMaker *(^maker)(NSString *,id, void(^)(void)) = ^XCAlertMaker *(NSString *x, id obj, void(^b)(void)) {
        XCAlertAction *a = [[XCAlertAction alloc] init];
        a.title = x;
        a.action = b;
        a.object = obj;
        a.actionStyle = XCAlertActionStyleCustom;
        [self.actions addObject:a];
        return self;
    };
    return maker;
}

- (void (^)(id _Nonnull))presentFrom {
    void (^maker)(id) = ^(id from) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *x = nil;
            UIView *v = nil;
            if ([from isKindOfClass:[UIViewController class]]) {
                x = (UIViewController *)from;
            } else if ([from isKindOfClass:[UIView class]]) {
                v = (UIView *)from;
            } else {
                return;
            }
            if (self.alertStyle == XCAlertControllerStyleSheet) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title_ message:self.message_ preferredStyle:UIAlertControllerStyleActionSheet];
                if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                    UIPopoverPresentationController *pop = [alert popoverPresentationController];
                    pop.permittedArrowDirections = UIPopoverArrowDirectionUp;
                    pop.sourceView = x.view;
                    pop.sourceRect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width , 0);
                }
                
                for (int i = 0; i < self.actions.count; i++) {
                    XCAlertAction *a = self.actions[i];
                    UIAlertActionStyle style = UIAlertActionStyleDefault;
                    if (a.actionStyle == XCAlertActionStyleDestructive) {
                        style = UIAlertActionStyleDestructive;
                    } else if (a.actionStyle == XCAlertActionStyleDefault) {
                        style = UIAlertActionStyleDefault;
                    } else if (a.actionStyle == XCAlertActionStyleForbid) {
                        
                    } else {
                        style = UIAlertActionStyleCancel;
                    }
                    UIAlertAction *action = [UIAlertAction actionWithTitle:a.title style:style handler:^(UIAlertAction * _Nonnull action) {
                        if (a.action) {
                            a.action();
                        }
                    }];
                    [alert addAction:action];
                }
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:cancel];
                
                float delay = 0;
                if (x.presentedViewController) {
                    delay = kPresentDelay;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self getp_vcFrom:x] presentViewController:alert animated:YES completion:nil];
                });
            } else if (self.alertStyle == XCAlertControllerStyleAlert) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.title_ message:self.message_ preferredStyle:UIAlertControllerStyleAlert];
                
                for (int i = 0; i < self.actions.count; i++) {
                    XCAlertAction *a = self.actions[i];
                    UIAlertActionStyle style = UIAlertActionStyleDefault;
                    if (a.actionStyle == XCAlertActionStyleDestructive) {
                        style = UIAlertActionStyleDestructive;
                    } else if (a.actionStyle == XCAlertActionStyleDefault) {
                        style = UIAlertActionStyleDefault;
                    } else if (a.actionStyle == XCAlertActionStyleForbid) {
                        
                    } else {
                        style = UIAlertActionStyleCancel;
                    }
                    UIAlertAction *action = [UIAlertAction actionWithTitle:a.title style:style handler:^(UIAlertAction * _Nonnull action) {
                        if (a.action) {
                            a.action();
                        }
                    }];
                    [alert addAction:action];
                }
                float delay = 0;
                if (x.presentedViewController) {
                    delay = kPresentDelay;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self getp_vcFrom:x] presentViewController:alert animated:YES completion:nil];
                });
            } else {
                // custom alert
                if ([self.customAlert isKindOfClass:[UIViewController class]]) {
                    if ([self.customAlert respondsToSelector:@selector(installWithTitle:message:actions:)]) {
                        [self.customAlert installWithTitle:self.title_ message:self.message_ actions:self.actions.copy];
                    }
                    UIViewController *alert = (UIViewController *)self.customAlert;
                    self.presentTransition = [[XCPresentTransition alloc] initWithPresentedViewController:alert presentingViewController:x style:self.alertStyle];
                    self.presentTransition.dismissTapOnTemp = self.dimissTapOnTemp_;
                    self.presentTransition.animationStyle = self.animationStyle_;
                    float delay = 0;
                    if (x.presentedViewController) {
                        delay = kPresentDelay;
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        alert.transitioningDelegate = self.presentTransition;
                        [[self getp_vcFrom:x] presentViewController:alert animated:YES completion:nil];
                    });
                } else if ([self.customAlert isKindOfClass:[UIView class]]) {
                    if ([self.customAlert respondsToSelector:@selector(installWithTitle:message:actions:)]) {
                        [self.customAlert installWithTitle:self.title_ message:self.message_ actions:self.actions.copy];
                    }
                    UIView *onView = x ? x.view : v;
                    self.viewTransition = [[XCAlertViewTransition alloc] initWithCustomAlertView:(UIView *)self.customAlert onView:onView];
                    self.viewTransition.dismissTapOnTemp = self.dimissTapOnTemp_;
                    self.viewTransition.animationStyle = self.animationStyle_;
                    self.viewTransition.slideClose = self.slideClose_;
                    [self.viewTransition show];
                }
            }
        });
    };
    return maker;
}

- (UIViewController *)getp_vcFrom:(UIViewController *)x {
    UIViewController *p = x;
    while (p) {
        UIViewController *x_p = p.presentedViewController;
        if (!x_p) {
            break;
        }
        p = x_p;
    }
    return p;
}

- (void)dismissAlert {
    if (self.viewTransition) {
        [self.viewTransition dismiss];
    }
    if (self.presentTransition) {
        [self.presentTransition dismiss];
    }
}

@end

@implementation XCAlertMaker (XCAlertCustom)

+ (XCAlertCustom)custom {
    return ^XCAlertMaker *(id<XCAlertContentProtocol> x) {
        XCAlertMaker *maker = [[XCAlertMaker alloc] initWithAlertStyle:XCAlertControllerStyleCustom custom:x];
        return maker;
    };
}

/// 默认是点击空白处不会消失的
- (XCAlertMaker * (^)(BOOL))dimissTapOnTemp {
    XCAlertMaker *(^maker)(BOOL) = ^XCAlertMaker *(BOOL x) {
        self.dimissTapOnTemp_ = x;
        return self;
    };
    return maker;
}

- (XCAlertMaker * (^)(XCAlertAnimation))animationStyle {
    XCAlertMaker *(^maker)(XCAlertAnimation) = ^XCAlertMaker *(XCAlertAnimation x) {
        self.animationStyle_ = x;
        return self;
    };
    return maker;
}

- (XCAlertMaker * _Nonnull (^)(BOOL))slideClose {
    XCAlertMaker *(^maker)(BOOL) = ^XCAlertMaker *(BOOL slideClose) {
        self.slideClose_ = slideClose;
        return  self;
    };
    return maker;
}

@end

#pragma mark - Controller Present caegory

@implementation UIViewController (XCAlertPresent)

- (XCAlertMaker *)XC_alertMaker {
    XCAlertMaker *maker = [[XCAlertMaker alloc] initWithAlertStyle:XCAlertControllerStyleCustom custom:(id<XCAlertContentProtocol>)self];
    return maker;
}

- (XCAlertMaker *)XC_presentFrom:(UIViewController *)from {
    XCAlertMaker *maker = self.XC_alertMaker;
    maker.presentFrom(from);
    return maker;
}

- (void)XC_dismissToPresent:(void (^)(UIViewController * _Nonnull))present {
    __weak typeof(self.presentingViewController) w_p = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        __strong typeof(w_p) s_p = w_p;
        if (!s_p) return;
        if (present) {
            present(s_p);
        }
    }];
}

- (void)XC_setNeedsUpdateFrameOfContentViewWithAnimate:(BOOL)animate {
    if ([self respondsToSelector:@selector(frameForViewContent)]) {
        objc_setAssociatedObject(self, kSetNeedsUpdateFrameKey, @(animate), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // 强制触发‘containerViewDidLayoutSubviews’，直接调用‘setNeedsLayout’无效果
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width + 1, self.view.frame.size.height);
    }
}

@end


@implementation UIView (XCAlertPresent)

- (void)XC_dismissAlertView {
    XCAlertViewTransition *t = objc_getAssociatedObject(self, kCustomAlertBindViewTransitionKey);
    if (t) {
        [t dismiss];
    }
}

- (void)XC_setAlertViewHidden:(BOOL)hidden {
    XCAlertViewTransition *t = objc_getAssociatedObject(self, kCustomAlertBindViewTransitionKey);
    if (t) {
        [t setHidden:hidden];
    }
}

- (void)XC_setNeedsUpdateFrameOfContentViewWithAnimate:(BOOL)animate {
    XCAlertViewTransition *t = objc_getAssociatedObject(self, kCustomAlertBindViewTransitionKey);
    if (t) {
        [t setNeedsUpdateFrameWithAnimate:animate];
    }
}

@end

