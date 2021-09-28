//
//  XCNormalButtonAttribute.m
//  lib-ui
//
//  Created by jinfeng on 2020/9/1.
//

#import "XCNormalButtonAttribute.h"

@implementation XCNormalButtonAttribute

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColors = nil;
        self.textColor = [UIColor colorWithRed:242/255.0 green:0 blue:0 alpha:1.0];
        self.borderLineColor = [UIColor colorWithRed:242/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
        self.pressTextColor = [UIColor colorWithRed:242/255.0 green:0 blue:0 alpha:1.0];
        self.pressBackgroundColors = @[(id)[UIColor colorWithRed:242/255.0 green:0/255.0 blue:0/255.0 alpha:0.05].CGColor];
        self.pressBorderLineColor = [UIColor colorWithRed:251/255.0 green:108/255.0 blue:108/255.0 alpha:1.0];
        self.pressMaskColor = nil;
        self.disableTextColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
        self.disableBorderLineColor = [UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
        self.disableBackgroundColors = @[[UIColor whiteColor]];
        self.disalbeAlpha = 0.3;
    }
    return self;
}

@end
