//
//  soundMgr.h
//  CronlyJewels
//
//  Created by Zhou Weikuan on 10-12-15.
//  Copyright 2010 sino. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundApp : NSObject {

}

+ (void) playEffect:(NSString*)key;
+ (void) playBackground:(NSString*)back;
+ (void) playBackground:(NSString*)back once:(BOOL)one;
+ (void) stopBackground;

@end
