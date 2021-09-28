//
//  XCCustomAlertView.m
//  lib-ui
//
//  Created by jinfeng on 2021/1/29.
//

#import "XCCustomAlertView.h"
#import "XCNormalButton.h"
#import "XCCustomUISetting.h"
#import "XCCustomUIHelper.h"

@interface XCCustomAlertView ()
@property (nonatomic, assign) XCCustomAlertUIStyle style;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *vLine;
@property (nonatomic, strong) NSMutableArray *hLines;
@property (nonatomic, strong) NSMutableArray *buttonViews;
@property (nonatomic, strong) UIView *buttonContentView;
@end

@implementation XCCustomAlertView

- (NSMutableArray *)buttonViews {
    if (!_buttonViews) {
        _buttonViews = [NSMutableArray array];
    }
    return _buttonViews;
}

- (NSMutableArray *)hLines {
    if (!_hLines) {
        _hLines = [NSMutableArray array];
    }
    return _hLines;
}

- (instancetype)initWithStyle:(XCCustomAlertUIStyle)style {
    self = [super init];
    if (self) {
        _style = style;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [XCCustomUIHelper backgroundColorWithStyle:self.style];
    self.layer.cornerRadius = 10;
    self.layer.masksToBounds = YES;
    
    self.titleLabel = [UILabel new];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:16  weight:UIFontWeightMedium];
    self.titleLabel.textColor = [XCCustomUIHelper titleColorWithStyle:self.style];
    self.titleLabel.numberOfLines = 0;
    [self addSubview:self.titleLabel];
    
    self.contentLabel = [UILabel new];
    self.contentLabel.textAlignment = NSTextAlignmentCenter;
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.textColor = [XCCustomUIHelper contentColorWithStyle:self.style];
    [self addSubview:self.contentLabel];
    
    self.buttonContentView = [UIView new];
    self.buttonContentView.backgroundColor = [XCCustomUIHelper backgroundColorWithStyle:self.style];
    [self addSubview:self.buttonContentView];
    
    self.vLine = [UIView new];
    self.vLine.hidden = YES;
    self.vLine.backgroundColor = [XCCustomUIHelper lineColorWithStyle:self.style];
    [self addSubview:self.vLine];
}

- (XCNormalButton *)createButtonWithAction:(XCAlertAction *)action {
    XCNormalButton *button = [XCNormalButton new];
    button.autoClipsRound = NO;
    button.title = action.title;
    [button setCustomAttribute:^(XCButtonAttribute * _Nonnull attribute) {
        attribute.font = [UIFont systemFontOfSize:16  weight:UIFontWeightMedium];
        attribute.backgroundColors = @[[XCCustomUIHelper backgroundColorWithStyle:self.style]];
        attribute.borderLineColor = nil;
        attribute.pressBackgroundColors = @[[XCCustomUIHelper pressBackgroundColorWithStyle:self.style]];
        if (action.actionStyle == XCAlertActionStyleDestructive) {
            attribute.textColor = [XCCustomUIHelper destructiveColorWithStyle:self.style];
        } else if (action.actionStyle == XCAlertActionStyleCancel) {
            attribute.textColor = [XCCustomUIHelper cancelColorWithStyle:self.style];
        } else if (action.actionStyle == XCAlertActionStyleCustom) {
            XCCustomUISetting *setting = action.object;
            attribute.font = setting.font;
            attribute.textColor = setting.textColor;
        } else {
            attribute.textColor = [XCCustomUIHelper defaultColorWithStyle:self.style];
        }
        attribute.pressTextColor = [attribute.textColor colorWithAlphaComponent:0.8];
    }];
    return button;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize alertSize = [self frameForViewContent].size;
    CGFloat width = alertSize.width;
    CGFloat height = alertSize.height;
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.titleLabel.font} context:nil].size;
    CGSize contentSize = [self.contentLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.contentLabel.font} context:nil].size;
    self.titleLabel.frame = CGRectMake((width - titleSize.width) / 2, 20  , titleSize.width, titleSize.height);
    CGFloat space = (titleSize.height > 0 && contentSize.height > 0) ? 16   : 0;
    self.contentLabel.frame = CGRectMake((width - contentSize.width) / 2, CGRectGetMaxY(self.titleLabel.frame) + space, contentSize.width, contentSize.height);
    CGFloat buttonViewHeight = self.buttonViews.count > 2 ? 43   * self.buttonViews.count : 43  ;
    self.buttonContentView.frame = CGRectMake(0, height - buttonViewHeight, width, buttonViewHeight);
    self.vLine.frame = CGRectMake(width / 2, CGRectGetMinY(self.buttonContentView.frame), 1, CGRectGetHeight(self.buttonContentView.frame));
    if (self.buttonViews.count == 2) {
        UIView *leftButton = self.buttonViews.firstObject;
        UIView *rightButton = self.buttonViews.lastObject;
        leftButton.frame = CGRectMake(0, 0, CGRectGetWidth(self.buttonContentView.frame) / 2, CGRectGetHeight(self.buttonContentView.frame));
        rightButton.frame = CGRectMake(CGRectGetMaxX(leftButton.frame), 0, CGRectGetWidth(leftButton.frame), CGRectGetHeight(leftButton.frame));
    } else {
        CGFloat button_y = 0;
        for (int i = 0; i < self.buttonViews.count; i++) {
            UIView *button = self.buttonViews[i];
            button.frame = CGRectMake(0, button_y, CGRectGetWidth(self.buttonContentView.frame), 43  );
            button_y += 43  ;
        }
    }
    for (int i = 0; i < self.hLines.count; i++) {
        UIView *line = self.hLines[i];
        line.frame = CGRectMake(0, 0, width, 1);
    }
}

#pragma mark -- XCAlertContentProtocol

- (void)installWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<XCAlertAction *> *)actions {
    self.titleLabel.text = title;
    self.contentLabel.text = message;
    [self.buttonViews enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.buttonViews removeAllObjects];
    [self.hLines enumerateObjectsUsingBlock:^(UIView *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.hLines removeAllObjects];
    
    __weak typeof(self) weakSelf = self;
    if (actions.count == 2) {
        self.vLine.hidden = NO;
        XCAlertAction *leftAction = actions.firstObject;
        XCAlertAction *rightAction = actions.lastObject;
        XCNormalButton *leftButton = [self createButtonWithAction:leftAction];
        XCNormalButton *rightButton = [self createButtonWithAction:rightAction];
        [self.buttonContentView addSubview:leftButton];
        [self.buttonContentView addSubview:rightButton];
        leftButton.addTapAction(^(XCButton * _Nonnull button) {
            if (leftAction.action) {
                leftAction.action();
            }
            [weakSelf XC_dismissAlertView];
        });
        rightButton.addTapAction(^(XCButton * _Nonnull button) {
            if (rightAction.action) {
                rightAction.action();
            }
            [weakSelf XC_dismissAlertView];
        });
        [self.buttonViews addObject:leftButton];
        [self.buttonViews addObject:rightButton];
        UIView *line = [UIView new];
        line.backgroundColor = [XCCustomUIHelper lineColorWithStyle:self.style];
        [self.buttonContentView addSubview:line];
        [self.hLines addObject:line];
    } else {
        self.vLine.hidden = YES;
        for (int i = 0; i < actions.count; i++) {
            XCAlertAction *action = actions[i];
            XCNormalButton *button = [self createButtonWithAction:action];
            [self.buttonContentView addSubview:button];
            button.addTapAction(^(XCButton * _Nonnull button) {
                if (action.action) {
                    action.action();
                }
                [weakSelf XC_dismissAlertView];
            });
            [self.buttonViews addObject:button];
            UIView *line = [UIView new];
            line.backgroundColor = [XCCustomUIHelper lineColorWithStyle:self.style];
            [button addSubview:line];
            [self.hLines addObject:line];
        }
    }
}

- (CGRect)frameForViewContent {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = 270  ;
    CGFloat height = 0;
    
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.titleLabel.font} context:nil].size;
    CGSize contentSize = [self.contentLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.contentLabel.font} context:nil].size;
    height += 20  ;
    height += titleSize.height;
    height += contentSize.height;
    if (titleSize.height > 0 && contentSize.height > 0) {
        height += 16  ;
    }
    height += 19  ;
    if (self.buttonViews.count > 2) {
        height += self.buttonViews.count * 43  ;
    } else {
        height += 43  ;
    }
    return CGRectMake((screenSize.width - width) / 2, (screenSize.height - height) / 2, width, height);
}

- (XCAlertAnimation)alertAnimation {
    return XCAlertAnimationPopAlert;
}

@end
