//
//  XCCustomSheetView.m
//  lib-ui
//
//  Created by jinfeng on 2021/1/29.
//

#import "XCCustomSheetView.h"
#import "XCNormalButton.h"
#import "XCCustomUIHelper.h"
#import "XCCustomUISetting.h"

@interface XCCustomSheetView ()
@property (nonatomic, assign) XCCustomAlertUIStyle style;
@property (nonatomic, strong) UIView *topContentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *buttonsView;
@property (nonatomic, strong) NSMutableArray *hLines;
@property (nonatomic, strong) UIView *cancelButtonView;
@property (nonatomic, strong) XCNormalButton *cancelButton;
@end

@implementation XCCustomSheetView

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
    self.topContentView = [UIView new];
    self.topContentView.backgroundColor = [XCCustomUIHelper backgroundColorWithStyle:self.style];
    self.topContentView.layer.cornerRadius = 10;
    self.topContentView.layer.masksToBounds = YES;
    [self addSubview:self.topContentView];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:16  weight:UIFontWeightMedium];
    self.titleLabel.textColor = [XCCustomUIHelper titleColorWithStyle:self.style];
    self.titleLabel.numberOfLines = 0;
    [self.topContentView addSubview:self.titleLabel];
    
    self.contentLabel = [UILabel new];
    self.contentLabel.textAlignment = NSTextAlignmentCenter;
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.font = [UIFont systemFontOfSize:14 ];
    self.contentLabel.textColor = [XCCustomUIHelper contentColorWithStyle:self.style];
    [self.topContentView addSubview:self.contentLabel];
    
    self.buttonsView = [UIView new];
    [self.topContentView addSubview:self.buttonsView];
    
    self.cancelButtonView = [UIView new];
    self.cancelButtonView.backgroundColor = self.topContentView.backgroundColor;
    self.cancelButtonView.layer.cornerRadius = 10;
    self.cancelButtonView.layer.masksToBounds = YES;
    [self addSubview:self.cancelButtonView];
}

- (XCNormalButton *)createButtonWithAction:(XCAlertAction *)action {
    XCNormalButton *button = [XCNormalButton new];
    button.autoClipsRound = NO;
    button.title = action.title;
    [button setCustomAttribute:^(XCButtonAttribute * _Nonnull attribute) {
        attribute.font = [UIFont systemFontOfSize:16 ];
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
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.titleLabel.font} context:nil].size;
    CGSize contentSize = [self.contentLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.contentLabel.font} context:nil].size;
    self.titleLabel.frame = CGRectMake((width - titleSize.width) / 2, 10  , titleSize.width, titleSize.height);
    CGFloat space = (titleSize.height > 0 && contentSize.height > 0) ? 8 : 0;
    self.contentLabel.frame = CGRectMake((width - contentSize.width) / 2, CGRectGetMaxY(self.titleLabel.frame) + space, contentSize.width, contentSize.height);
    CGFloat buttonsView_y = 0;
    if (titleSize.height > 0 || contentSize.height > 0) {
        buttonsView_y += 10  ;
        buttonsView_y += titleSize.height;
        buttonsView_y += contentSize.height;
        if (titleSize.height > 0 && contentSize.height > 0) {
            buttonsView_y += 8  ;
        }
        buttonsView_y += 10  ;
    }
    self.buttonsView.frame = CGRectMake(0, buttonsView_y, width, self.buttonsView.subviews.count * 44  );
    self.topContentView.frame = CGRectMake(0, 0, width, CGRectGetMaxY(self.buttonsView.frame));
    self.cancelButtonView.frame = CGRectMake(0, CGRectGetMaxY(self.topContentView.frame) + 10  , width, 44  );
    self.cancelButton.frame = self.cancelButtonView.bounds;
    CGFloat button_y = 0;
    for (int i = 0; i < self.buttonsView.subviews.count; i++) {
        UIView *button = self.buttonsView.subviews[i];
        button.frame = CGRectMake(0, button_y, width, 44  );
        button_y += 44  ;
    }
    for (UIView *hLine in self.hLines) {
        hLine.frame = CGRectMake(0, 0, width, 1);
    }
}

#pragma mark -- XCAlertContentProtocol

- (void)installWithTitle:(NSString *)title message:(NSString *)message actions:(NSArray<XCAlertAction *> *)actions {
    self.titleLabel.text = title;
    self.contentLabel.text = message;
    [self.buttonsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.hLines removeAllObjects];
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;
    self.cancelButtonView.hidden = YES;
    __weak typeof(self) weakSelf = self;
    for (XCAlertAction *action in actions) {
        if (action.actionStyle == XCAlertActionStyleCancel) {
            self.cancelButtonView.hidden = NO;
            self.cancelButton = [self createButtonWithAction:action];
            [self.cancelButtonView addSubview:self.cancelButton];
            self.cancelButton.addTapAction(^(XCButton * _Nonnull button) {
                if (action.action) {
                    action.action();
                }
                [weakSelf XC_dismissAlertView];
            });
        } else {
            XCNormalButton *button = [self createButtonWithAction:action];
            [self.buttonsView addSubview:button];
            button.addTapAction(^(XCButton * _Nonnull button) {
                if (action.action) {
                    action.action();
                }
                [weakSelf XC_dismissAlertView];
            });
        }
    }
    if (title.length > 0 || message.length > 0 || self.buttonsView.subviews.count > 1) {
        for (int i = 0; i < self.buttonsView.subviews.count; i++) {
            UIView *button = self.buttonsView.subviews[i];
            UIView *hLine = [UIView new];
            hLine.backgroundColor = [XCCustomUIHelper lineColorWithStyle:self.style];
            [button addSubview:hLine];
            [self.hLines addObject:hLine];
        }
    }
}

- (CGRect)frameForViewContent {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat width = screenSize.width - 32  ;
    CGFloat height = 0;
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.titleLabel.font} context:nil].size;
    CGSize contentSize = [self.contentLabel.text boundingRectWithSize:CGSizeMake(width - 32  , CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.contentLabel.font} context:nil].size;
    if (titleSize.height > 0 || contentSize.height > 0) {
        height += 10  ;
        height += titleSize.height;
        height += contentSize.height;
        if (titleSize.height > 0 && contentSize.height > 0) {
            height += 8  ;
        }
        height += 10  ;
    }
    height += self.buttonsView.subviews.count * 44  ;
    height += self.cancelButton ? 44   : 0;
    if (self.cancelButton != nil && self.buttonsView.subviews.count > 0) {
        height += 10  ;
    }
    height += 16  ;
    if (@available(iOS 11.0, *)) {
        height += UIApplication.sharedApplication.windows.firstObject.safeAreaInsets.bottom;
    }
    return CGRectMake((screenSize.width - width) / 2, screenSize.height - height, width, height);
}

- (XCAlertAnimation)alertAnimation {
    return XCAlertAnimationSheet;
}

@end
