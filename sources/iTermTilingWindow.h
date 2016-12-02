//
//  iTermTilingWindow.h
//  iTerm2
//
//  Created by joshua stein on 12/2/16.
//
//

#import <Foundation/Foundation.h>
#import "iTermWeakReference.h"
#import "PseudoTerminal.h"
#import "iTermTilingFrame.h"

@class iTermTilingFrame;

@interface iTermTilingWindow : NSObject

@property (nonatomic, retain) PseudoTerminal<iTermWeakReference> *terminal;
@property (nonatomic, retain) iTermTilingFrame *frame;
- (id)initForTerminal:(PseudoTerminal *)terminal;
- (void)adjustToFrame;

@end
