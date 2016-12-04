//
//  iTermTilingToast.h
//  iTerm
//
//  Created by George Nachman on 3/13/13.
//
//

#import <Cocoa/Cocoa.h>
#import "iTermTilingFrame.h"

@interface iTermTilingToast : NSWindowController {
        BOOL hiding_;
        NSTimer *hideTimer_;
}

+ (void)showToastWithMessage:(NSString *)message inFrame:(iTermTilingFrame *)frame;
+ (void)hideAllToasts;

@end
