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

@class iTermTilingManager;
@class iTermTilingWindow;

@interface iTermTilingFrame : NSObject

@property (retain) iTermTilingManager *manager;
@property (assign, nonatomic) CGRect rect;
@property (retain) NSWindow *numberLabelHolder;
@property (retain) NSTextView *numberLabel;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)_manager;
- (NSArray<iTermTilingWindow *> *)windows;
- (iTermTilingWindow *)frontWindow;
- (void)unfocusFrontWindow;
- (void)focusFrontWindowAndMakeKey:(BOOL)key;
- (void)swapWithFrame:(iTermTilingFrame *)toFrame;
- (void)cycleWindowsForward:(BOOL)forward;
- (void)cycleLastWindow;
- (CGRect)rectForWindow;
- (void)redraw;

@end
