//
//  constants.h
//  MahJong
//
//  Created by Zhou Weikuan on 10-12-26.
//  Copyright 2010 sino. All rights reserved.
//

enum {
    kMinWidth = 950,
    kMinHeight = 800,
	kLayerBack = 0,
	kLayerCard = 1,
    kLayerDesc = 2,

};
extern CGSize WinSize;
extern void loadConstants();
extern NSString * cardAtIndex(int idx);

extern int buffDiffX;
extern int recyDiffX;
extern CGPoint buffFirstPos;
extern CGPoint recyFirstPos;

extern CGPoint cardFirstPos;
extern CGPoint cardDiffPos;
extern CGPoint cardIndexPos;
extern int     cardIndexDiff;

extern CGPoint togglePos, adPos;
extern CGPoint newGamePos, restartGamePos, undoPos, posGames, posFacebook, posTwitter, hintPos;
extern CGPoint curGameNoPos;
extern CGPoint stepInfoPos;

extern float   fontSize;
extern float   kMoveTime;
extern float   buttonLayerHeight;