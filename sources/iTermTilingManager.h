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

@property BOOL actionMode;
@property (assign) NSMutableArray<iTermTilingFrame *> *frames;
@property (assign) NSColor *activeFrameBorderColor;
@property int borderWidth;
@property int cornerRadius;
@property int gap;

+ (instancetype)sharedInstance;
- (iTermTilingFrame *)currentFrame;
- (BOOL)downgradeKeyAction:(int)action;
- (BOOL)handleKeyEvent:(NSEvent *)event;

@end
