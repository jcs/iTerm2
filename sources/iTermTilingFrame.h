//
//  iTermTilingFrame.h
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "iTermTilingManager.h"
#import "iTermTilingWindow.h"

@class iTermTilingWindow;
@class iTermTilingManager;

@interface iTermTilingFrameBorder : NSView
@property (assign) int borderWidth;
@property (assign) int cornerRadius;
@property (retain) NSColor *borderColor;
@end

@interface iTermTilingFrame : NSObject

@property (retain) iTermTilingManager *manager;
@property (retain) NSWindow *borderWindow;
@property (retain) iTermTilingFrameBorder *border;
@property (assign, nonatomic) CGRect rect;
@property (retain) NSMutableArray<iTermTilingWindow *> *windows;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)_manager;
- (void)addWindow:(iTermTilingWindow *)window;
- (void)removeWindow:(iTermTilingWindow *)window;
- (CGRect)rectForWindow;
- (void)horizontalSplit;
- (void)verticalSplit;
- (void)redraw;

@end
