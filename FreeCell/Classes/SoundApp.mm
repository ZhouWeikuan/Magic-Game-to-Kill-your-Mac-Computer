//
//  soundMgr.mm
//  CronlyJewels
//
//  Created by Zhou Weikuan on 10-12-15.
//  Copyright 2010 sino. All rights reserved.
//

#import "SoundApp.h"
#import "SimpleAudioEngine.h"
#import "Settings.h"

@implementation SoundApp

+ (void) playEffect:(NSString*)key {
    [[SimpleAudioEngine sharedEngine] playEffect: key];
}
+ (void) stopBackground {
    SimpleAudioEngine * engine = [SimpleAudioEngine sharedEngine];
	if ([engine isBackgroundMusicPlaying]) {
		[engine stopBackgroundMusic];
	}
}

+ (void) playBackground:(NSString*)back once:(BOOL)one {
    [self stopBackground];
    
	SimpleAudioEngine * engine = [SimpleAudioEngine sharedEngine];
    [engine setBackgroundMusicVolume:0.7f];
    if (one) {
        [engine playBackgroundMusic:back loop: NO];
    } else {
        [engine playBackgroundMusic:back];
    }
    [engine setBackgroundMusicVolume:0.7f];

}
+ (void) playBackground:(NSString*)back {
    [self playBackground:back once: NO];
}


@end
