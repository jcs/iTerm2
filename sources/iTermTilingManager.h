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
#import "iTermTilingWindow.h"

@class iTermTilingFrame;
@class iTermTilingWindow;

typedef NS_ENUM(NSInteger, iTermTilingFrameDirection) {
        iTermTilingFrameDirectionLeft,
        iTermTilingFrameDirectionRight,
        iTermTilingFrameDirectionAbove,
        iTermTilingFrameDirectionBelow,
};

@interface iTermTilingManager : NSObject

@property (assign) NSMutableArray<iTermTilingFrame *> *frames;
@property (retain) NSMutableArray<iTermTilingWindow *> *windows;
@property (assign) NSColor *activeFrameBorderColor;
@property (assign) NSColor *inactiveFrameBorderColor;
@property int borderWidth;
@property int gap;
@property BOOL showingFrameNumbers;

+ (instancetype)sharedInstance;
- (void)dumpFrames;
- (BOOL)startAdjustingFrames;
- (void)finishAdjustingFrames;
- (iTermTilingFrame *)currentFrame;
- (void)removeWindow:(iTermTilingWindow *)window;
- (void)setCurrentFrame:(iTermTilingFrame *)newCur;
- (BOOL)handleAction:(int)action;
- (NSArray <iTermTilingWindow *>*)windowsInFront;
- (NSArray <iTermTilingWindow *>*)windowsNotInFront;

@end
