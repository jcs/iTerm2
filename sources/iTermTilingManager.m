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
#import "iTermTilingToast.h"
#import "NSScreen+iTerm.h"
#import "DebugLogging.h"

/* iTermTilingManager containing multiple iTermTilingFrame objects */
@implementation iTermTilingManager {
        BOOL adjustingFrames;
        NSEvent *ignoreEvent;
        int winNumbers;
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
        
        NSLog(@"[TilingManager] starting up!");
        
        adjustingFrames = NO;
        
        self.windows = [[NSMutableArray alloc] init];
        winNumbers = 0;
        
        /* TODO: get these from preferences */
        self.gap = 16;
        self.borderWidth = 4;
        self.activeFrameBorderColor = [NSColor orangeColor];
        self.inactiveFrameBorderColor = [NSColor grayColor];

        /* create one frame taking up the screen */
        NSScreen *screen = [NSScreen mainScreen];
        iTermTilingFrame *frame = [[iTermTilingFrame alloc] initWithRect:screen.visibleFrameIgnoringHiddenDock andManager:self];
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

- (void)dumpFrames
{
        NSLog(@"==========================================");
        
        for (int i = 0; i < [[self frames] count]; i++) {
                NSLog(@"frame[%d] %@", i, NSStringFromRect([[[self frames] objectAtIndex:i] rect]));
                
                for (int j = 0; j < [[self windows] count]; j++) {
                        iTermTilingWindow *win = [[self windows] objectAtIndex:j];
                        
                        if ([[win frame] isEqualTo:[[self frames] objectAtIndex:i]]) {
                                NSLog(@"frame[%d] window[%d]", i, [win number]);
                        }
                }
        }
        NSLog(@"==========================================");
}

- (void)terminalWindowCreated:(NSNotification *)notification
{
        if (![[[notification object] className] isEqualToString:@"PseudoTerminal"])
                return;
        
        iTermTilingWindow *itw = [[iTermTilingWindow alloc] initForTerminal:(PseudoTerminal *)[notification object] frame:[self currentFrame] number:winNumbers++];
        [[self windows] addObject:itw];
        
        [itw adjustToFrame];
        
        [self dumpFrames];
}

- (void)removeWindow:(iTermTilingWindow *)window
{
        iTermTilingFrame *fromFrame = [window frame];
        [window setFrame:nil];
        [[self windows] removeObject:window];

        if ([[self windows] count] == 0)
                winNumbers = 0;
        else if ([window number] == winNumbers - 1)
                winNumbers--;
        
        [fromFrame focusFrontWindowAndMakeKey:[[self currentFrame] isEqualTo:fromFrame]];
}

- (BOOL)startAdjustingFrames
{
        @synchronized(self) {
                if (adjustingFrames)
                        return NO;
                
                adjustingFrames = YES;
        }
        
        return YES;
}

- (void)finishAdjustingFrames
{
        [self redrawFrames];
        adjustingFrames = NO;
        
        [self dumpFrames];
}

- (iTermTilingFrame *)currentFrame
{
        return (iTermTilingFrame *)[self.frames objectAtIndex:0];
}

- (void)setCurrentFrame:(iTermTilingFrame *)newCur
{
        if (![self startAdjustingFrames])
                return;
        
        [[self currentFrame] unfocusFrontWindow];
        
        for (int i = 0; i < [self.frames count]; i++) {
                iTermTilingFrame *f = [self.frames objectAtIndex:i];
                
                if ([f isEqualTo:newCur]) {
                        /* move the new current frame to the head of the line */
                        [[self frames] removeObjectAtIndex:i];
                        [[self frames] insertObject:f atIndex:0];
                        
                        [f focusFrontWindowAndMakeKey:YES];
                        
                        [iTermTilingToast showToastWithMessage:@"Current Frame" inFrame:f];

                        break;
                }
        }
        
        /* move the new current frame's top window to the front of the window list */
        iTermTilingWindow *w = [[self currentFrame] frontWindow];
        if (w) {
                [[self windows] removeObject:w];
                [[self windows] insertObject:w atIndex:0];
        }
        
        [self finishAdjustingFrames];
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
        
        NSMutableArray *matches = [[NSMutableArray alloc] init];
        for (int i = 0; i < [[self frames] count]; i++) {
                iTermTilingFrame *tf = [[self frames] objectAtIndex:i];
                
                switch (direction) {
                case iTermTilingFrameDirectionLeft:
                        if (tf.rect.origin.x + tf.rect.size.width == which.rect.origin.x)
                                [matches addObject:tf];
                        break;
                case iTermTilingFrameDirectionRight:
                        if (tf.rect.origin.x == which.rect.origin.x + which.rect.size.width)
                                [matches addObject:tf];
                        break;
                case iTermTilingFrameDirectionAbove:
                        if (tf.rect.origin.y == which.rect.origin.y + which.rect.size.height) {
                                if (tf.rect.origin.x == which.rect.origin.x)
                                        [matches insertObject:tf atIndex:0];
                                else
                                        [matches addObject:tf];
                        }
                        break;
                case iTermTilingFrameDirectionBelow:
                        if (which.rect.origin.y == tf.rect.origin.y + tf.rect.size.height) {
                                if (tf.rect.origin.x == which.rect.origin.x)
                                        [matches insertObject:tf atIndex:0];
                                else
                                        [matches addObject:tf];
                        }
                        break;
                }
        }
        
        if ([matches count] > 0)
                return [matches objectAtIndex:0];
        
        return nil;
}

- (BOOL)handleAction:(int)action
{
        BOOL ret = YES;
        
        switch (action) {
        case KEY_ACTION_TILING_HSPLIT:
        {
                /* split the current frame into two, left and right */
                NSLog(@"[TilingManager] horizontal split");
                [self splitCurrentFrameHorizontally:YES];
                break;
        }
        case KEY_ACTION_TILING_VSPLIT:
        {
                /* split the current frame into two, top and bottom */
                NSLog(@"[TilingManager] vertical split");
                [self splitCurrentFrameHorizontally:NO];
                break;
        }
        case KEY_ACTION_TILING_FOCUS_LEFT:
        {
                NSLog(@"[TilingManager] focus left");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionLeft ofFrame:[self currentFrame]];
                if (swap)
                        [self setCurrentFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_FOCUS_RIGHT:
        {
                NSLog(@"[TilingManager] focus right");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionRight ofFrame:[self currentFrame]];
                if (swap)
                        [self setCurrentFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_FOCUS_UP:
        {
                NSLog(@"[TilingManager] focus up");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionAbove ofFrame:[self currentFrame]];
                if (swap)
                        [self setCurrentFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_FOCUS_DOWN:
        {
                NSLog(@"[TilingManager] focus down");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionBelow ofFrame:[self currentFrame]];
                if (swap)
                        [self setCurrentFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_FOCUS_LAST:
                NSLog(@"[TilingManager] focus last");
                if ([[self frames] count] > 1) {
                        [self setCurrentFrame:[[self frames] objectAtIndex:1]];
                }
                break;
        case KEY_ACTION_TILING_SHOW_FRAMES:
                NSLog(@"[TilingManager] show frames");
                [self showFrameNumbers];
                break;
        case KEY_ACTION_TILING_REMOVE:
                NSLog(@"[TilingManager] remove");
                [self removeCurrentFrame];
                break;
        case KEY_ACTION_TILING_NEW_WINDOW:
                NSLog(@"[TilingManager] new window");
                [[iTermController sharedInstance] launchBookmark:[[ProfileModel sharedInstance] defaultBookmark] inTerminal:nil];
                break;
        case KEY_ACTION_TILING_CYCLE_NEXT:
                NSLog(@"[TilingManager] cycle next window");
                [[self currentFrame] cycleWindowsForward:YES];
                break;
        case KEY_ACTION_TILING_CYCLE_PREV:
                NSLog(@"[TilingManager] cycle prev window");
                [[self currentFrame] cycleWindowsForward:NO];
                break;
        case KEY_ACTION_TILING_CYCLE_LAST:
                NSLog(@"[TilingManager] cycle last window");
                [[self currentFrame] cycleLastWindow];
                break;
        case KEY_ACTION_TILING_SWAP_LEFT: {
                NSLog(@"[TilingManager] swap left");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionLeft ofFrame:[self currentFrame]];
                if (swap)
                        [[self currentFrame] swapWithFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_SWAP_RIGHT: {
                NSLog(@"[TilingManager] swap right");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionRight ofFrame:[self currentFrame]];
                if (swap)
                        [[self currentFrame] swapWithFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_SWAP_UP: {
                NSLog(@"[TilingManager] swap up");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionAbove ofFrame:[self currentFrame]];
                if (swap)
                        [[self currentFrame] swapWithFrame:swap];
                break;
        }
        case KEY_ACTION_TILING_SWAP_DOWN: {
                NSLog(@"[TilingManager] swap down");
                iTermTilingFrame *swap = [self findFrameInDirection:iTermTilingFrameDirectionBelow ofFrame:[self currentFrame]];
                if (swap)
                        [[self currentFrame] swapWithFrame:swap];
                break;
        }

        default:
                NSLog(@"[TilingManager] other key pressed while in action mode: %d", action);
                ret = NO;
        }

        return ret;
}

- (void)splitCurrentFrameHorizontally:(BOOL)horizontally
{
        /* split the current frame into two, either left and right (becoming left position) for horizontal, or top and bottom (becoming top) for vertical */
        NSRect newCurRect, newNewRect;
        
        if (![self startAdjustingFrames])
                return;
        
        iTermTilingFrame *cur = [self currentFrame];

        NSRect oldRect = [cur rect];
        if (horizontally) {
                newCurRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y, floor(oldRect.size.width / 2), oldRect.size.height);
                newNewRect = NSMakeRect(newCurRect.origin.x + newCurRect.size.width, oldRect.origin.y, oldRect.size.width - newCurRect.size.width, oldRect.size.height);
        } else {
                newCurRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y + (oldRect.size.height / 2), oldRect.size.width, oldRect.size.height / 2);
                newNewRect = NSMakeRect(newCurRect.origin.x, oldRect.origin.y, oldRect.size.width, oldRect.size.height - newCurRect.size.height);
        }
        
        [cur setRect:newCurRect];
        
        iTermTilingFrame *newFrame = [[iTermTilingFrame alloc] initWithRect:newNewRect andManager:self];
        /* assuming we'll want to switch to our new frame next, put it at position 1 for KEY_ACTION_TILING_FOCUS_LAST */
        [[self frames] insertObject:newFrame atIndex:1];
        
        [self finishAdjustingFrames];
}

- (void)removeCurrentFrame
{
        if (![self startAdjustingFrames])
                return;

        if ([[self frames] count] <= 1) {
                [iTermTilingToast showToastWithMessage:@"Cannot remove last frame" inFrame:[self currentFrame]];
                return;
        }

        iTermTilingFrame *cur = [self currentFrame];
        iTermTilingFrame *dst = [[self frames] objectAtIndex:1];

        /* push this frame's windows onto the next frame */
        NSArray *wins = [cur windows];
        for (int i = 0; i < [wins count]; i++) {
                iTermTilingWindow *tw = [wins objectAtIndex:i];
                [tw setFrame:dst];
        }
        
        [[self frames] removeObject:cur];
        
        [self resizeFrames];
        
        [self finishAdjustingFrames];
}

- (void)resizeFrames
{
        /* if the resolution changed, try to fit everything back inside the screen */
        NSScreen *screen = [NSScreen mainScreen];
        for (int i = 0; i < [[self frames] count]; i++) {
                iTermTilingFrame *tf = [[self frames] objectAtIndex:i];
                if (tf.rect.origin.x + tf.rect.size.width > screen.visibleFrameIgnoringHiddenDock.size.width) {
                        NSLog(@"[TilingManager] frame is wider than screen (%@): %@", NSStringFromRect(screen.visibleFrameIgnoringHiddenDock), tf);
                        
                        /* TODO */
                }
        }
        
        /* now find frames that have no neighbors and make them touch (or touch the screen) */
        for (int i = 0; i < [[self frames] count]; i++) {
                iTermTilingFrame *tf = [[self frames] objectAtIndex:i];
                CGRect newRect = tf.rect;
                
                /* find any frames to the right of us that will prevent us from taking the remaining screen width */
                CGFloat newWidth = screen.visibleFrameIgnoringHiddenDock.size.width - newRect.origin.x;
                for (int j = 0; j < [[self frames] count]; j++) {
                        if (j == i)
                                continue;
                        
                        iTermTilingFrame *of = [[self frames] objectAtIndex:j];
                        
                        if (floor(of.rect.origin.y) < floor(newRect.origin.y + newRect.size.height) &&
                            floor(of.rect.origin.y + of.rect.size.height) > floor(newRect.origin.y) &&
                            floor(of.rect.origin.x) > floor(newRect.origin.x)) {
                                newWidth = MIN(newWidth, of.rect.origin.x - newRect.origin.x);
                        }
                }
                newRect.size.width = newWidth;
        
                /* find any frames below us that will prevent us from taking the remaining screen height */
                //CGFloat newHeight = newRect.origin.y + newRect.size.height;
                CGFloat newHeight = -1;
                for (int j = 0; j < [[self frames] count]; j++) {
                        if (j == i)
                                continue;

                        iTermTilingFrame *of = [[self frames] objectAtIndex:j];

                        if (floor(of.rect.origin.x) < floor(newRect.origin.x + newRect.size.width) &&
                            floor(of.rect.origin.x + of.rect.size.width) > floor(newRect.origin.x) &&
                            floor(of.rect.origin.y) < floor(newRect.origin.y)) {
                                newHeight = MAX(newHeight, of.rect.origin.y + of.rect.size.height);
                        }
                }
                if (newHeight == -1)
                        newHeight = newRect.origin.y + newRect.size.height;
                newRect.origin.y -= (newHeight - newRect.size.height);
                newRect.size.height = newHeight;
                
                /* find any frames to the left of us that will prevent us from taking the remaining screen width */
                CGFloat newLeft = 0;
                for (int j = 0; j < [[self frames] count]; j++) {
                        if (j == i)
                                continue;

                        iTermTilingFrame *of = [[self frames] objectAtIndex:j];
                        
                        if (floor(of.rect.origin.y) < floor(newRect.origin.y + newRect.size.height) &&
                            floor(of.rect.origin.y + of.rect.size.height) > floor(newRect.origin.y) &&
                            floor(of.rect.origin.x) < floor(newRect.origin.x)) {
                                newLeft = MAX(newLeft, of.rect.origin.x + of.rect.size.width);
                        }
                }
                newRect.size.width += (newRect.origin.x - newLeft);
                newRect.origin.x = newLeft;
                
                /* find any frames above us that will prevent us from taking the remaining screen height */
                CGFloat newTop = screen.visibleFrameIgnoringHiddenDock.size.height;
                for (int j = 0; j < [[self frames] count]; j++) {
                        if (j == i)
                                continue;

                        iTermTilingFrame *of = [[self frames] objectAtIndex:j];
                        
                        if (floor(of.rect.origin.x) < floor(newRect.origin.x + newRect.size.width) &&
                            floor(of.rect.origin.x + of.rect.size.width) > newRect.origin.x &&
                            floor(of.rect.origin.y) > floor(newRect.origin.y)) {
                                newTop = MIN(newTop, of.rect.origin.y);
                        }
                }
                newRect.size.height += (newTop - newRect.size.height - newRect.origin.y);
                newRect.origin.y = newTop - newRect.size.height;
                
                [tf setRect:newRect];
        }
}

- (void)showFrameNumbers
{
        if (self.showingFrameNumbers)
                return;
        
        self.showingFrameNumbers = YES;
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideFrameNumbers) userInfo:nil repeats:NO];
        [self redrawFrames];
}

- (void)hideFrameNumbers
{
        self.showingFrameNumbers = NO;
        [self redrawFrames];
}

- (NSArray<iTermTilingWindow *> *)windowsInFront
{
        NSMutableArray *frontWins = [[NSMutableArray alloc] init];
        for (int i = 0; i < [[self frames] count]; i++) {
                iTermTilingWindow *w = [[[self frames] objectAtIndex:i] frontWindow];
                if (w)
                        [frontWins addObject:w];
        }
        
        return [NSArray arrayWithArray:frontWins];
}

- (NSArray<iTermTilingWindow *> *)windowsNotInFront
{
        NSArray *frontWins = [self windowsInFront];
        
        NSMutableArray *wins = [[NSMutableArray alloc] init];
        for (int i = 0; i < [[self windows] count]; i++) {
                if (![frontWins containsObject:[[self windows] objectAtIndex:i]])
                        [wins addObject:[[self windows] objectAtIndex:i]];
        }
        
        return [NSArray arrayWithArray:wins];
}

@end
