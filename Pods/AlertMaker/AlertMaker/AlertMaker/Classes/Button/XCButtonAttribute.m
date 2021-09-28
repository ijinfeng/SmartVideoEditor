//
//  XCButtonAttribute.m
//  BundleFastlane
//
//  Created by jinfeng on 2020/8/31.
//  Copyright © 2020 jinfeng. All rights reserved.
//

#import "XCButtonAttribute.h"

@implementation XCButtonAttribute

- (instancetype)init {
    self = [super init];
    if (self) {
        self.font = [self getPingFangSCMediumFont:16];
        self.minimumSpace = 4;
    }
    return self;
}

- (UIFont *)getPingFangSCRegularFont:(CGFloat)fontSize {
    UIFont *font = nil;
    if (@available(iOS 9.0, *)) {
        font = [UIFont fontWithName:@"PingFangSC-Regular" size:fontSize];
    } else if (@available(iOS 8.2, *)) {
        font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
    } else {
        font = [UIFont systemFontOfSize:fontSize];
    }
    return font;
}

- (UIFont *)getPingFangSCMediumFont:(CGFloat)fontSize {
    UIFont *font = nil;
    if (@available(iOS 9.0, *)) {
        font = [UIFont fontWithName:@"PingFangSC-Medium" size:fontSize];
    } else if (@available(iOS 8.2, *)) {
        font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];
    } else {
        font = [UIFont systemFontOfSize:fontSize];
    }
    return font;
}


@end
