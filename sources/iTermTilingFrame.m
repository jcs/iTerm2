//
//  iTermTilingFrame.m
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import "iTermTilingFrame.h"

/* iTermTilingFrameBorder */
@implementation iTermTilingFrameBorder

@synthesize borderWidth;
@synthesize cornerRadius;
@synthesize borderColor;

- (void)drawRect:(NSRect)dirtyRect
{
        NSBezierPath *bpath = [NSBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, self.borderWidth / 2, self.borderWidth / 2) xRadius:self.cornerRadius yRadius:self.cornerRadius];
        
        [self.borderColor set];
        
        [bpath setLineWidth:self.borderWidth];
        [bpath stroke];
}

@end

/* iTermTilingFrame containing multiple iTermTilingWindow objects */
@implementation iTermTilingFrame

@synthesize borderWindow;
@synthesize border;
@synthesize rect;
@synthesize windows;

- (id)initWithRect:(CGRect)_rect andManager:(iTermTilingManager *)manager
{
        if (!(self = [super init]))
                return nil;
        
        self.manager = manager;
        self.rect = _rect;
        self.windows = [[NSMutableArray alloc] init];
        
        self.borderWindow = [[NSWindow alloc] initWithContentRect:self.rect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
        self.borderWindow.opaque = NO;
        self.borderWindow.backgroundColor = [NSColor clearColor];
        self.borderWindow.ignoresMouseEvents = YES;
        self.borderWindow.level = CGWindowLevelForKey(kCGFloatingWindowLevelKey);
        self.borderWindow.hasShadow = NO;
        self.borderWindow.releasedWhenClosed = NO;
        
        self.border = [[iTermTilingFrameBorder alloc] initWithFrame:self.borderWindow.contentView.bounds];
        self.border.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.border.borderWidth = [manager borderWidth];
        self.border.cornerRadius = [manager cornerRadius];
        [self.borderWindow.contentView addSubview:self.border];
        
        [self updateFrame];
        [self.borderWindow makeKeyAndOrderFront:nil];
        
        return self;
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

- (void)updateFrame
{
        [[self border] setBorderWidth:[self.manager borderWidth]];
        [[self border] setCornerRadius:[self.manager cornerRadius]];
        [[self border] setBorderColor:[[self.manager currentFrame] isEqualTo:self] ? [self.manager activeFrameBorderColor] : [NSColor grayColor]];

        [[self borderWindow] setFrame:CGRectInset(self.rectForWindow, -self.border.borderWidth, -self.border.borderWidth) display:YES];
        [[self border] setNeedsDisplay:YES];
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
}

- (CGRect)rectForWindow
{
        return CGRectInset(self.rect, self.manager.gap / 2, self.manager.gap / 2);
}

- (void)horizontalSplit
{
        /* split the current frame into two, left and right (becoming left position) */
        NSRect oldRect = [self rect];
        NSRect newCurRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y, (oldRect.size.width / 2), oldRect.size.height);
        NSRect newNewRect = NSMakeRect(newCurRect.origin.x + newCurRect.size.width, oldRect.origin.y, oldRect.size.width - newCurRect.size.width, oldRect.size.height);

        [self setRect:newCurRect];

        iTermTilingFrame *newFrame = [[iTermTilingFrame alloc] initWithRect:newNewRect andManager:self.manager];
        [self.manager.frames addObject:newFrame];
}

- (void)verticalSplit
{
        /* split the current frame into two, top and bottom (becoming top position) */
        NSRect oldRect = [self rect];
        NSRect newCurRect = NSMakeRect(oldRect.origin.x, oldRect.origin.y + (oldRect.size.height / 2), oldRect.size.width, oldRect.size.height / 2);
        NSRect newNewRect = NSMakeRect(newCurRect.origin.x, oldRect.origin.y, oldRect.size.width, oldRect.size.height - newCurRect.size.height);
        
        [self setRect:newCurRect];
        
        iTermTilingFrame *newFrame = [[iTermTilingFrame alloc] initWithRect:newNewRect andManager:self.manager];
        [self.manager.frames addObject:newFrame];
}

@end
