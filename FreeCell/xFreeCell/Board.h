/*
 *  Board.h
 *  FreeCell
 *
 *  Created by Zhou Weikuan on 11-3-3.
 *  Copyright 2011 sino. All rights reserved.
 *
 */
#import "cocos2d.h"
#import "Datatype.h" 
#import <vector>

@class GameScene;
class Board {
public:
	Board();
	~Board();
	
	void StartGame();
	void EndGame();
	
	void LabelSelected(int lbl);
	void LabelUnselect(int lbl);
    
    int  FindCurCol(CGPoint pos);
    int  FindCardIndexInCol(CGPoint pos, int col);
    NSMutableArray * FindMaxAvailsInCol(int col, int idx);
	
	void reorderCards();
	void Shuffle();
	uint TryMove(uint src, uint dst, uint cnt);
	void updateStepInfo();
	void BackHome() ;
	BOOL GiveUp();
	void Record(COperations * thisStep);

	uint FindEmptyBuf();
	bool IsCard(uint card);
	bool IsCol(uint col);
	bool ColInRecycle(uint col);
	bool ColInCard(uint col);
	bool ColInBuf(uint col);
	uint BottCard(uint col);
	uint CntMaxSuppliment(bool OccupyAnEmptyCol = false);
	uint CntCardsIn(uint col);
	uint CntSeriIn(uint col);
	bool GameOver(void);
	void AutoThrow();
	uint CntMaxMv(uint desCol,uint srcCol);
	BOOL IsEmptyCol(uint col);
	
	void MoveCardToCard(uint dst, uint src, uint n);
	void MoveCardToBuff(uint dst, uint src, uint n);
	void MoveCardToRecyle(uint dst, uint src, uint n);
	void MoveBuffToCard(uint dst, uint src, uint n);
	void MoveBuffToBuff(uint dst, uint src, uint n);
	void MoveBuffToRecycle(uint dst, uint src, uint n);
	void MoveRecycleToCard(uint dst, uint src, uint n);
	void MoveRecycleToBuff(uint dst, uint src, uint n);
	
	void MoveCards(uint dst,uint src,uint n);
	void PostMove();
    
	// CDlgScore m_dlgScore;
	void Undo();
	char * FindActiveCard(uint card,char * b,char *r);
	BOOL Trashable(uint card);
	uint* SortByActivity(uint *pCols);
	void GetHints(void);
	bool DoAICal(void);
	void CheckGame();
	bool CombimeCol(uint col);
	bool SpliteCol(uint col);
	void GetTarget(int col,int *target);
	uint CntEmptyCardCols(void);
	uint CntEmptyBufs(void);
	uint FindEmptyCardCol(void);
	bool FitFormula(uint b, uint a);
	bool Splite();
	bool Combine();
	bool AICal();
	void ClrOpsRecords(void);
	uint GetCard(uint col,uint idx);
	
	void OnUndo();
	void OnAi();
	void OnHelpNextstep();
	void OnRand();
	
	GameScene * gameScene;
	CCMenu    * menu;
	
	CCLabelTTF  * lblCurGameNo;
	
	uint m_nSel;
	HINTS m_Hints;
	std::vector<COperations*> *m_pOps;
	int m_nCurGameNumber;
	
	CCSprite * cards[8][21];
	CCSprite * buff[4][2];
	CCSprite * recy[4][14];
	
	uint m_colNum[17];
	// uint m_iCards[8][20];//6+13=19
	// uint m_iBuffer[4];
	// uint m_iRecycle[4][14];

	BOOL m_bQuickMove;
	BOOL m_bEnableDbClick;
	BOOL m_bEnableAlert;
	
	BOOL m_bAICalRunning;
	BOOL m_bRealTimeUpdate;
};
