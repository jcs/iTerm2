//
//  iTermTilingWindow.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingWindow.h"

/* iTermTilingWindow */
@implementation iTermTilingWindow

@synthesize terminal;
@synthesize frame;

- (id)initForTerminal:(PseudoTerminal *)_terminal
{
        if (!(self = [super init]))
                return nil;
        
        self.terminal = (PseudoTerminal<iTermWeakReference> *)_terminal;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeNotification:)
                                                     name:NSWindowDidResizeNotification
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
        [[[self terminal] window] setFrame:[[self frame] rectForWindow] display:YES];
}

- (void)resizeNotification:(NSNotification *)notification
{
        NSLog(@"[TilingManager] window resized: %@, keeping in frame %@", [self terminal], NSStringFromRect([[self frame] rectForWindow]));
        [self adjustToFrame];
}

@end
