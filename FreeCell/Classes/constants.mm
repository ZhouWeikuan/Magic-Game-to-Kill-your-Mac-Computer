//
//  constants.mm
//  MahJong
//
//  Created by Zhou Weikuan on 10-12-26.
//  Copyright 2010 sino. All rights reserved.
//

#import "constants.h"
#import "cocos2d.h"

CGSize WinSize;

int buffDiffX;
int recyDiffX;
CGPoint buffFirstPos;
CGPoint recyFirstPos;

CGPoint cardFirstPos;
CGPoint cardDiffPos;

CGPoint cardIndexPos;
int     cardIndexDiff;

CGPoint togglePos, adPos;
CGPoint newGamePos, restartGamePos, undoPos, posGames, posFacebook, posTwitter, hintPos;
CGPoint curGameNoPos;
CGPoint stepInfoPos;

float   fontSize;
float   kMoveTime       =   0.2f;
float   buttonLayerHeight;

void loadConstants() {
    buffDiffX       = 86;
    buffFirstPos    = ccp(141+91-56,  670);
    recyDiffX       = 86;
    recyFirstPos    = ccp(551+91-56, 670);
    
    curGameNoPos    = ccp(260+106, 775);
    stepInfoPos     = ccp(620+121, 775);
    
    cardFirstPos    = ccp(141+91-56, 486);
    cardDiffPos     = ccp(94, -32);
    
    cardIndexPos    = ccp(50+91+91-56, 577.5);  //num
    cardIndexDiff   = 56;
    
    togglePos       =   ccp(475+91-56, 670);
    
    /*newGamePos      =   ccp(80+91, 40);
    restartGamePos  =   ccp(160+91, 40);
    undoPos         =   ccp(240+91, 40);
    hintPos         =   ccp(475, 40);
    posGames        =   ccp(619, 40);
    posFacebook     =   ccp(699, 40);
    posTwitter      =   ccp(779, 40);*/
    
    newGamePos      =   ccp(40, 704);
    restartGamePos  =   ccp(40, 624);
    undoPos         =   ccp(40, 544);
    hintPos         =   ccp(40, 400);
    posGames        =   ccp(40, 256);
    posFacebook     =   ccp(40, 176);
    posTwitter      =   ccp(40, 96);
    fontSize	= 40;
    buttonLayerHeight = 80;
    adPos    = ccp(384, 400);
}

NSString * cardAtIndex(int idx) {
	if (idx >=2 && idx <= 10) {
		return [NSString stringWithFormat:@"%d", idx];
	} else if (idx == 1) {
		return @"A";
	} else if (idx == 11) {
		return @"J";
	} else if (idx == 12) {
		return @"Q";
	} else if (idx == 13) {
		return @"K";
	}
	return @"0";
}

