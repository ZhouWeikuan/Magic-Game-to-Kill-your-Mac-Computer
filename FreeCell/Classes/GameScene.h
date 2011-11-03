//
//  HelloWorldLayer.h
//  FreeCell
//
//  Created by Zhou Weikuan on 11-1-4.
//  Copyright sino 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Board.h"
// #import "AdMobDelegateProtocol.h"
//#import "iAd/ADBannerView.h"

// HelloWorld Layer
@interface GameScene : CCLayer
{
	BOOL     running;
	Board    board;
@public	
    CCColorLayer    * buttonLayer;
    
@protected    
	CCMenuItem * cardIndexes[13];
    int         selIndex;
    
	CCLabelTTF * lblStepInfo;
    
    int selCol;
    CGPoint diffPos, touchPos;
    NSMutableArray * selCards;
}
// @property (nonatomic, retain) id iAdView;
// @property (nonatomic, retain) AdMobView * mobView;
// - (void) requestAdMob;
//- (void) request_iAd;

@property (nonatomic, retain) NSMutableArray * selCards;
@property (assign) BOOL running;

// returns a Scene that contains the HelloWorld as the only child
+(id) scene;

- (void) indexClicked:(id)sender;
- (void) undoOneStep:(id)sender;
- (void) newGame:(id)sender;
- (void) restartGame:(id)sender;
- (void) toggleButtons:(id)sender;

- (void) showHints:(id)sender;
- (void) showGames:(id)sender;
- (void) goFacebook:(id)sender;
- (void) goTwitter:(id)sender;

- (void) postMove:(id)sender;
- (void) back_handleTouch:(NSValue *)val;
- (void) back_handleMoved:(NSValue *)val;
- (void) back_handleEnded:(NSValue *)val;
- (void) back_handleCancel;

- (uint) moveCards:(uint)cnt to:(uint)dst;
- (void) handleTouch:(NSValue *)val;
- (void) handleMoved:(NSValue *)val;
- (void) handleEnded:(NSValue *)val;
- (void) handleCancel;
- (void) restoreCardsPos;

- (void) issueMsg:(NSString*)msg title:(NSString*)title;

- (void) updateStepInfo:(NSNumber *)num;
- (void) showWinMsg;

@end
