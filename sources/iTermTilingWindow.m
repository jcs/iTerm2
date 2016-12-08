//
//  iTermTilingWindow.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingWindow.h"

@implementation iTermTilingWindowBorder

@synthesize window;
@synthesize borderWidth;
@synthesize borderColor;

- (id)initWithFrame:(CGRect)frame forTilingWindow:(iTermTilingWindow *)tilingWindow_
{
        self = [super initWithFrame:frame];
        self.tilingWindow = tilingWindow_;
        self.borderWidth = 1;
        self.borderColor = [NSColor clearColor];

        return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
        NSBezierPath *bpath = [NSBezierPath bezierPathWithRect:self.bounds];
        [self.borderColor set];
        [bpath setLineWidth:self.borderWidth];
        [bpath stroke];
}

/* let PTYTextView see first click to start selecting text */
- (BOOL)acceptsFirstMouse:(NSEvent *)event {
        return YES;
}

@end

@implementation iTermTilingWindow

@synthesize terminal;
@synthesize frame;
@synthesize border;

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
                                                 selector:@selector(lostFocusNotification:)
                                                     name:NSWindowDidResignKeyNotification
                                                   object:[_terminal window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gainedFocusNotification:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:[_terminal window]];

        self.border = [[iTermTilingWindowBorder alloc] initWithFrame:NSMakeRect(0, 0, terminal.windowFrame.size.width, terminal.windowFrame.size.height) forTilingWindow:self];
        [[[[self terminal] window] contentView] addSubview:self.border];

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
        
        if ([[[self frame] windows] count] > 0) {
                if ([[[[self frame] manager] currentFrame] isEqualTo:self.frame])
                        [[self border] setBorderColor:[[[self frame] manager] activeFrameBorderColor]];
                else
                        [[self border] setBorderColor:[[[self frame] manager] inactiveFrameBorderColor]];
        } else
                [[self border] setBorderColor:[NSColor clearColor]];
        
        [[self border] setBorderWidth:[self.frame.manager borderWidth]];
        [[self border] setFrame:NSMakeRect(0, 0, terminal.windowFrame.size.width, terminal.windowFrame.size.height)];
        [[self border] setNeedsDisplay:YES];
}

- (void)resizeOrMoveNotification:(NSNotification *)notification
{
        [[self frame] redraw];
}

- (void)lostFocusNotification:(NSNotification *)notification
{
        self.focused = NO;
}

- (void)gainedFocusNotification:(NSNotification *)notification
{
        if ([[[[self frame] manager] currentFrame] isEqualTo:[self frame]]) {
                self.focused = YES;
        } else {
                [[[self terminal] window] resignKeyWindow];
                [[[[self frame] manager] currentFrame] focusFrontWindowAndMakeKey:YES];
        }
}

- (void)focusAndMakeKey:(BOOL)key
{
        if (key)
                [[[self terminal] window] makeKeyAndOrderFront:nil];
        else
                [[[self terminal] window] orderFront:nil];
}

- (void)unfocus
{
        [[[self terminal] window] resignKeyWindow];
}

@end
