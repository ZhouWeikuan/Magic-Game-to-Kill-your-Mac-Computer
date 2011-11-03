//
//  HelloWorldLayer.m
//  FreeCell
//
//  Created by Zhou Weikuan on 11-1-4.
//  Copyright sino 2011. All rights reserved.
//

// Import the interfaces
#import "Datatype.h"
#import "GameScene.h"
#import "constants.h"
#import "CronlyGames.h"
#import "SoundApp.h"
//#import "GameKitWrapper.h"
//#import "Reachability.h"
#import "AppDelegate.h"
#import "Settings.h"

static BOOL replay = false;

// HelloWorld implementation
@implementation GameScene
@synthesize selCards, running;
// @synthesize iAdView;
// @synthesize mobView;

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameScene *layer = [GameScene node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
        self.selCards = nil;
        
		CGSize size = WinSize;
        if (size.width < kMinWidth) {
            self.scaleX = size.width / kMinWidth;
        }
        if (size.height < kMinHeight) {
            self.scaleY = size.height / kMinHeight;
        }
        self.anchorPoint = CGPointZero;
        self.position = CGPointZero;
        size = [[CCDirector sharedDirector] winSize];
        
        CCSprite *sprite = [CCSprite spriteWithFile:@"main_bg.png"]; 
        [self addChild:sprite z:0];
        sprite.position = ccp(size.width*0.5f, 0);
        sprite.anchorPoint = ccp(0.5f, 0);
        
        buttonLayer = [CCColorLayer layerWithColor:ccc4(0x33, 0x33, 0x66, 0xaa) width:buttonLayerHeight height: size.height];
        [self addChild:buttonLayer z:2];
        buttonLayer.position = ccp(0, 0);
        buttonLayer.tag = 0;
        buttonLayer.anchorPoint = CGPointZero;
        
        /*id act = [CCMoveTo actionWithDuration:1.5f position:ccp(0, size.height)];
        [buttonLayer runAction: act];*/
        
		CCMenu * menu = [CCMenu menuWithItems: nil];
		[self addChild: menu z:0];
		menu.position = ccp(0, 0);
        
        /*CCMenuItem * item = [self addFrameCacheMenuItem:@"info.png" sele:@"info_hover.png" call:@selector(toggleButtons:) pos:togglePos];
        [menu addChild:item];*/
        
        selIndex = 0;
		for (int i=0; i<13; ++i) {
			NSString * str = cardAtIndex(i+1);
            NSString * strD = [NSString stringWithFormat:@"btn_%@.png", str];
            NSString * strH = [NSString stringWithFormat:@"btn_%@_hover.png", str];
			cardIndexes[i] = [self addFrameCacheMenuItem:strD sele:strH call:@selector(indexClicked:)
                                           pos:ccp(cardIndexPos.x + cardIndexDiff*i, cardIndexPos.y)];
			cardIndexes[i].tag = -(i+1);
			[menu addChild:cardIndexes[i] z:kLayerBack];
		}
        
		lblStepInfo = [CCLabelTTF labelWithString:@"00" fontName:@"Marker Felt" fontSize:fontSize];
		[self addChild:lblStepInfo z: 1];
        lblStepInfo.anchorPoint = ccp(0, 0.5f);
		lblStepInfo.position = stepInfoPos;
        
        board.gameScene = self;
        board.menu		= menu;
	}
	
    
    running = true;
	self.isMouseEnabled = YES;
    
    
    CCMenu * menu = [CCMenu menuWithItems: nil];
    [buttonLayer addChild: menu z:1];
    menu.position = ccp(0, 0);

    CCMenuItem * item = [self addMenuItem:@"new.png" sele:@"new_hover.png" call:@selector(newGame:) pos:newGamePos];
    [menu addChild: item];
    
    item = [self addMenuItem:@"restart.png" sele:@"restart_hover.png"
                        call:@selector(restartGame:) pos:restartGamePos];
    [menu addChild: item];
    
    item = [self addMenuItem:@"undo.png" sele:@"undo_hover.png"
                        call:@selector(undoOneStep:) pos:undoPos];
    [menu addChild: item];
	
    item = [self addMenuItem:@"fruitlink.png" sele:@"fruitlink.png"
                        call:@selector(showGames:) pos:posGames];
    [menu addChild: item];
    item.scale = 0.7f;
    
    item = [self addMenuItem:@"facebook.png" sele:@"facebook_hover.png"
                                  call:@selector(goFacebook:) pos:posFacebook];
    [menu addChild: item];
    item.scale = 0.76f;
    
    item = [self addMenuItem:@"twitter.png" sele:@"twitter_hover.png"
                                  call:@selector(goTwitter:) pos:posTwitter];
    [menu addChild: item];
    item.scale = 0.7f;

    item = [self addFrameCacheMenuItem:@"hint.png" sele:@"hint_hover.png"
                        call:@selector(showHints:) pos: hintPos];
    [menu addChild: item];

	return self;
}

- (void) onEnter {
	[super onEnter];

    [SoundApp playBackground:@"back.mp3"];
    
	board.StartGame();
}

- (void) onExit {
    [[CCDirector sharedDirector] purgeCachedData];
    
	[super onExit];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc {
    self.selCards = nil;
    
    
    //self.iAdView    = nil;
    // self.mobView.delegate = nil;
    // self.mobView    = nil;

    [[CCDirector sharedDirector] purgeCachedData];
	// don't forget to call "super dealloc"
	[super dealloc];
}

# pragma mark AdMob & iAd support
/*
- (void)didReceiveAd:(AdMobView *)view {
    // put the ad at the top middle of the screen in landscape mode
    NSLog(@"AdMob: Did receive AD");
    
    view.center = adPos;
    
    if (viewController != nil) {
        [viewController.view addSubview:view];
    }
}

// Sent when an ad request failed to load an ad
- (void)didFailToReceiveAd:(AdMobView *)view {
    NSLog(@"AdMob: Did fail to receive ad in AdViewController");
}

- (UIViewController *)currentViewControllerForAd:(AdMobView *)adView {
    return viewController;
}

- (NSString *) publisherIdForAd:(AdMobView *)adView {
    return arc4random()%3==1?@"a14daad7f0a3d55":@"a14daad78ae59c9";
}
- (void) requestAdMob {
    if (mobView != nil)
        return;
    
    Reachability * r = [Reachability reachabilityForInternetConnection];
    if (![r isReachable])
        return;
    
    NSLog(@"requesting AdMob.");
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.mobView = [AdMobView requestAdOfSize:ADMOB_SIZE_748x110 withDelegate:self];
    } else {
        self.mobView = [AdMobView requestAdOfSize:ADMOB_SIZE_320x48 withDelegate:self];
    }
}
*/
/*
- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    NSLog(@"got new iAd");
    if (!isIAdVisible) {
        [[viewController.view subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
        self.mobView = nil;
        
        isIAdVisible = YES;
        
        banner.center = adPos;
        [viewController.view addSubview:banner];
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"failed to get iAd");
    if (isIAdVisible) {
        isIAdVisible = NO;
        [banner removeFromSuperview];
    }
    [self requestAdMob];
}

- (void) request_iAd {
    Class classAdBannerView = NSClassFromString(@"ADBannerView");
    if (classAdBannerView != nil) {
        NSLog(@"requesting iAd.");
        ADBannerView * view = [[ADBannerView alloc] initWithFrame:CGRectZero];
        id obj = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            obj = ADBannerContentSizeIdentifierPortrait;
        } else {
            obj = ADBannerContentSizeIdentifier320x50;
        }
        NSSet * set = [NSSet setWithObjects: obj, nil];
        [view setRequiredContentSizeIdentifiers: set];
        [view setCurrentContentSizeIdentifier:obj];
        [view setDelegate:self];
        self.iAdView = view;
        [view release];
    } else {
        [self requestAdMob];
    }
}
*/

#pragma mark -
#pragma mark Touches Handling
- (void) postMove:(id)sender {
    // run in background
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    Sleep(1000 * kMoveTime * 1.2f);
    //@synchronized(self) {
        board.PostMove();
    //}
    [pool release];
}
- (void) back_handleTouch:(NSValue *)val {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    //@synchronized(self) {
        [self handleTouch: val];
    //}
    [pool release];
}
- (void) back_handleMoved:(NSValue *)val {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    //@synchronized(self) {
        [self handleMoved: val];
    //}
    [pool release];
}
- (void) back_handleEnded:(NSValue *)val {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    //@synchronized(self) {
        [self handleEnded: val];
    //}
    [pool release];
}
- (void) back_handleCancel {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    //@synchronized(self) {
        [self handleCancel];
    //}
    [pool release];
}

- (uint) moveCards:(uint)cnt to:(uint)dst {
    return board.TryMove(selCol, dst, cnt);
}

- (void) handleTouch:(NSValue *)val {
    CGPoint loc;
    [val getValue:&loc];
    
    int col = board.FindCurCol(loc);
    if (col == 0) {
        self.selCards = nil;
        return;
    }
    if (col == selCol && ccpDistance(touchPos, loc) < cardDiffPos.x * 0.2f) {
        // double click the current column
        uint emptyCol;
        if (board.ColInBuf(col) && board.ColInCard(emptyCol = board.FindEmptyCardCol()) 
            || (board.ColInCard(col) 
                && (board.ColInBuf(emptyCol = board.FindEmptyBuf())
                    || board.ColInCard(emptyCol = board.FindEmptyCardCol())))
            ) {
            //假设发生两个单击动作，第一个动作击中当前双击的地方
            //第二个单击动作击中某空档中央
            col = emptyCol;
            if ([selCards count] > 1) {
                NSRange ran = NSMakeRange(0, [selCards count]-1);
                for (uint s=0; s < [selCards count] -1 ; ++s){
                    CCSprite * obj = [selCards objectAtIndex:s];
                    obj.scale = 1.0f;
                }
                [selCards removeObjectsInRange: ran];
            }            
            [self moveCards:1 to:col];
            
            selCol = 0;
            self.selCards = nil;
            return;
        }
        selCol = 0;
        self.selCards = nil;
    }
    
    if (selCards != nil) {
        // Move cards to the new points
        if ([self moveCards:[selCards count] to: col]) {            
            selCol = 0;
            self.selCards = nil;
            return;
        }
        selCol = 0;
        self.selCards = nil;
    }
    
    int idx = board.FindCardIndexInCol(loc, col);
    if (idx == 0) {
        self.selCards = nil;
    } else {
        self.selCards = board.FindMaxAvailsInCol(col, idx);
        if ([selCards count] == 0){
            self.selCards = nil;
            return;
        }
        CCSprite * obj = (CCSprite*)[selCards objectAtIndex: 0];
        selCol = col;
        diffPos = ccpSub(obj.position, loc);
        touchPos= loc;
    }
}

- (void) handleMoved:(NSValue *)val {
    CGPoint loc;
    [val getValue:&loc];
    
    if (selCards==nil||[selCards count]==0)
        return;
    int i = 0;
    for (id obj in selCards) {
        CCSprite * s = (CCSprite *)obj;
        s.position = ccpAdd(loc, ccp(diffPos.x, diffPos.y + i * cardDiffPos.y));
        ++i;
    }
}

- (void) handleEnded:(NSValue *)val {
    //CGPoint loc = [val CGPointValue];
    CGPoint loc;
    [val getValue:&loc];
    if (selCards==nil||[selCards count]==0) {
        return;
    }
    
    int col = board.FindCurCol(loc);
    
    if (col == selCol || col == 0) {
        // 单击
        [self restoreCardsPos];
        
        selCol = col;
        if (selCol == 0) {
            self.selCards = nil;
        }
    } else {
        // move from one position to other position
        if ([self moveCards:[selCards count] to: col]) {
            // moved
        } else if (ccpDistance(touchPos, loc) > cardDiffPos.x) {
            [self restoreCardsPos];
            if (loc.y > touchPos.y){
                if (loc.x > touchPos.x) {
                    // move to Buff
                } else {
                    // move to Recycle
                }
            } else {
                if (loc.x > touchPos.x) {
                    // move to right card cols
                } else {
                    // move to left card cols;
                }
            }
        } else {
            [self restoreCardsPos];
        }
        
        selCol = 0;
        self.selCards = nil;
    }
}

- (void) handleCancel {
    [self restoreCardsPos];
}

- (void) restoreCardsPos {
    if (selCards == nil || selCol == 0 || [selCards count] == 0) {
        selCol = 0;
        self.selCards = nil;
        return;
    }
    id act = nil;
    if (board.ColInBuf(selCol)) {
        CCSprite * s = (CCSprite*)[selCards objectAtIndex: 0];
        s.scale = 1.0f;
        act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(buffFirstPos.x+(selCol-9)*buffDiffX,
                                                                  buffFirstPos.y)];
        // [s stopAllActions];
        // [s runAction: act];
        s.position = ccp(buffFirstPos.x+(selCol-9)*buffDiffX,
                         buffFirstPos.y);
        return;
    }
    if (board.ColInRecycle(selCol)) {
        CCSprite * s = (CCSprite*)[selCards objectAtIndex: 0];
        s.scale = 1.0f;
        act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(recyFirstPos.x+(selCol-13)*recyDiffX,
                                                                  recyFirstPos.y)];
        // [s stopAllActions];
        // [s runAction: act];
        s.position = ccp(recyFirstPos.x+(selCol-13)*recyDiffX,
                         recyFirstPos.y);
        return;
    }
    int idx = board.m_colNum[selCol] - [selCards count];
    for (id obj in selCards) {
        CCSprite * s = (CCSprite*)obj;
        s.scale = 1.0f;
        
        act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(cardFirstPos.x + cardDiffPos.x * (selCol - 1),
                                                                  cardFirstPos.y + idx * cardDiffPos.y)];
        // [s stopAllActions];
        // [s runAction: act];
        s.position = ccp(cardFirstPos.x + cardDiffPos.x * (selCol - 1),
                         cardFirstPos.y + idx * cardDiffPos.y);
        ++idx;
    }
}

- (BOOL) ccMouseDown:(NSEvent *)theEvent{
    CGPoint loc = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:theEvent];
    loc = [self convertToNodeSpace:loc];
    NSValue * val = [NSValue value:&loc withObjCType:@encode(CGPoint)];
    [self performSelectorInBackground:@selector(back_handleTouch:) withObject: val];
    return true;
}

- (BOOL) ccMouseDragged:(NSEvent *)theEvent{
    CGPoint loc = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:theEvent];
    loc = [self convertToNodeSpace:loc];
    NSValue * val = [NSValue value:&loc withObjCType:@encode(CGPoint)];
    [self performSelectorInBackground:@selector(back_handleMoved:) withObject: val];
    return true;
}

- (BOOL) ccMouseUp:(NSEvent *)theEvent {
	CGPoint loc = [(CCDirectorMac*)[CCDirector sharedDirector] convertEventToGL:theEvent];
    loc = [self convertToNodeSpace:loc];
    NSValue *val = [NSValue value:&loc withObjCType:@encode(CGPoint)];
    [self performSelectorInBackground:@selector(back_handleEnded:) withObject: val];
    return true;
}

//- (void) ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
- (void) ccMouseExited:(NSEvent *)theEvent{
    [self performSelectorInBackground:@selector(back_handleCancel) withObject:nil];
    //return true;
}

#pragma mark -
#pragma mark buttons menu handlers
- (void) indexClicked:(id)sender {
    [SoundApp playEffect:@"click.wav"];
    if (selIndex != 0) {
        board.LabelUnselect(selIndex);
    }
    
    CCMenuItem * it = (CCMenuItem*)sender;
    int idx = -it.tag;
    if (idx == selIndex) {
        selIndex = 0;
    } else {
        board.LabelSelected(idx);
        selIndex = idx;
    }
}

- (void) toggleButtons:(id)sender {
    [SoundApp playEffect:@"click.wav"];

    CGSize size = [[CCDirector sharedDirector] winSize];
    buttonLayer.tag = 1 - buttonLayer.tag;
    //id act = [CCMoveTo actionWithDuration:0.7f position:ccp(0, size.height - buttonLayer.tag * buttonLayerHeight)];
    //[buttonLayer runAction: act];
}

- (void) newGame:(id)sender {
    [SoundApp playEffect:@"newgame.wav"];

    board.OnRand();
    replay = NO;
    
    CCScene * s = [GameScene scene];
    [[CCDirector sharedDirector] replaceScene: [CCTransitionSlideInR transitionWithDuration:0.7f scene: s]];
}

- (void) restartGame:(id)sender {
    [SoundApp playEffect:@"click.wav"];
    replay = YES;
    
    CCScene * s = [GameScene scene];
    [[CCDirector sharedDirector] replaceScene: [CCTransitionSlideInR transitionWithDuration:0.7f scene: s]];
}

- (void) undoOneStep:(id)sender {
    if (!running)
        return;
    [SoundApp playEffect:@"click.wav"];

    board.OnUndo();
}

- (void) showHints:(id)sender {
    if (!running)
        return;
    [SoundApp playEffect:@"click.wav"];
    
    board.OnHelpNextstep();
}

- (void) showGames:(id)sender {
    [SoundApp playEffect:@"click.wav"];
    
    NSString * urlstr = @"macappstore://ax.search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?q=cronlygames";
    NSURL *url = [NSURL URLWithString:urlstr];
    [[NSWorkspace sharedWorkspace] openURL: url];
}

- (void) goFacebook:(id)sender {
    [SoundApp playEffect:@"click.wav"];
    
    NSString * urlstr = @"http://www.facebook.com/pages/CronlyGames/246908508659748";
	NSURL *url = [NSURL URLWithString:urlstr];
	[[NSWorkspace sharedWorkspace] openURL: url];
}

- (void) goTwitter:(id)sender {
    [SoundApp playEffect:@"click.wav"];
    
    NSString * urlstr = @"http://twitter.com/#!/cronlygames";
	NSURL *url = [NSURL URLWithString:urlstr];
	[[NSWorkspace sharedWorkspace] openURL: url];
}


- (void) issueMsg:(NSString*)msg title:(NSString*)title {
    NSAlert * alert = [NSAlert alertWithMessageText:NSLocalizedString(title, nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(msg, nil)];

    alert.delegate = nil;
    [alert runModal];
}

- (void) updateStepInfo:(NSNumber *)num {
    int s = [num intValue];
	NSString * str = [NSString stringWithFormat:@"%02d", s];
	lblStepInfo.string = str;
    lblStepInfo.tag = s;
}

- (void) showWinMsg {
    running = false;
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    CCLabelTTF * lbl = [CCLabelTTF labelWithString:@"You win!" fontName:@"Marker Felt" fontSize: fontSize];
    [self addChild: lbl z:1];
    lbl.position = ccp(size.width * 0.5f, size.height * 0.5f);
    lbl.color    = ccRED;
    
    if (buttonLayer.tag == 0) {
        [self toggleButtons: self];
    }
    
    if (!replay) {
        [Settings incPassCount];
        //int t = [Settings getPassCount];
        //[[GameKitWrapper sharedWrapper] reportScore:t forCategory:@"com.cronlygames.freecell.passcount"];
    }
}

@end
