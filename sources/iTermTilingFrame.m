//
//  iTermTilingFrame.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingFrame.h"
#import "iTermTilingToast.h"

@implementation iTermTilingFrame

@synthesize rect;
@synthesize windows;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)manager
{
        if (!(self = [super init]))
                return nil;
        
        self.manager = manager;
        self.rect = _rect;
        self.windows = [[NSMutableArray alloc] init];
        
        return self;
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingFrame: %p rect=%@ rectForWindow=%@ windows=%lu", self, NSStringFromRect(self.rect), NSStringFromRect(self.rectForWindow), (unsigned long)[[self windows] count]];
}

- (void)addWindow:(iTermTilingWindow *)window
{
        [window setFrame:self];
        [[self windows] insertObject:window atIndex:0];
}

- (void)removeWindow:(iTermTilingWindow *)window
{
        [window setFrame:nil];
        [[self windows] removeObject:window];
        
        [self focusFrontWindowAndMakeKey:[[[self manager] currentFrame] isEqualTo:self]];
}

- (void)focusFrontWindowAndMakeKey:(BOOL)key
{
        if ([[self windows] count] == 0)
                return;
        
        iTermTilingWindow *win = [[self windows] objectAtIndex:0];
        if (win)
                [win focusAndMakeKey:(BOOL)key];
}

- (void)unfocusFrontWindow
{
        if ([[self windows] count] == 0)
                return;
        
        iTermTilingWindow *win = [[self windows] objectAtIndex:0];
        if (win)
                [win unfocus];
}

- (void)swapWithFrame:(iTermTilingFrame *)toFrame
{
        CGRect torect = [toFrame rect];
        CGRect thisrect = [self rect];
        [self setRect:torect];
        [toFrame setRect:thisrect];
        [toFrame focusFrontWindowAndMakeKey:YES];
}

- (void)cycleWindowsForward:(BOOL)forward
{
        if ([[self windows] count] == 0) {
                [iTermTilingToast showToastWithMessage:@"No managed windows" inFrame:self];
                return;
        }
        
        if ([[self windows] count] == 1) {
                [iTermTilingToast showToastWithMessage:@"No other windows" inFrame:self];
                return;
        }
        
        if (forward) {
                /* normal cycle, shift first window onto the end of the stack */
                iTermTilingWindow *w = [[self windows] objectAtIndex:0];
                [[self windows] removeObjectAtIndex:0];
                [[self windows] addObject:w];
                [self focusFrontWindowAndMakeKey:YES];
        } else {
                /* previous cycle, move last window onto the front */
                iTermTilingWindow *w = [[self windows] lastObject];
                [[self windows] removeLastObject];
                [[self windows] insertObject:w atIndex:0];
                [self focusFrontWindowAndMakeKey:YES];
        }
}

- (void)cycleLastWindow
{
        if ([[self windows] count] == 0) {
                [iTermTilingToast showToastWithMessage:@"No managed windows" inFrame:self];
                return;
        }
        
        if ([[self windows] count] == 1) {
                [iTermTilingToast showToastWithMessage:@"No other windows" inFrame:self];
                return;
        }
        
        iTermTilingWindow *w = [[self windows] objectAtIndex:0];
        [[self windows] removeObjectAtIndex:0];
        [[self windows] insertObject:w atIndex:1];
        [self focusFrontWindowAndMakeKey:YES];
}

- (void)setRect:(CGRect)_rect
{
        rect = _rect;
        [self redraw];
}

- (void)redraw
{
        [[self windows] enumerateObjectsUsingBlock:^(iTermTilingWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj adjustToFrame];
        }];
}

- (CGRect)rectForWindow
{
        CGRect sf = [[NSScreen mainScreen] visibleFrame];
        CGFloat gap;
        CGRect nr = self.rect;
        
        /* when not touching an edge, use half gap since the other side will have half gap too */
        
        gap = self.manager.gap / (self.rect.origin.x == 0 ? 1 : 2);
        nr.origin.x += gap;
        nr.size.width -= gap;
        
        gap = self.manager.gap / (self.rect.origin.x + self.rect.size.width >= sf.size.width ? 1 : 2);
        nr.size.width -= gap;

        gap = self.manager.gap / (self.rect.origin.y == 0 ? 1 : 2);
        nr.origin.y += gap;
        nr.size.height -= gap;
        
        gap = self.manager.gap / (self.rect.origin.y + self.rect.size.height >= sf.size.height ? 1 : 2);
        nr.size.height -= gap;
        
        return nr;
}

@end
