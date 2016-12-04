//
//  iTermTilingFrame.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingFrame.h"

@implementation iTermTilingFrameBorder

@synthesize borderWidth;
@synthesize cornerRadius;
@synthesize borderColor;

- (void)drawRect:(NSRect)dirtyRect
{
        NSBezierPath *bpath = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, ceil(self.borderWidth / 2), ceil(self.borderWidth / 2)) xRadius:self.cornerRadius yRadius:self.cornerRadius];
        
        [self.borderColor set];
        [bpath setLineWidth:self.borderWidth];
        [bpath stroke];
}

@end

@implementation iTermTilingFrame

@synthesize borderWindow;
@synthesize border;
@synthesize numberLabel;
@synthesize rect;
@synthesize windows;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)manager
{
        if (!(self = [super init]))
                return nil;
        
        self.manager = manager;
        self.rect = _rect;
        self.windows = [[NSMutableArray alloc] init];
        
        self.borderWindow = [[NSWindow alloc] initWithContentRect:self.rect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreRetained defer:YES];
        self.borderWindow.opaque = NO;
        self.borderWindow.backgroundColor = [NSColor clearColor];
        self.borderWindow.ignoresMouseEvents = YES;
        self.borderWindow.hasShadow = NO;
        //self.borderWindow.level = NSFloatingWindowLevel;
        
        self.numberLabel = [[NSTextView alloc] init];
        self.numberLabel.textColor = [NSColor textColor];
        self.numberLabel.string = @"";
        self.numberLabel.textContainerInset = NSMakeSize(5, 5);
        self.numberLabel.textContainer.maximumNumberOfLines = 1;
        [self.borderWindow.contentView addSubview:self.numberLabel];
        
        self.border = [[iTermTilingFrameBorder alloc] initWithFrame:self.borderWindow.contentView.bounds];
        self.border.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.border.borderWidth = [manager borderWidth];
        self.border.cornerRadius = [manager cornerRadius];
        [self.borderWindow.contentView addSubview:self.border];

        [self updateFrame];
        [self.borderWindow orderFront:nil];
        
        return self;
}

- (NSString *)description
{
        return [NSString stringWithFormat:@"iTermTilingFrame: %p rect=%@ windows=%lu", self, NSStringFromRect(self.rect), (unsigned long)[[self windows] count]];
}

- (void)addWindow:(iTermTilingWindow *)window
{
        [window setFrame:self];
        [[self windows] addObject:window];
        [self updateFrame];
}

- (void)removeWindow:(iTermTilingWindow *)window
{
        [window setFrame:nil];
        [[self windows] removeObject:window];
        [self updateFrame];
}

- (void)focusFrontWindow
{
        if ([[self windows] count] == 0)
                return;
        
        iTermTilingWindow *win = [[self windows] objectAtIndex:0];
        if (win)
                [win focus];
}

- (void)unfocusFrontWindow
{
        if ([[self windows] count] == 0)
                return;
        
        iTermTilingWindow *win = [[self windows] objectAtIndex:0];
        if (win)
                [win unfocus];
}

- (void)setRect:(CGRect)_rect
{
        rect = _rect;
        [self redraw];
}

- (void)redraw
{
        [self updateFrame];
        [[self windows] enumerateObjectsUsingBlock:^(iTermTilingWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj adjustToFrame];
        }];
        [self.borderWindow orderFront:nil];
}

- (void)updateFrame
{
        NSColor *borderColor;

        [[self border] setBorderWidth:[self.manager borderWidth]];
        [[self border] setCornerRadius:[self.manager cornerRadius]];
        
        if ([[self windows] count] > 0) {
                if ([[self.manager currentFrame] isEqualTo:self])
                        borderColor = [self.manager activeFrameBorderColor];
                else
                        borderColor = [self.manager inactiveFrameBorderColor];
        } else
                borderColor = [NSColor clearColor];
        
        [[self border] setBorderColor:borderColor];
        [[self borderWindow] setFrame:[self rectForWindowInsetBorder:NO] display:YES];
        [[self border] setNeedsDisplay:YES];
        
        if ([[self manager] showingFrameNumbers]) {
                [[self numberLabel] setHidden:NO];
                [[self numberLabel] setFrame:NSMakeRect(self.border.borderWidth, self.borderWindow.frame.size.height - 10, 200, 10)];
                [[self numberLabel] setString:[NSString stringWithFormat:@"%lu", (unsigned long)self.manager.frames.count]];
                for (int i = 0; i < self.manager.frames.count; i++) {
                        if ([[self.manager.frames objectAtIndex:i] isEqualTo:self]) {
                                self.numberLabel.string = [NSString stringWithFormat:@"%d", i];
                                break;
                        }
                }
                [[self numberLabel] sizeToFit];
                CGRect textRect = [[self numberLabel].string boundingRectWithSize:CGSizeMake([self numberLabel].frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:nil context:nil];
                [[self numberLabel] setFrame:NSMakeRect(self.border.borderWidth, self.borderWindow.frame.size.height - self.numberLabel.frame.size.height - self.border.borderWidth, (self.numberLabel.textContainerInset.width * 4) + textRect.size.width, self.numberLabel.frame.size.height)];
                [[self numberLabel] setNeedsDisplay:YES];
        } else {
                [[self numberLabel] setHidden:YES];
        }
}

- (CGRect)rectForWindowInsetBorder:(BOOL)inset
{
        CGRect sf = [[NSScreen mainScreen] visibleFrame];
        CGFloat gap;
        CGRect nr = self.rect;
        
        if (inset)
                nr = CGRectInset(nr, [[self manager] borderWidth], [[self manager] borderWidth]);
        
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
