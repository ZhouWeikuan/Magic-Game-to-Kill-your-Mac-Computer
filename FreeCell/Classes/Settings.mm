//
//  Settings.mm
//  WhacAMole
//
//  Created by Zhou Weikuan on 11-2-24.
//  Copyright 2011 sino. All rights reserved.
//

#import "Settings.h"

#define keyGameNo @"freecell.gameNo"
#define keyPassCount @"freecell.passCount"

@implementation Settings

+ (int) getCurGameNo {
    int t = [[NSUserDefaults standardUserDefaults] integerForKey: keyGameNo];
    if (t == 0) {
        t = 1234567;
    }
    return t;
}

+ (void) setCurGameNo:(int) gameNo {
    [[NSUserDefaults standardUserDefaults] setInteger: gameNo forKey: keyGameNo];
}


+ (void) incPassCount {
    int t = 1 + [self getPassCount];
    [[NSUserDefaults standardUserDefaults] setInteger:t forKey: keyPassCount];
}

+ (int) getPassCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey: keyPassCount];
}

@end
