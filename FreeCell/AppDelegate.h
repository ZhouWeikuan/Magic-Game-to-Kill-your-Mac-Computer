//
//  AppDelegate.h
//  FreeCell
//
//  Created by Zhou Weikuan on 11-6-29.
//  Copyright CronlyGames 2011年. All rights reserved.
//

#import "cocos2d.h"

@interface FreeCellAppDelegate : NSObject <NSApplicationDelegate>
{
	NSWindow	*window_;
	MacGLView	*glView_;
}

@property (assign) IBOutlet NSWindow	*window;
@property (assign) IBOutlet MacGLView	*glView;

- (IBAction)toggleFullScreen:(id)sender;

@end
