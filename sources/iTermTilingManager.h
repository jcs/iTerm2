//
//  iTermTilingManager.h
//  iTerm2
//
//  Created by joshua stein on 12/1/16.
//
//

#import <Foundation/Foundation.h>
#import "iTermWeakReference.h"
#import "PTYWindow.h"
#import "PseudoTerminal.h"

@interface iTermTilingFrameBorder : NSView
@property (retain) NSColor *borderColor;
@property (assign) CGFloat borderWidth;
@property (assign) CGFloat cornerRadius;
@end

@class iTermTilingWindow;

@interface iTermTilingFrame : NSObject
@property (retain) NSWindow *borderWindow;
@property (retain) iTermTilingFrameBorder *border;
@property (assign) CGRect rect;
@property (retain) NSMutableArray<iTermTilingWindow *> *windows;
- (id)initWithRect:(CGRect)rect;
- (void)addWindow:(iTermTilingWindow *)window;
- (void)removeWindow:(iTermTilingWindow *)window;
@end

@interface iTermTilingWindow : NSObject
@property (nonatomic, retain) PseudoTerminal<iTermWeakReference> *terminal;
@property (nonatomic, retain) iTermTilingFrame *frame;
- (id)initForTerminal:(PseudoTerminal *)terminal;
@end

@interface iTermTilingManager : NSObject
+ (instancetype)sharedInstance;
@end
