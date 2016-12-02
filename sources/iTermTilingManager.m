//
//  iTermTilingManager.m
//  iTerm2
//
//  Created by joshua stein on 12/1/16.
//
//

#import "iTermTilingManager.h"
#import "iTermTilingFrame.h"
#import "iTermTilingWindow.h"
#import "iTermKeyBindingMgr.h"
#import "DebugLogging.h"

/* iTermTilingManager containing multiple iTermTilingFrame objects */
@implementation iTermTilingManager {
        NSUInteger curFrameIdx;
}

+ (instancetype)sharedInstance {
        static id instance;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
                instance = [[self alloc] init];
        });
        return instance;
}

+ (BOOL)ignoreKeyBindingAction:(int)code
{
        if (code == KEY_ACTION_TILING_ACTION)
                return NO;
        else if (code >= KEY_ACTION_TILING_ACTION && code <= KEY_ACTION_TILING_LASTID)
                return ![[iTermTilingManager sharedInstance] actionMode];
        else
                return YES;
}

- (instancetype)init
{
        if (!(self = [super init]))
                return nil;
        
        NSLog(@"[TilingManager] starting up!");
        
        self.gap = 30;
        self.borderWidth = 4;
        self.cornerRadius = 10;
        self.activeFrameBorderColor = [NSColor orangeColor];

        curFrameIdx = 0;
        
        /* create one frame taking up the screen */
        NSScreen *screen = [NSScreen mainScreen];
        CGRect initFrame = CGRectMake(screen.visibleFrame.origin.x, screen.visibleFrame.origin.y, screen.visibleFrame.size.width, screen.visibleFrame.size.height);
        
        NSLog(@"[TilingManager] setting initial frame to %@", NSStringFromRect(initFrame));

        iTermTilingFrame *frame = [[iTermTilingFrame alloc] initWithRect:initFrame andManager:self];
        self.frames = [[NSMutableArray alloc] initWithObjects:frame, nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalWindowCreated:)
                                                     name:kTerminalWindowControllerWasCreatedNotification
                                                   object:nil];
        
        return self;
}

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [super dealloc];
}

- (void)dumpWindows
{
        NSLog(@"[TilingManager] ===================================================================");
        NSLog(@"[TilingManager] window dump:");
        for (int i = 0; i < [self.frames count]; i++) {
                iTermTilingFrame *f = [self.frames objectAtIndex:i];
                
                for (int j = 0; j < [[f windows] count]; j++) {
                        iTermTilingWindow *t = (iTermTilingWindow *)[[f windows] objectAtIndex:j];
                        
                        NSLog(@"[TilingManager] [Frame:%d] [Window:%d] %@", i, j, t);
                }
        }
        NSLog(@"[TilingManager] ===================================================================");
}

- (iTermTilingFrame *)currentFrame
{
        return (iTermTilingFrame *)[self.frames objectAtIndex:curFrameIdx];
}

- (void)setCurrentFrame:(iTermTilingFrame *)newCur
{
        for (int i = 0; i < [self.frames count]; i++) {
                iTermTilingFrame *f = [self.frames objectAtIndex:i];
                
                if ([f isEqualTo:newCur]) {
                        curFrameIdx = i;
                        break;
                }
        }
        
        [self redrawFrames];
}

- (void)terminalWindowCreated:(NSNotification *)notification
{
        if (![[[notification object] className] isEqualToString:@"PseudoTerminal"])
                return;

        iTermTilingWindow *itw = [[iTermTilingWindow alloc] initForTerminal:(PseudoTerminal *)[notification object]];
        
        NSLog(@"[TilingManager] new window created: %@", [notification object]);

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(terminalWindowClosing:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[[itw terminal] window]];

        [[self currentFrame] addWindow:itw];
        
        [self dumpWindows];
}

- (iTermTilingWindow *)iTermTilingWindowForNSWindow:(NSWindow *)window
{
        for (int i = 0; i < [self.frames count]; i++) {
                iTermTilingFrame *f = [self.frames objectAtIndex:i];
                
                for (int j = 0; j < [[f windows] count]; j++) {
                        iTermTilingWindow *t = (iTermTilingWindow *)[[f windows] objectAtIndex:j];
                        if (t.terminal && [t.terminal.window isEqualTo:window])
                                return t;
                }
        }
        
        NSLog(@"[TilingManager] can't find itw for window %@", window);
        return nil;
}

- (void)terminalWindowClosing:(NSNotification *)notification
{
        NSLog(@"[TilingManager] window closing, looking for itw: %@", [notification object]);
        
        iTermTilingWindow *t = [self iTermTilingWindowForNSWindow:[notification object]];
        if (t)
                [[t frame] removeWindow:t];
}

- (void)redrawFrames
{
        [[self frames] enumerateObjectsUsingBlock:^(iTermTilingFrame * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj redraw];
        }];
}

- (NSString *)directionString:(iTermTilingFrameDirection)direction
{
        switch (direction) {
        case iTermTilingFrameDirectionLeft:
                return @"left";
        case iTermTilingFrameDirectionAbove:
                return @"above";
        case iTermTilingFrameDirectionBelow:
                return @"below";
        case iTermTilingFrameDirectionRight:
                return @"right";
        }
        
        return @"???";
}

- (iTermTilingFrame *)findFrameInDirection:(iTermTilingFrameDirection)direction ofFrame:(iTermTilingFrame *)which
{
        if (which == nil)
                which = [self currentFrame];
        
        if (which == nil)
                return nil;
        
        NSLog(@"[TilingManager] trying to find frame %@ of %@", [self directionString:direction], which);
        [self dumpWindows];
        
        __block iTermTilingFrame *winner;
        [[self frames] enumerateObjectsUsingBlock:^(iTermTilingFrame * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                switch (direction) {
                case iTermTilingFrameDirectionLeft:
                        if (obj.rect.origin.x + obj.rect.size.width == which.rect.origin.x - 1) {
                                winner = obj.copy;
                                *stop = YES;
                                return;
                        }
                        break;
                case iTermTilingFrameDirectionRight:
                        if (obj.rect.origin.x == which.rect.origin.x + which.rect.size.width + 1) {
                                winner = obj.copy;
                                *stop = YES;
                                return;
                        }
                        break;
                case iTermTilingFrameDirectionAbove:
                        if (obj.rect.origin.y == which.rect.origin.y + which.rect.size.height + 1) {
                                winner = obj.copy;
                                *stop = YES;
                                return;
                        }
                        break;
                case iTermTilingFrameDirectionBelow:
                        if (obj.rect.origin.y == which.rect.origin.y + which.rect.size.height + 1) {
                                winner = obj.copy;
                                *stop = YES;
                                return;
                        }
                        break;
                }
        }];
        
        NSLog(@"winner is %@", winner);

        return winner;
}

/* whether iTermKeyBindingMgr should downgrade a key action to just a regular keystroke */
- (BOOL)downgradeKeyAction:(int)action
{
        if (self.actionMode)
                return NO;
        
        return (action > KEY_ACTION_TILING_ACTION && action <= KEY_ACTION_TILING_LASTID);
}

- (BOOL)handleKeyEvent:(NSEvent *)event
{
        NSString *unmodkeystr = [event charactersIgnoringModifiers];
        unichar unmodunicode = [unmodkeystr length] > 0 ? [unmodkeystr characterAtIndex:0] : 0;
        unsigned int modflag = [event modifierFlags];
        
        int action = [iTermKeyBindingMgr actionForKeyCode:unmodunicode
                                                modifiers:modflag
                                                     text:nil
                                              keyMappings:[iTermKeyBindingMgr globalKeyMap]];

        if (!self.actionMode) {
                if (action == KEY_ACTION_TILING_ACTION) {
                        NSLog(@"[TilingManager] enabling action mode");
                        self.actionMode = YES;
                        [[NSCursor contextualMenuCursor] push];
                        return YES;
                }
                
                return NO;
        }
        
        NSLog(@"[TilingManager] process key action in action mode: %d", action);

        switch (action) {
                case KEY_ACTION_TILING_HSPLIT:
                {
                        /* split the current frame into two, left and right */
                        NSLog(@"[TilingManager] horizontal split");
                        [[self currentFrame] horizontalSplit];
                        
                        break;
                }
                case KEY_ACTION_TILING_VSPLIT:
                {
                        /* split the current frame into two, top and bottom */
                        NSLog(@"[TilingManager] vertical split");
                        [[self currentFrame] verticalSplit];

                        break;
                }
                case KEY_ACTION_TILING_FOCUS_LEFT:
                {
                        NSLog(@"[TilingManager] focus left");
                        iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionLeft ofFrame:[self currentFrame]];
                        [self setCurrentFrame:swap];
                        break;
                }
                case KEY_ACTION_TILING_FOCUS_RIGHT:
                {
                        NSLog(@"[TilingManager] focus right");
                        iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionRight ofFrame:[self currentFrame]];
                        [self setCurrentFrame:swap];
                        break;
                }
                case KEY_ACTION_TILING_FOCUS_UP:
                {
                        NSLog(@"[TilingManager] focus up");
                        iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionAbove ofFrame:[self currentFrame]];
                        [self setCurrentFrame:swap];
                        break;
                }
                case KEY_ACTION_TILING_FOCUS_DOWN:
                {
                        NSLog(@"[TilingManager] focus down");
                        iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionBelow ofFrame:[self currentFrame]];
                        [self setCurrentFrame:swap];
                        break;
                }
                case KEY_ACTION_TILING_FOCUS_NEXT:
                        NSLog(@"[TilingManager] focus next");
                        break;
                case KEY_ACTION_TILING_FOCUS_PREV:
                        NSLog(@"[TilingManager] focus previous");
                        break;
                case KEY_ACTION_TILING_SWAP_LEFT:
                        NSLog(@"[TilingManager] swap left");
                        break;
                case KEY_ACTION_TILING_SWAP_RIGHT:
                        NSLog(@"[TilingManager] swap right");
                        break;
                case KEY_ACTION_TILING_SWAP_UP:
                        NSLog(@"[TilingManager] swap up");
                        break;
                case KEY_ACTION_TILING_SWAP_DOWN:
                        NSLog(@"[TilingManager] swap down");
                        break;
                case KEY_ACTION_TILING_REMOVE:
                        NSLog(@"[TilingManager] remove");
                        break;
                default:
                        NSLog(@"[TilingManager] other key pressed while in action mode: %d", action);
        }
        
        self.actionMode = NO;
        [NSCursor pop];

        return YES;
}

@end
