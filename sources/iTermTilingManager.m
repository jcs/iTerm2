//
//  iTermTilingManager.m
//  iTerm2
//
//  Created by joshua stein on 12/1/16.
//
//

#import "iTermTilingManager.h"
#import "DebugLogging.h"

/* iTermTilingWindow */
@implementation iTermTilingWindow

@synthesize terminal;
@synthesize frame;

- (id)initForTerminal:(PseudoTerminal *)_terminal
{
        if (!(self = [super init]))
                return nil;
        
        self.terminal = (PseudoTerminal<iTermWeakReference> *)_terminal;
        
        return self;
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingWindow: %p PseudoTerminal=%@", self, [self.terminal description]];
}

@end

/* iTermTilingFrameBorder */
@implementation iTermTilingFrameBorder {
        BOOL hiding;
}

- (void)drawRect:(NSRect)dirtyRect
{
        NSBezierPath *bpath = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, self.borderWidth / 2, self.borderWidth / 2) xRadius:self.cornerRadius yRadius:self.cornerRadius];
        if (hiding)
                [[NSColor clearColor] set];
        else
                [self.borderColor set];
        [bpath setLineWidth:self.borderWidth];
        [bpath stroke];
}

- (void)hide
{
        if (!hiding) {
                hiding = YES;
                [self setNeedsDisplay:YES];
        }
}

- (void)show
{
        if (hiding) {
                hiding = NO;
                [self setNeedsDisplay:YES];
        }
}

@end

/* iTermTilingFrame containing multiple iTermTilingWindow objects */
@implementation iTermTilingFrame

@synthesize borderWindow;
@synthesize border;
@synthesize rect;
@synthesize windows;

- (id)initWithRect:(CGRect)_rect
{
        if (!(self = [super init]))
                return nil;

        self.rect = _rect;
        self.windows = [[NSMutableArray alloc] init];

        self.borderWindow = [[NSWindow alloc] initWithContentRect:self.rect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
        self.borderWindow.opaque = NO;
        self.borderWindow.backgroundColor = [NSColor clearColor];
        self.borderWindow.ignoresMouseEvents = YES;
        self.borderWindow.level = CGWindowLevelForKey(kCGFloatingWindowLevelKey);
        self.borderWindow.hasShadow = NO;
        //self.borderWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
        self.borderWindow.releasedWhenClosed = NO;
        
        self.border = [[iTermTilingFrameBorder alloc] initWithFrame:self.borderWindow.contentView.bounds];
        [self.border setBorderColor:[NSColor colorWithRed:0.5 green:0 blue:0.5 alpha:1]];
        [self.border setBorderWidth:4];
        [self.border setCornerRadius:10];
        self.border.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self.borderWindow.contentView addSubview:self.border];
        
        [self updateFrame];
        [self.borderWindow makeKeyAndOrderFront:nil];
         
        return self;
}

- (void)addWindow:(iTermTilingWindow *)window
{
        [window setFrame:self];
        [[self windows] addObject:window];
        [[self border] show];
}

- (void)removeWindow:(iTermTilingWindow *)window
{
        [window setFrame:nil];
        [[self windows] removeObject:window];
        
        if ([[self windows] count] == 0) {
                NSLog(@"[TilingManager] frame has no more windows, hiding frame");
                [[self border] hide];
        } else
                [[self border] show];
}

- (void)updateFrame
{
        [[self borderWindow] setFrame:CGRectInset(self.rect, -self.border.borderWidth, -self.border.borderWidth) display:YES];
        [[self border] setNeedsDisplay:YES];
}

@end

/* iTermTilingManager containing multiple iTermTilingFrame objects */
@implementation iTermTilingManager {
        CGFloat gap;
        NSMutableArray<iTermTilingFrame *> *frames;
}

+ (instancetype)sharedInstance {
        static id instance;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
                instance = [[self alloc] init];
        });
        return instance;
}

- (instancetype)init
{
        if (!(self = [super init]))
                return nil;
        
        NSLog(@"tiling manager starting up!");
        
        gap = 10;
        
        /* create one frame taking up the screen */
        NSScreen *screen = [NSScreen mainScreen];
        CGRect initFrame = CGRectMake(screen.visibleFrame.origin.x + gap, screen.visibleFrame.origin.y + gap, screen.visibleFrame.size.width - (gap * 2), screen.visibleFrame.size.height - (gap * 2));
        
        NSLog(@"[TilingManager] setting initial frame to %@", NSStringFromRect(initFrame));

        iTermTilingFrame *frame = [[iTermTilingFrame alloc] initWithRect:initFrame];
        frames = [[NSMutableArray alloc] initWithObjects:frame, nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalWindowCreated:)
                                                     name:kTerminalWindowControllerWasCreatedNotification
                                                   object:nil];
        
        return self;
}

- (void)dumpWindows
{
        NSLog(@"[TilingManager] ===================================================================");
        NSLog(@"[TilingManager] window dump:");
        for (int i = 0; i < [frames count]; i++) {
                iTermTilingFrame *f = [frames objectAtIndex:i];
                
                for (int j = 0; j < [[f windows] count]; j++) {
                        iTermTilingWindow *t = (iTermTilingWindow *)[[f windows] objectAtIndex:j];
                        
                        NSLog(@"[TilingManager] [Frame:%d] [Window:%d] %@", i, j, t);
                }
        }
        NSLog(@"[TilingManager] ===================================================================");
}

- (iTermTilingFrame *)currentFrame
{
        return (iTermTilingFrame *)[frames objectAtIndex:0];
}

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [super dealloc];
}

- (void)terminalWindowCreated:(NSNotification *)notification
{
        if (![[[notification object] className] isEqualToString:@"PseudoTerminal"])
                return;

        iTermTilingWindow *itw = [[iTermTilingWindow alloc] initForTerminal:(PseudoTerminal *)[notification object]];
        
        NSLog(@"[TilingManager] new window created: %@", [notification object]);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalWindowResized:)
                                                     name:NSWindowDidResizeNotification
                                                   object:[[itw terminal] window]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalWindowClosing:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[[itw terminal] window]];

        [[self currentFrame] addWindow:itw];
        
        [self dumpWindows];
}

- (iTermTilingWindow *)iTermTilingWindowForNSWindow:(NSWindow *)window
{
        for (int i = 0; i < [frames count]; i++) {
                iTermTilingFrame *f = [frames objectAtIndex:i];
                
                for (int j = 0; j < [[f windows] count]; j++) {
                        iTermTilingWindow *t = (iTermTilingWindow *)[[f windows] objectAtIndex:j];
                        if (t.terminal && [t.terminal.window isEqualTo:window])
                                return t;
                }
        }
        
        NSLog(@"[TilingManager] can't find itw for window %@", window);
        return nil;
}

- (void)terminalWindowResized:(NSNotification *)notification
{
        NSLog(@"[TilingManager] window resized, looking for itw: %@", [notification object]);
        
        iTermTilingWindow *t = [self iTermTilingWindowForNSWindow:[notification object]];
        if (!t)
                return;
        
        NSLog(@"[TilingManager] window resized: %@, keeping in frame %@", [t terminal], NSStringFromRect([[t frame] rect]));
        
        [[[t terminal] window] setFrame:[[t frame] rect] display:YES];
}

- (void)terminalWindowClosing:(NSNotification *)notification
{
        NSLog(@"[TilingManager] window closing, looking for itw: %@", [notification object]);
        
        iTermTilingWindow *t = [self iTermTilingWindowForNSWindow:[notification object]];
        if (t)
                [[t frame] removeWindow:t];
}

@end
