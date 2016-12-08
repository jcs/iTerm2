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

@interface iTermTilingFrame : NSObject

@property (retain) iTermTilingManager *manager;
@property (assign, nonatomic) CGRect rect;
@property (retain) NSMutableArray<iTermTilingWindow *> *windows;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)_manager;
- (void)addWindow:(iTermTilingWindow *)window;
- (void)removeWindow:(iTermTilingWindow *)window;
- (void)unfocusFrontWindow;
- (void)focusFrontWindowAndMakeKey:(BOOL)key;
- (void)cycleWindowsForward:(BOOL)forward;
- (void)cycleLastWindow;
- (CGRect)rectForWindow;
- (void)redraw;

@end
