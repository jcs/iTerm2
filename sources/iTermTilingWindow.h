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

@class iTermTilingFrame;
@class iTermTilingWindow;

@interface iTermTilingWindowBorder : NSView

@property (retain) iTermTilingWindow *tilingWindow;
@property (assign) int borderWidth;
@property (retain) NSColor *borderColor;

- (id)initWithFrame:(CGRect)frame forTilingWindow:(iTermTilingWindow *)window;

@end


@interface iTermTilingWindow : NSObject

@property (nonatomic, retain) PseudoTerminal<iTermWeakReference> *terminal;
@property (nonatomic, retain) iTermTilingFrame *frame;
@property (retain) iTermTilingWindowBorder *border;
@property BOOL focused;
- (id)initForTerminal:(PseudoTerminal *)terminal;
- (void)adjustToFrame;
- (void)focusAndMakeKey:(BOOL)key;
- (void)unfocus;

@end
