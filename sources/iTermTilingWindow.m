//
//  iTermTilingWindow.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingWindow.h"

@implementation iTermTilingWindow

@synthesize terminal;
@synthesize frame;

- (id)initForTerminal:(PseudoTerminal *)_terminal
{
        if (!(self = [super init]))
                return nil;
        
        self.terminal = (PseudoTerminal<iTermWeakReference> *)_terminal;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeOrMoveNotification:)
                                                     name:NSWindowDidResizeNotification
                                                   object:[_terminal window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeOrMoveNotification:)
                                                     name:NSWindowDidMoveNotification
                                                   object:[_terminal window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(lostFocus:)
                                                     name:NSWindowDidResignKeyNotification
                                                   object:[_terminal window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gainedFocus:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:[_terminal window]];
        return self;
}

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [super dealloc];
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingWindow: %p PseudoTerminal=%@", self, [self.terminal description]];
}

- (void)adjustToFrame
{
        [[[self terminal] window] setFrame:[[self frame] rectForWindowInsetBorder:YES] display:YES];
}

- (void)resizeOrMoveNotification:(NSNotification *)notification
{
        [[self frame] redraw];
}

- (void)lostFocus:(NSNotification *)notification
{
        self.focused = NO;
        //[[self frame] redraw];
}

- (void)gainedFocus:(NSNotification *)notification
{
        self.focused = YES;
        
#if 0   /* XXX: this swaps frames when the last terminal in a frame exits, which is not desired */
        if (![[[[self frame] manager] currentFrame] isEqualTo:[self frame]]) {
                [[[self frame] manager] setCurrentFrame:[self frame]];
        }
#endif
        
        //[[self frame] redraw];
}

- (void)focus
{
        [[[self terminal] window] makeKeyAndOrderFront:nil];
}

- (void)unfocus
{
        [[[self terminal] window] resignKeyWindow];
}

@end
