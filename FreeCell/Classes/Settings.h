//
//  Settings.h
//  WhacAMole
//
//  Created by Zhou Weikuan on 11-2-24.
//  Copyright 2011 sino. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject {

}

+ (int) getCurGameNo;
+ (void) setCurGameNo:(int) gameNo;


+ (void) incPassCount;
+ (int) getPassCount;

@end
