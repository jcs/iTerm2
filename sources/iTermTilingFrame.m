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
@synthesize numberLabelHolder;
@synthesize numberLabel;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)manager
{
        if (!(self = [super init]))
                return nil;
        
        self.manager = manager;
        self.rect = _rect;
        
        self.numberLabelHolder = [[NSWindow alloc] initWithContentRect:_rect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreRetained defer:YES];
        self.numberLabelHolder.opaque = NO;
        self.numberLabelHolder.backgroundColor = [NSColor clearColor];
        self.numberLabelHolder.ignoresMouseEvents = YES;
        self.numberLabelHolder.hasShadow = NO;
        self.numberLabelHolder.level = NSFloatingWindowLevel;

        self.numberLabel = [[NSTextView alloc] init];
        self.numberLabel.textColor = [NSColor textColor];
        self.numberLabel.string = @"";
        self.numberLabel.textContainerInset = NSMakeSize(5, 5);
        self.numberLabel.textContainer.maximumNumberOfLines = 1;
        self.numberLabel.editable = NO;
        self.numberLabel.selectable = NO;
        self.numberLabel.horizontallyResizable = YES;
        self.numberLabel.verticallyResizable = NO;
        [self.numberLabelHolder.contentView addSubview:self.numberLabel];
        
        return self;
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingFrame: %p rect=%@ rectForWindow=%@ windows=%lu", self, NSStringFromRect(self.rect), NSStringFromRect(self.rectForWindow), (unsigned long)[[self windows] count]];
}

- (NSArray<iTermTilingWindow *> *)windows
{
        NSMutableArray *wins = [[NSMutableArray alloc] init];
        
        for (int i = 0; i < [[[self manager] windows] count]; i++) {
                iTermTilingWindow *w = [[[self manager] windows] objectAtIndex:i];
                if ([[w frame] isEqualTo:self])
                        [wins addObject:w];
        }
        
        return [NSArray arrayWithArray:wins];
}

- (iTermTilingWindow *)frontWindow
{
        if ([[self windows] count] > 0) {
                iTermTilingWindow *win = [[self windows] objectAtIndex:0];
                if (win)
                        return win;
        }
        
        return nil;
}

- (void)focusFrontWindowAndMakeKey:(BOOL)key
{
        iTermTilingWindow *win = [self frontWindow];
        if (win)
                [win focusAndMakeKey:(BOOL)key];
}

- (void)unfocusFrontWindow
{
        iTermTilingWindow *win = [self frontWindow];
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
        
        NSArray *wins = [[self manager] windowsNotInFront];
        if ([wins count] == 0) {
                [iTermTilingToast showToastWithMessage:@"No other windows" inFrame:self];
                return;
        }
        
        if (![[self manager] startAdjustingFrames])
                return;
        
        iTermTilingWindow *cur = [[[self manager] windows] objectAtIndex:0];
        [[[self manager] windows] removeObject:cur];
        
        iTermTilingWindow *new = nil;
        if (forward) {
                /* normal cycle, shift first window onto the end of the stack */
                new = [wins objectAtIndex:0];
        } else {
                /* previous cycle, move last window onto the front */
                new = [wins lastObject];
        }
        
        [[[self manager] windows] removeObject:new];
        [new setFrame:self];
        [[[self manager] windows] insertObject:new atIndex:0];
        
        [[[self manager] windows] addObject:cur];
        
        [self focusFrontWindowAndMakeKey:YES];
        
        [[self manager] finishAdjustingFrames];
}

- (void)cycleLastWindow
{
        if ([[[self manager] windows] count] == 0) {
                [iTermTilingToast showToastWithMessage:@"No managed windows" inFrame:self];
                return;
        }
        
        NSArray *wins = [[self manager] windowsNotInFront];
        if ([wins count] == 0) {
                [iTermTilingToast showToastWithMessage:@"No other windows" inFrame:self];
                return;
        }

        if (![[self manager] startAdjustingFrames])
                return;

        /* bring the first window not foremost in another frame to the forefront of this one */
        iTermTilingWindow *w = [wins objectAtIndex:0];
        [[[self manager] windows] removeObject:w];
        [[[self manager] windows] insertObject:w atIndex:0];
        [w setFrame:self];
        [self focusFrontWindowAndMakeKey:YES];
        
        [[self manager] finishAdjustingFrames];
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
        
        if ([[self manager] showingFrameNumbers]) {
                [[self numberLabel] setString:[NSString stringWithFormat:@"%lu", [[[self manager] frames] indexOfObject:self]]];

                CGRect textRect = [[self numberLabel].string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:nil context:nil];
                textRect = NSMakeRect(0, 0, ceilf(([[self numberLabel] textContainerInset].width * 2) + textRect.size.width + 10), ceilf(textRect.size.height));

                [[self numberLabel] setFrame:NSMakeRect([[self manager] borderWidth], [[self manager] borderWidth], textRect.size.width, textRect.size.height + ([[self manager] borderWidth] * 2))];
                
                [[self numberLabelHolder] setFrame:NSMakeRect(self.rect.origin.x,
                                                              self.rect.origin.y + self.rect.size.height - [[self numberLabel] frame].size.height - ([[self manager] borderWidth] * 2),
                                                              [[self numberLabel] frame].size.width + ([[self manager] borderWidth] * 2),
                                                              [[self numberLabel] frame].size.height + ([[self manager] borderWidth] * 2))
                                           display:YES];
                [[self numberLabelHolder] setBackgroundColor:[[self manager] activeFrameBorderColor]];
                [[self numberLabelHolder] orderFrontRegardless];
        } else {
                [[self numberLabelHolder] orderOut:nil];
        }
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
