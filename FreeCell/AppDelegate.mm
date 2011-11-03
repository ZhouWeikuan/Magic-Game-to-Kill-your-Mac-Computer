//
//  AppDelegate.m
//  FreeCell
//
//  Created by Zhou Weikuan on 11-6-29.
//  Copyright CronlyGames 2011å¹´® All rights reserved.
//

#import "AppDelegate.h"
#import "GameScene.h"
#import "constants.h"
#import "CronlyGames.h"

@implementation FreeCellAppDelegate
@synthesize window=window_, glView=glView_;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	
	[director setDisplayFPS:NO];
    
	WinSize       = NSSizeToCGSize(glView_.frame.size);
    glView_.frame = NSMakeRect(0, 0, kMinWidth, kMinHeight);
	
	[director setOpenGLView:glView_];

	// EXPERIMENTAL stuff.
	// 'Effects' don't work correctly when autoscale is turned on.
	// Use kCCDirectorResize_NoScale if you don't want auto-scaling.
	[director setResizeMode:kCCDirectorResize_AutoScale];
	
	// Enable "moving" mouse event. Default no.
	[window_ setAcceptsMouseMovedEvents: YES];
    
    srand(uint(time(NULL)));
    srandom(time(0));
	loadConstants();
    
    CCSpriteFrameCache * cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    
    NSString * cardName = @"card.png";
    NSString * cardPlist= @"card.plist";
    cardName = @"card.png";
    cardPlist= @"card.plist";
    /*} else if (isRetina()) {
        cardName = @"card@2x.png";
        cardPlist= @"card@2x.plist";
    } else {
        cardName = @"card~iphone.png";
        cardPlist= @"card~iphone.plist";
    }*/
    CCTexture2D * cardTex = [[CCTextureCache sharedTextureCache] addImage: cardName];
    [cache addSpriteFramesWithFile: cardPlist texture: cardTex];	
	
	[director runWithScene:[GameScene scene]];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
	return YES;
}

- (void)dealloc
{
	[[CCDirector sharedDirector] end];
	[window_ release];
	[super dealloc];
}

#pragma mark AppDelegate - IBActions

- (IBAction)toggleFullScreen: (id)sender
{
	CCDirectorMac *director = (CCDirectorMac*) [CCDirector sharedDirector];
	[director setFullScreen: ! [director isFullScreen] ];
}

@end
