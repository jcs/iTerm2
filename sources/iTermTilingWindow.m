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
        int pad = 0;
        if (self.borderWidth % 2 != 0)
                pad++;
        
        NSBezierPath *bpath = [NSBezierPath bezierPathWithRect:NSMakeRect(floorf(self.borderWidth / 2), floorf(self.borderWidth / 2), self.bounds.size.width - self.borderWidth + pad, self.bounds.size.height - self.borderWidth + pad)];
        [self.borderColor set];
        [bpath setLineWidth:self.borderWidth];
        [bpath stroke];
}

/* let PTYTextView see first click to start selecting text */
- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
        return YES;
}

@end

@implementation iTermTilingWindow

@synthesize terminal;
@synthesize frame;
@synthesize border;

- (id)initForTerminal:(PseudoTerminal *)terminal_ frame:(iTermTilingFrame *)frame_ number:(int)number_
{
        if (!(self = [super init]))
                return nil;
        
        self.terminal = (PseudoTerminal<iTermWeakReference> *)terminal_;
        
        self.border = [[iTermTilingWindowBorder alloc] initWithFrame:NSMakeRect(0, 0, terminal.windowFrame.size.width, terminal.windowFrame.size.height) forTilingWindow:self];
        [[[[self terminal] window] contentView] addSubview:self.border];
        
        self.frame = frame_;
        self.number = number_;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalClosing:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[terminal_ window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeOrMoveNotification:)
                                                     name:NSWindowDidResizeNotification
                                                   object:[terminal_ window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeOrMoveNotification:)
                                                     name:NSWindowDidMoveNotification
                                                   object:[terminal_ window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(lostFocusNotification:)
                                                     name:NSWindowDidResignKeyNotification
                                                   object:[terminal_ window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gainedFocusNotification:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:[terminal_ window]];

        return self;
}

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [super dealloc];
}

- (void)terminalClosing:(NSNotification *)notification
{
        [[[self frame] manager] removeWindow:self];
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingWindow: %p PseudoTerminal=%@", self, [self.terminal description]];
}

- (BOOL)isFrontMostInFrame
{
        return ([self isEqualTo:[[[self frame] windows] objectAtIndex:0]]);
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
        [[self border] setFrame:NSMakeRect(0, 0, self.terminal.windowFrame.size.width, self.terminal.windowFrame.size.height)];
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
