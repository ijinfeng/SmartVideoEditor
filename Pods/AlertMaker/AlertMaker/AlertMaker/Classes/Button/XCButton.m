//
//  XCButton.m
//  BundleFastlane
//
//  Created by jinfeng on 2020/8/31.
//  Copyright © 2020 jinfeng. All rights reserved.
//

#import "XCButton.h"
#import <objc/runtime.h>

@interface XCButton ()
@property (nonatomic, strong) CAGradientLayer *backgroundLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) XCButtonAttribute *attribute;
@property (nonatomic, strong) CALayer *pressMaskLayer;
@property (nonatomic, strong) NSLayoutConstraint *titleLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint *titleRightConstraint;
@end

@implementation XCButton

- (void)dealloc {
    NSLog(@"XCButton dealloc<%@>",self);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self createAttribute];
    }
    return self;
}

- (XCButton *)createAttribute {
    if (!self.attribute) {
        self.attribute = [[[self.class buttonAttributeClass] alloc] init];
        self.attribute.backgroundLayer = self.backgroundLayer;
    }
    self.layer.masksToBounds = YES;
    self.autoClipsRound = YES;
    [self buildWithLevelAttribute];
    return self;
}

- (void)buildWithLevelAttribute {
    [self setNormalStyle];
    self.titleLabel.text = self.attribute.title;
    self.titleLabel.font = self.attribute.font;
    self.layer.borderWidth = self.attribute.borderLineColor ? 1.0 / [UIScreen mainScreen].scale : 0;
    [self addTitleConstraints];
}

- (void)addTitleConstraints {
    if (self.titleLeftConstraint == nil && self.titleLabel.superview) {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:self.attribute.minimumSpace];
        self.titleLeftConstraint = left;
        NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-self.attribute.minimumSpace];
        self.titleRightConstraint = right;
        [self addConstraints:@[top,bottom, left,right]];
    }
    self.titleLeftConstraint.constant = self.attribute.minimumSpace;
    self.titleRightConstraint.constant = -self.attribute.minimumSpace;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.attribute.title = title;
    self.titleLabel.text = title;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if (enabled) {
        [self setNormalStyle];
    } else {
        [self setDisableStyle];
    }
}

- (XCButtonActionBlock)addTapAction {
    XCButton *(^button)(void(^action)(XCButton *)) = ^XCButton *(void(^action)(XCButton *)) {
        [self addTarget:self action:@selector(actionForTap:) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, _cmd, action, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
    return button;
}


- (void)setCustomAttribute:(void (^)(XCButtonAttribute * _Nonnull attribute))maker {
    if (maker) {
        if (!self.attribute) {
            [self createAttribute];
        }
        maker(self.attribute);
        [self buildWithLevelAttribute];
    }
}

- (void)bindCustomAttribute:(XCButtonAttribute *)attribute {
    if (!attribute) {
        return;
    }
    self.attribute = attribute;
    self.attribute.title = self.titleLabel.text;
    self.attribute.backgroundLayer = self.backgroundLayer;
    [self buildWithLevelAttribute];
}

#pragma mark -- Action

- (void)actionForTap:(XCButton *)button {
    void(^action)(XCButton *) = objc_getAssociatedObject(self, @selector(addTapAction));
    if (action) {
        action(self);
    }
}

#pragma mark -- Press

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self setPressStyle];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.enabled) {
        [self setNormalStyle];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if (self.enabled) {
        [self setNormalStyle];
    }
}

- (void)setPressStyle {
    if (self.attribute.pressBackgroundColors.count == 0) {
        self.backgroundColor = [UIColor whiteColor];
    } else if (self.attribute.pressBackgroundColors.count == 1) {
        self.backgroundLayer.colors = nil;
        id color = self.attribute.pressBackgroundColors.firstObject;
        if ([color isKindOfClass:[UIColor class]]) {
            self.backgroundColor = color;
        } else {
            self.backgroundColor = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(color)];
        }
    } else {
        NSMutableArray *colors = [NSMutableArray array];
        for ( id color in self.attribute.pressBackgroundColors) {
            if ([color isKindOfClass:[UIColor class]]) {
                [colors addObject:(id)((UIColor *)color).CGColor];
            } else {
                [colors addObject:color];
            }
        }
        self.backgroundLayer.colors = colors;
    }
    self.titleLabel.textColor = self.attribute.pressTextColor;
    self.layer.borderColor = self.attribute.pressBorderLineColor.CGColor;
    self.pressMaskLayer.backgroundColor = self.attribute.pressMaskColor.CGColor;
    [self.layer addSublayer:self.pressMaskLayer];
    self.alpha = 1;
}

- (void)setNormalStyle {
    if (self.attribute.backgroundColors.count == 0) {
        self.backgroundColor = [UIColor whiteColor];
        self.backgroundLayer.colors = nil;
    } else if (self.attribute.backgroundColors.count == 1) {
        self.backgroundLayer.colors = nil;
        id color = self.attribute.backgroundColors.firstObject;
        if ([color isKindOfClass:[UIColor class]]) {
            self.backgroundColor = color;
        } else {
            self.backgroundColor = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(color)];
        }
    } else {
        NSMutableArray *colors = [NSMutableArray array];
        for ( id color in self.attribute.backgroundColors) {
            if ([color isKindOfClass:[UIColor class]]) {
                [colors addObject:(id)((UIColor *)color).CGColor];
            } else {
                [colors addObject:color];
            }
        }
        self.backgroundLayer.colors = colors;
    }
    self.titleLabel.textColor = self.attribute.textColor;
    self.layer.borderColor = self.attribute.borderLineColor.CGColor;
    [self.pressMaskLayer removeFromSuperlayer];
    self.alpha = 1;
}

- (void)setDisableStyle {
    if (self.attribute.disableBackgroundColors.count == 0) {
        self.backgroundColor = [UIColor whiteColor];
    } else if (self.attribute.disableBackgroundColors.count == 1) {
        self.backgroundLayer.colors = nil;
        id color = self.attribute.disableBackgroundColors.firstObject;
        if ([color isKindOfClass:[UIColor class]]) {
            self.backgroundColor = color;
        } else {
            self.backgroundColor = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(color)];
        }
    } else {
        NSMutableArray *colors = [NSMutableArray array];
        for ( id color in self.attribute.disableBackgroundColors) {
            if ([color isKindOfClass:[UIColor class]]) {
                [colors addObject:(id)((UIColor *)color).CGColor];
            } else {
                [colors addObject:color];
            }
        }
        self.backgroundLayer.colors = colors;
    }
    self.titleLabel.textColor = self.attribute.disableTextColor;
    self.layer.borderColor = self.attribute.disableBorderLineColor.CGColor;
    self.alpha = self.attribute.disalbeAlpha;
}

#pragma mark -- Layout

- (void)layoutSubviews {
    if (self.autoClipsRound) {
        self.layer.cornerRadius = self.frame.size.height / 2.0;
    }
    self.backgroundLayer.frame = self.bounds;
    self.pressMaskLayer.frame = self.bounds;
}

#pragma mark - Get

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (CAGradientLayer *)backgroundLayer {
    if (!_backgroundLayer) {
        _backgroundLayer = [[CAGradientLayer alloc] init];
        _backgroundLayer.locations = @[@(0), @(1)];
        _backgroundLayer.startPoint = CGPointMake(0.00, 0.50);
        _backgroundLayer.endPoint = CGPointMake(1.00, 0.50);
        [self.layer insertSublayer:_backgroundLayer atIndex:0];
    }
    return _backgroundLayer;
}

- (CALayer *)pressMaskLayer {
    if (!_pressMaskLayer) {
        _pressMaskLayer = [CALayer new];
    }
    return _pressMaskLayer;
}

+ (Class)buttonAttributeClass {
    return XCButtonAttribute.class;
}

@end
