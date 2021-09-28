//
//  XCCustomSheetView.h
//  lib-ui
//
//  Created by jinfeng on 2021/1/29.
//

#import <UIKit/UIKit.h>
#import "XCAlertMaker.h"
#import "XCCustomAlertMaker.h"

NS_ASSUME_NONNULL_BEGIN

@interface XCCustomSheetView : UIView<XCAlertContentProtocol>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStyle:(XCCustomAlertUIStyle)style;

@end

NS_ASSUME_NONNULL_END
