//
//  iTermTilingManager.h
//  iTerm2
//
//  Created by joshua stein on 12/1/16.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "iTermTilingFrame.h"

@class iTermTilingFrame;

typedef NS_ENUM(NSInteger, iTermTilingFrameDirection) {
        iTermTilingFrameDirectionLeft,
        iTermTilingFrameDirectionRight,
        iTermTilingFrameDirectionAbove,
        iTermTilingFrameDirectionBelow,
};

@interface iTermTilingManager : NSObject

@property (assign) NSMutableArray<iTermTilingFrame *> *frames;
@property (assign) NSColor *activeFrameBorderColor;
@property (assign) NSColor *inactiveFrameBorderColor;
@property int borderWidth;
@property int gap;
@property BOOL showingFrameNumbers;

+ (instancetype)sharedInstance;
- (iTermTilingFrame *)currentFrame;
- (void)setCurrentFrame:(iTermTilingFrame *)newCur;
- (BOOL)handleAction:(int)action;

@end
