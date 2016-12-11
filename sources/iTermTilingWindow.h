//
//  iTermTilingWindow.h
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import <Foundation/Foundation.h>
#import "iTermWeakReference.h"
#import "PseudoTerminal.h"
#import "iTermTilingFrame.h"

@class iTermTilingWindow;
@class iTermTilingFrame;

@interface iTermTilingWindowBorder : NSView

@property (retain) iTermTilingWindow *tilingWindow;
@property (assign) int borderWidth;
@property (retain) NSColor *borderColor;

- (id)initWithFrame:(CGRect)frame forTilingWindow:(iTermTilingWindow *)window;

@end


@interface iTermTilingWindow : NSObject

@property (retain) PseudoTerminal<iTermWeakReference> *terminal;
@property (retain) iTermTilingFrame *frame;
@property (retain) iTermTilingWindowBorder *border;
@property BOOL focused;
@property int number;

- (id)initForTerminal:(PseudoTerminal *)terminal frame:(iTermTilingFrame *)frame number:(int)number;
- (void)adjustToFrame;
- (void)focusAndMakeKey:(BOOL)key;
- (void)unfocus;

@end
