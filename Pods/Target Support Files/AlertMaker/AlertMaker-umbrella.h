#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "XCButton.h"
#import "XCButtonAttribute.h"
#import "XCNormalButton.h"
#import "XCNormalButtonAttribute.h"
#import "UIColor+XCAlertColor.h"
#import "XCAlertContentProtocol.h"
#import "XCAlertMaker.h"
#import "XCCustomAlertMaker.h"
#import "XCCustomAlertView.h"
#import "XCCustomSheetView.h"
#import "XCCustomUIHelper.h"
#import "XCCustomUISetting.h"

FOUNDATION_EXPORT double AlertMakerVersionNumber;
FOUNDATION_EXPORT const unsigned char AlertMakerVersionString[];

