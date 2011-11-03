/*
 *  Board.c
 *  FreeCell
 *
 *  Created by Zhou Weikuan on 11-3-3.
 *  Copyright 2011 sino. All rights reserved.
 *
 */
#import "Board.h"
#import "constants.h"
#import "GameScene.h"
#import "CronlyGames.h"
#import "Settings.h"
#import "SoundApp.h"

//用于支持洗牌的函数
#import <algorithm>
#import <functional>

inline BOOL FitTrash(uint card, uint x) {
	return (TYPE(x)==TYPE(card)&&NUM(x)==NUM(card)-1);
}

//利用clock与rand，返回一个随机数
//我们可以产生一个随机数，即使srand每次设置同一个种子，
//调用此函数后也不会得到相同的随机数，这样比较好，
//因为这才是真正的随机开局呀
int Randomx(void) {
	int n = ( (rand() << 16) | (clock() & 0xFFFF) ) & MAX_GAME_NUMBER;
	return std::max(n,1);
}

Board::Board() {
	m_pOps = new std::vector<COperations*>();
	m_Hints.ClrHints();
	
	m_bEnableAlert    = true;
	m_bQuickMove      = false;
	m_bEnableDbClick  = YES;
	m_bAICalRunning   = true;
	m_bRealTimeUpdate = YES;
}

Board::~Board() {
	ClrOpsRecords();
	delete m_pOps;
}

int  Board::FindCurCol(CGPoint pos) {
    int i;
    for (i=0; i<4; ++i) {
        if (CGRectContainsPoint([buff[i][0] boundingBox], pos)) {
            return 9 + i;
        }
    }
    for (i=0; i<4; ++i) {
        if (CGRectContainsPoint([recy[i][0] boundingBox], pos)) {
            return 13 + i;
        }
    }
    
    CGSize s = cards[1][0].contentSize;
    float l = cardFirstPos.x - s.width/2;
    float r = cardFirstPos.x + cardDiffPos.x * 7 + s.width/2;
    float u = cardFirstPos.y + s.height/2;
    float d = cardFirstPos.y + cardDiffPos.y * 20 - s.height/2;
    if (pos.x >=l && pos.x <=r && pos.y >= d && pos.y <= u) {
        int col = 1 + (int)((pos.x - cardFirstPos.x + cardDiffPos.x/2) / cardDiffPos.x);
        if (col <= 1){
            col = 1;
        } else if (col > 8) {
            col = 8;
        }
        
        return col;
    }
    
    return 0;
}

int Board::FindCardIndexInCol(CGPoint pos, int col) {
    if (col >= 9)
        return m_colNum[col];
    int ret = 0;
    for (uint i=1; i<=m_colNum[col]; ++i) {
        if (CGRectContainsPoint([cards[col-1][i] boundingBox], pos)) {
            ret = i;
        }
    }
    return ret;
}

// find the maximum available cards in a series
NSMutableArray * Board::FindMaxAvailsInCol(int col, int idx) {
    NSMutableArray * ret = [NSMutableArray arrayWithCapacity: 4];
    if (col >= 13) {
        if (idx) {
            recy[col-13][idx].scale = 1.2f;
            [ret addObject: recy[col-13][idx]];
            [gameScene reorderChild:recy[col-13][idx] z:kLayerCard];
        }
        return ret;
    }
    if (col >= 9) {
        if (idx) {
            [ret addObject: buff[col-9][idx]];
            buff[col-9][idx].scale = 1.2f;
            [gameScene reorderChild:buff[col-9][idx] z:kLayerCard];
        }
        return ret;
    }
    
    uint maxi = CntMaxSuppliment(NO);
    if (m_colNum[col] - idx + 1 > maxi) {
        return ret;
    }
    CCSprite * o = nil;
    for (uint i=idx; i<= m_colNum[col]; ++i) {
        if (o==nil || FitFormula(o.tag, cards[col-1][i].tag)) {
            o = cards[col-1][i];
            o.scale = 1.2f;
            [ret addObject: o];
        } else {
            for (id obj in ret) {
                o = obj;
                o.scale = 1.0f;
            }
            [ret removeAllObjects];
            break;
        }
    }
    for (id obj in ret) {
        o = (CCSprite*)obj;
        o.scale = 1.2f;
        [gameScene reorderChild:o z:kLayerCard];
    }
    
    return ret;
}


//根据给定的牌局代号开始此局
void Board::StartGame() {
    CCSpriteFrameCache * cache = [CCSpriteFrameCache sharedSpriteFrameCache];

    int gameNumber = [Settings getCurGameNo];
    m_colNum[0] = 0;
	for (int i=0; i<4; ++i) {
        buff[i][0] = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName:@"cardB.png"]];
        [gameScene addChild: buff[i][0] z:0];
        buff[i][0].position = ccp(buffFirstPos.x+i*buffDiffX, buffFirstPos.y);
        m_colNum[9 + i] = 0;
        buff[i][0].tag = 0;
	}
	
	for (int i=0; i<4; ++i) {
        recy[i][0]  = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName:@"cardA.png"]];
        [gameScene addChild:recy[i][0] z:0];
        recy[i][0].position = ccp(recyFirstPos.x+i*recyDiffX, recyFirstPos.y);
        m_colNum[13 + i] = 0;
        recy[i][0].tag = 0;
	}
	
    for (int i=0; i<8; ++i) {
        m_colNum[i+1] = (i<4) + 6;
        
        cards[i][0]  = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName:@"cardK.png"]];
        [gameScene addChild: cards[i][0] z:0];
        cards[i][0].position = ccp(cardFirstPos.x + i * cardDiffPos.x, cardFirstPos.y);

        cards[i][0].tag = 0;
    }
    
	//	m_dlgScore.UpdateScore();//记录战况
	
	ClrOpsRecords();   //清除动作记录
	m_Hints.ClrHints();//清除提示
	
	m_nCurGameNumber = gameNumber;
	Shuffle();//洗牌发牌
	GetHints();
	
	// 设置窗框标题为当前牌局代号
	NSString * title = [NSString stringWithFormat:@"%10d", m_nCurGameNumber];
	lblCurGameNo = [CCLabelTTF labelWithString:title fontName:@"Marker Felt" fontSize: fontSize];
	[gameScene addChild: lblCurGameNo];
    lblCurGameNo.anchorPoint = ccp(0, 0.5f);
	lblCurGameNo.position = curGameNoPos;
	
#if 0
	m_dlgScore.InitScore();//记录战况
#endif
}

void Board::reorderCards() {
	for (int i=1; i<=8; ++i) {
		int cnt = m_colNum[i];
		for (int j=1; j<=cnt; ++j) {
			[gameScene reorderChild:cards[i-1][j] z:kLayerCard];
		}
	}	
}

void Board::EndGame() {
    [gameScene performSelectorOnMainThread:@selector(showWinMsg) withObject:nil waitUntilDone: NO];
    
    [SoundApp playEffect:@"win.mp3"];
    
    //[[GameKitWrapper sharedWrapper] reportScore:m_pOps->size() forCategory:@"com.cronlygames.freecell.steps"];
}

//测试当前单击点并根据击中的列的情况采取对应动作
//这个函数的代码本来是应该在OnLButtonDown中的，但
//考虑到双击动作可以用单击来模拟，而直接在OnLBtttonDblClk中调用
//OnLButtonDown不太合适，所以提取出来作为一个函数
//供OnLButtonDown和OnLBtttonDblClk两者调用

uint Board::TryMove(uint src, uint dst, uint cnt) {
    if (src == dst)
        return 0;
    
    uint nMv = CntMaxMv(dst, src);	
    
    if ((IsEmptyCol(dst) && dst <= 8 && cnt <= nMv) || cnt == nMv) {
        [SoundApp playEffect:@"move.wav"];
        MoveCards(dst, src, cnt);
        Record(new COperations(dst, src, nMv));
    } else {        
        cnt = 0;
    }        

    [gameScene performSelectorInBackground:@selector(postMove:) withObject:nil];
    
    return cnt;
}

void Board::PostMove() {
    AutoThrow(); //自动扔牌
    CheckGame(); //游戏是否结束？
}

//洗牌
void Board::Shuffle() {
	//准备一副新牌，并洗牌
	int card[52];
	int i;
	for(i = 1; i <= 52; ++i)
		card[i-1] = i;
	
	using namespace std;
	
	srand((m_nCurGameNumber >> 16) & 0x0FFFF);
	random_shuffle(card, card + 52);
	srand(m_nCurGameNumber & 0xFFFF);
	random_shuffle(card, card + 52);
	
    CCSpriteFrameCache * cache = [CCSpriteFrameCache sharedSpriteFrameCache];
	//发牌到牌列m_iCards
    NSString * str = nil;
    int idx = 0;
	for (int i = 0; i < 8; ++i) {
        const int num = m_colNum[i+1];
        for (int j=1; j<=num; ++j) {
            str = [NSString stringWithFormat:@"card%02d.png", card[idx]];
            
            cards[i][j] = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName: str]];
            [gameScene addChild:cards[i][j] z: kLayerCard];
            cards[i][j].position = ccp(cardFirstPos.x + i * cardDiffPos.x, cardFirstPos.y + (j-1)* cardDiffPos.y);
            cards[i][j].tag = card[idx];
            
            ++ idx;
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
// Board serialization
#if 0
void Board::Serialize(CArchive& ar)
{
	struct SIZE_INF { uint size, *pAddr; };
	const SIZE_INF cols[3] = {
		{ sizeof(m_iCards  ) / sizeof(uint) , &m_iCards[0][0]   },
		{ sizeof(m_iBuffer ) / sizeof(uint) , &m_iBuffer[0]     },
		{ sizeof(m_iRecycle) / sizeof(uint) , &m_iRecycle[0][0] },
	};
	
	if (ar.IsStoring()) {
		ar<<m_nCurGameNumber;//保存本局代号
		m_pOps->Serialize(ar);//保存步骤记录
		for(uint k = 0; k < 3 ; ++k)//保存牌局
			for(uint i = 0; i < cols[k].size; i++)
				ar<<cols[k].pAddr[i];
	}
	else {
		ar>>m_nCurGameNumber;//读取本局代号
		ClrOpsRecords();//清除步骤记录，准备读档 
		m_pOps->Serialize(ar);//读取步骤记录
		for(uint k = 0; k < 3 ; ++k)//读取牌局
			for(uint i = 0; i < cols[k].size; i++)
				ar>>cols[k].pAddr[i];
	}
}
#endif

/////////////////////////////////////////////////////////////////////////////
// Board commands
bool Board::IsCol(uint col) {
	return (col<=16 && col>=1);
}


// +-----Buf----+    +---Recycle---+
// | 9 10 11 12 | JL | 13 14 15 16 |
// +------------+    +-------------+
// +------------Cards--------------+
// | 1   2   3   4   5   6   7   8 |
// +-------------------------------+
//核心的移牌程序：将src列的n张牌移动到des列

void Board::MoveCardToCard(uint dst, uint src, uint n) {
    int sf = m_colNum[src] - n + 1;
    int df = m_colNum[dst] + 1;
    id act = nil;
    for (uint i=0; i<n; ++i) {
        cards[dst-1][df] = cards[src-1][sf];
        cards[dst-1][df].scale = 1.0f;
        [gameScene reorderChild:cards[dst-1][df] z:kLayerCard];
        act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(cardFirstPos.x + (dst-1)*cardDiffPos.x,
                                                             cardFirstPos.y + (df-1)*cardDiffPos.y)];
        
        [cards[dst-1][df] stopAllActions];
        [cards[dst-1][df] runAction: act];
        cards[src-1][sf] = nil;
        
        ++df, ++sf;
    }
    m_colNum[src] -= n;
    m_colNum[dst] += n;
}
void Board::MoveCardToBuff(uint dst, uint src, uint n) {
    int sf = m_colNum[src] - n + 1;
    buff[dst-9][1] = cards[src-1][sf];
    [gameScene reorderChild:buff[dst-9][1] z:kLayerCard];
    buff[dst-9][1].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(buffFirstPos.x+(dst-9)*buffDiffX,
                                                                 buffFirstPos.y)];
    [buff[dst-9][1] stopAllActions];
    [buff[dst-9][1] runAction: act];
    cards[src-1][sf] = nil;
    
    -- m_colNum[src];
    ++ m_colNum[dst];
}
void Board::MoveCardToRecyle(uint dst, uint src, uint n) {
    int sf = m_colNum[src] - n + 1;
    int df = m_colNum[dst] + 1;
    recy[dst - 13][df] = cards[src-1][sf];
    [gameScene reorderChild:recy[dst - 13][df] z:kLayerCard];
    recy[dst - 13][df].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(recyFirstPos.x+(dst-13)*recyDiffX,
                                                                 recyFirstPos.y)];
    [recy[dst - 13][df] stopAllActions];
    [recy[dst - 13][df] runAction: act];
    cards[src-1][sf] = nil;
    
    --m_colNum[src];
    ++m_colNum[dst];
}

void Board::MoveBuffToCard(uint dst, uint src, uint n) {
    if (m_colNum[src] >= 1) {
        
    } else {
        return;
    }
    int df = m_colNum[dst] + 1;
    
    cards[dst-1][df] = buff[src-9][1];
    [gameScene reorderChild:cards[dst-1][df] z:kLayerCard];
    cards[dst-1][df].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(cardFirstPos.x+(dst-1)*cardDiffPos.x,
                                                                 cardFirstPos.y + (df-1) * cardDiffPos.y)];
    [cards[dst-1][df] stopAllActions];
    [cards[dst-1][df] runAction: act];
    buff[src-9][1] = nil;
    ++m_colNum[dst];
    --m_colNum[src];
}

void Board::MoveBuffToBuff(uint dst, uint src, uint n) {
    if (dst != src) {
        
    } else {
        return;
    }
    buff[dst-9][1] = buff[src-9][1];
    [gameScene reorderChild: buff[dst-9][1] z:kLayerCard];
    buff[dst-9][1].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(buffFirstPos.x+(dst-9)*buffDiffX,
                                                                 buffFirstPos.y)];
    [buff[dst-9][1] stopAllActions];
    [buff[dst-9][1] runAction: act];
    
    buff[src-9][1] = nil;
    ++ m_colNum[dst];
    -- m_colNum[src];
}
void Board::MoveBuffToRecycle(uint dst, uint src, uint n) {
    int df = m_colNum[dst] + 1;
    recy[dst-13][df] = buff[src-9][1];
    [gameScene reorderChild: recy[dst-13][df] z:kLayerCard];
    recy[dst-13][df].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(recyFirstPos.x+(dst-13)*recyDiffX,
                                                                 recyFirstPos.y)];
    [recy[dst-13][df] stopAllActions];
    [recy[dst-13][df] runAction: act];
    buff[src-9][1] = nil;
    
    ++ m_colNum[dst];
    -- m_colNum[src];
}
void Board::MoveRecycleToCard(uint dst, uint src, uint n) {
    int df = m_colNum[dst] + 1;
    int sf = m_colNum[src] - n + 1;
    
    cards[dst-1][df] = recy[src-13][sf];
    [gameScene reorderChild:cards[dst-1][df] z:kLayerCard];
    cards[dst-1][df].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(cardFirstPos.x+(dst-1)*cardDiffPos.x,
                                                                 cardFirstPos.y + (df-1) * cardDiffPos.y)];
    [cards[dst-1][df] stopAllActions];
    [cards[dst-1][df] runAction: act];
    
    recy[src-13][sf] = nil;
    ++ m_colNum[dst];
    -- m_colNum[src];
}

void Board::MoveRecycleToBuff(uint dst, uint src, uint n) {
    int sf = m_colNum[src] - n + 1;
    
    buff[dst-9][1] = recy[src-13][sf];
    [gameScene reorderChild:buff[dst-9][1] z:kLayerCard];
    buff[dst-9][1].scale = 1.0f;
    
    id act = [CCMoveTo actionWithDuration:kMoveTime position:ccp(buffFirstPos.x+(dst-9)*buffDiffX,
                                                                 buffFirstPos.y)];
    [buff[dst-9][1] stopAllActions];
    [buff[dst-9][1] runAction: act];
    
    recy[src-13][sf] = nil;
    ++ m_colNum[dst];
    -- m_colNum[src];
}

void Board::MoveCards(uint dst, uint src, uint n) {
	if (IsCol(src) && !IsEmptyCol(src) //源列非空
		   && n <= CntSeriIn(src) //最多可移动全部序列牌
        && IsCol(dst)) {
        
    } else {
        return;
    }
	
	//取消当前选中
	if (!m_bAICalRunning) {
		// UnselectCardCol();
    }
	if (src <= 8) {
		if (dst <= 8) {
			MoveCardToCard(dst, src, n);
		} else if (dst <= 12){
			MoveCardToBuff(dst, src, n);
		} else {
			MoveCardToRecyle(dst, src, n);
		}
	} else if (src <= 12) {
		if (dst <= 8) {
			MoveBuffToCard(dst, src, n);
		} else if (dst <= 12) {
			MoveBuffToBuff(dst, src, n);
		} else {
			MoveBuffToRecycle(dst, src, n);
		}
	} else {
		if (dst <= 8) {
			MoveRecycleToCard(dst, src, n);
		} else if (dst <= 12) {
			MoveRecycleToBuff(dst, src, n);
		} else {
			return;
		}
	}

	if (m_bAICalRunning && !m_bRealTimeUpdate) {
		return;
	}
	
	updateStepInfo(); //刷新步数信息
    
//	InvalidateRect(rSrc);//刷新源列牌面
//	InvalidateRect(rDes);//刷新目标列牌面
}

//按照规则f的条件判断 a可放在b下 这一论断对两张牌a，b是否成立
//规则f如下：
//    红牌可以放在黑牌下，黑牌可以放在红牌下
//    但是必须保证大点数的牌在上，小点数的牌在下
//    且点数只能相差1点
//    例如：
//        照此规则，红桃5下只可以放黑桃4或者梅花4
//    
bool Board::FitFormula(uint b, uint a) {
	if (a<=52 && a>=1 && b<=52 && b>=1) {
        
    } else {
        return 0;
    }
	//Type()   =  0 黑桃   1 红桃   2 梅花   3 方块
	//b，a不同花色且b的点数比a大一点
	return (TYPE(a)+TYPE(b))%2==1 && NUM(b)-NUM(a)==1;
}

//看看此列是否为空
BOOL Board::IsEmptyCol(uint col) {
	return CntCardsIn(col)==0;
}

// 计算实际允许从被选中列移动多少张纸牌到目标列
//（计算出来之后可以利用函数MoveCards来进行实际的移动）
uint Board::CntMaxMv(uint desCol, uint srcCol) {
	if (IsCol(srcCol) && !IsEmptyCol(srcCol) && IsCol(desCol)) {
        
    } else {
        return 0;
    }
	
	uint n = 0;
	//目标列是牌列
	if (desCol <= 8) {
        if (COL_IN_RECY(srcCol)) {
            if (IsEmptyCol(desCol) || 
                FitFormula(BottCard(desCol), BottCard(srcCol) ))
				n = 1;
		} else if (COL_IN_BUFF(srcCol)) { //源列是缓存列
			if (IsEmptyCol(desCol) || 
			   FitFormula( BottCard(desCol) , BottCard(srcCol) ))
				n = 1;
		} else {
			//源列是牌列
			uint nSeri = CntSeriIn(srcCol);//计算连续多少张牌
			if(IsEmptyCol(desCol)) { //目标列是空牌列
				uint maxSuppliment = CntMaxSuppliment(true);
				//肯定可以移动
				n = std::min(maxSuppliment,nSeri);
			} else {
				uint bottSrc = BottCard(srcCol);//源列最下面的牌
				uint bottDes = BottCard(desCol);//目标列最下面的牌
				uint numSrc = NUM(bottSrc);//牌点数
				uint numDes = NUM(bottDes);//牌点数
				n = numDes - numSrc;
				uint maxSuppliment = CntMaxSuppliment(false);
				//必须严格满足以下条件才可以移动：
				if( 	//目标牌点数介于源序列牌之上的指定区间内 且
				   numDes >= numSrc + 1 && numDes <= numSrc + nSeri &&
				   //它比源牌大奇数点且红黑相异或大偶数点红黑相同 且 有足够空间来移动
				   n%2 == (TYPE(bottSrc)+TYPE(bottDes))%2 && n <= maxSuppliment) { 
					;
				} else {
					n = 0;
				}
			}
		}
	} else if (desCol <= 12) { //目标列是缓存列
		if (IsEmptyCol(desCol)) {
			n = 1;//缓存列无牌则可移动一张
		}
	} else { //目标列是回收列
		int s = BottCard(srcCol);
		if (!IsEmptyCol(desCol)) {
			int d = BottCard(desCol);
			if (TYPE(s)==TYPE(d) && NUM(d) == NUM(s) - 1)
				n = 1;//花色相符，点数小一，则可以回收
		} else if (NUM(s) == 1 && (uint)(TYPE(s)+13) == desCol)
			n = 1;//是A且花色相符（且相应回收列中无牌）
	}
	
	return n;
}

//遍历各列并自动扔出1-12列中最小的牌直到无法扔出为止
void Board::AutoThrow() {
	uint colSrc, cardSrc, numSrc, colDes,sons[2];
	while(true) { //直到没有牌可扔为止
		for (colSrc = 1; colSrc <= 12; colSrc++) { //寻找可扔的牌所在的列
			if (IsEmptyCol(colSrc))
				continue;
			cardSrc = BottCard(colSrc);
			if (!Trashable(cardSrc))
				continue;
			numSrc = NUM(cardSrc);
			colDes = TYPE(cardSrc) + 13;
			if (numSrc == 1 || numSrc == 2)
				break;
			if (m_bAICalRunning)
				break;//自动解答时废牌能扔就扔
			
			//考虑子牌是否已经回收
			sons[0] = sons[1] = colDes;
			sons[0] -= colDes > 13 ? 1 : -3;
			sons[1] += colDes < 16 ? 1 : -3;
			if (m_colNum[sons[0]] > 0 //子牌的回收列非空
				&& m_colNum[sons[1]] //子牌的回收列非空
				&& NUM(BottCard(sons[0])) >= numSrc-1
				&& NUM(BottCard(sons[1])) >= numSrc-1) {
				break;
			}
		}
		if (colSrc > 12)
			break;
		if (!m_bQuickMove && ColInCard(colSrc)) { //快速移动的时候没有动画
			// CGRect rs = RectOf(colSrc,CntCardsIn(colSrc),1);
			// CGRect rd = RectOf(colDes,1,1);
			//			::LineDDA(rs.left,rs.top,rd.left,rd.top,LineDDACallback,cardSrc);
		}
		
        [SoundApp playEffect:@"move.wav"];
		MoveCards(colDes,colSrc,1);
        // Record(new COperations(colDes,colSrc,1));
		if(m_pOps->empty()) {
			Record(new COperations(colDes,colSrc,1));
		} else { //扔牌后的自动扔牌动作必须和扔牌动作放在一起
			(m_pOps->back())->AddOperation(colDes,colSrc,1);
		}
        Sleep(200);
	}
}

//测试是否游戏结束
bool Board::GameOver() {
	//如果所有牌都在回收列了则游戏结束
	for(uint i=13;i<=16;i++) {
		if (m_colNum[i] < 13)
            return false;
	}
	return true;
}

//按照规则计算此列有几张牌是顺序存放的
uint Board::CntSeriIn(uint col) {
	//我们认为缓存列和回收列的序列牌长为1
	if (IsCol(col) && !IsEmptyCol(col)) {
        
    } else {
        return 0;
    }
	uint nSeri = 1;//非空的缓存列序列牌数为1
	if (col <= 8) {
		// CCSprite *pTop,*p1, *p2;
		CCSprite ** card = cards[col - 1];
		int p1 = m_colNum[col];//指向底牌
		int p2 = p1 - 1; //p2指向p1上面的牌
		while (p2 > 0 && FitFormula(card[p2].tag, card[p1].tag)) {
            ++nSeri;
            --p1, --p2;
        }
	}
	return nSeri;
}

//计算给定的牌列中有多少张牌
uint Board::CntCardsIn(uint col) {
	if (IsCol(col)) {
        
    } else {
        return 0;
    }
	
    return m_colNum[col];
}

//假设目前有连续的无数张牌等待移动
//计算目前空出的无牌列(可用空间)最多可供一次性移动多少张牌
//OccupyAnEmptyCol指出在计算时是否使用全部可用空间
//如果否，则在计算最多允许一次性移动多少张牌时牌列中的可用
//空间会少计一个
uint Board::CntMaxSuppliment(bool OccupyAnEmptyCol)
{
	int a = CntEmptyBufs();
    int b = CntEmptyCardCols();

	//有一个空列将会被作为目标牌列
	if (OccupyAnEmptyCol) {
		//可往空牌列移动的牌数在由人来玩牌时只与空档有关
#if 0
        if(!m_bAICalRunning) {
            return a+b;
        }
#endif
		//其他任何情况下都一样
		if (b) {
            
        } else {
            return 0;
        }
		--b;
	}
	return a*(b+1)+b*(b+1)/2+1;
}

//取出给定列的底牌
uint Board::BottCard(uint col) {
	if (IsCol(col) && !IsEmptyCol(col)) {
        
    } else {
        return 0;
    }
	
	if (col <= 8) {
        return cards[col-1][m_colNum[col]].tag;
	} else if(col <= 12) {
        return buff[col-9][m_colNum[col]].tag;
	} else {
        return recy[col-13][m_colNum[col]].tag;
	}
}

bool Board::ColInCard(uint col) {
	return (col<=8 && col>=1);
}

bool Board::ColInBuf(uint col) {
	return (col<=12 && col>=9);
}

bool Board::ColInRecycle(uint col) {
	return (col<=16 && col>=13);
}

bool Board::IsCard(uint card) {
	return (card >= 1 && card <= 52);
}

void Board::Record(COperations *thisStep) {
	//增加一步记录并刷新步数信息
	m_pOps->push_back(thisStep);
	updateStepInfo();
}

void Board::updateStepInfo() {
    NSNumber * num = [NSNumber numberWithInt: m_pOps->size()];
    [gameScene performSelectorOnMainThread:@selector(updateStepInfo:) withObject:num waitUntilDone: NO];
}

//撤消
void Board::OnUndo() {
	Undo();
	GetHints();
}

//执行撤消动作
void Board::Undo() {
	if (m_pOps->empty())
		return;
	
	//撤销一步
	COperations *pOpsLast = (COperations*)m_pOps->back();
	m_pOps->pop_back();

	std::vector<COperation> & pOps = pOpsLast->pOps;
	for (std::vector<COperation>::reverse_iterator it = pOps.rbegin();
		 it != pOps.rend(); ++it) {
		COperation & pOp = *it;
		MoveCards(pOp.src,pOp.des,pOp.cnt);
	}
	
	pOpsLast->ClrOps();
	delete pOpsLast;
	
	updateStepInfo();
}

//游戏返回到开头但是保留步骤记录，准备回放
void Board::BackHome() {
	int nSteps = m_pOps->size();
	
	//还原牌局但保留步骤记录
	while(nSteps > 0) {
		COperations *pOpsLast = (COperations*)(*m_pOps)[--nSteps];
		std::vector<COperation> & pOps = pOpsLast->pOps;
		for (std::vector<COperation>::iterator it = pOps.begin();
			 it != pOps.end(); ++it) {
			COperation & pOp = *it;
			MoveCards(pOp.src, pOp.des, pOp.cnt);
		}
		
		updateStepInfo();
	}
}

//取第col列第idx张牌
uint Board::GetCard(uint col, uint idx) {
	assert(IsCol(col) && !IsEmptyCol(col) && idx > 0 && idx <= CntCardsIn(col));
	if(col <= 8) {
        return cards[col-1][idx].tag;
	} else if(col <= 12) {
        return buff[col-9][idx].tag;
	} else {
        return recy[col-13][idx].tag;
	}
}

void Board::ClrOpsRecords() {
	if (m_pOps == NULL)
		return;
	
	////////////////////////////////
	//清除原来的操作记录
	while(!m_pOps->empty()) {
		COperations * op = m_pOps->back();
		m_pOps->pop_back();
		delete op;
	}
	m_pOps->clear();
}
//自动解答
void Board::OnAi()  {
	// TODO: Add your command handler code here
	// UnselectCardCol();//取消选中状态
	m_Hints.ClrHints();//清除提示的记录
#if 0
	CDlgAICal dlgAICal;//自动解答
	dlgAICal.DoModal();
	UpdateAllViews(NULL);//可能使用了快速解答，所以要刷新界面
	
	if(!dlgAICal.m_bSuccess) {
		AfxMessageBox("抱歉，自动解答未能成功!");
	}
#endif
	CheckGame();//答案已经找到，从头开始演示
}

/*自动解答算法使用全局的递归算法和局部的回溯法算法相结合，步骤如下：
 自动解答算法：
 (1)  对1-4和9-16列中 每一个 有牌可以移动到其他列的 列 执行(2)
 否则（无牌可以移动）看还有没有空档，没有则返回false（此路不通），
 如果有空档则（表示1-4和9-16列全是空的，解答成功）返回true，
 (2)  对此列牌的每一个目标列(目标列可能不止一列)都使用以下算法：
 (3)  如果此列可以合并到其他列，则将此列合并到其他列。如果
 有两个列可以合并它，则
 (4)  自动扔牌
 (5)  调用自动解答算法
 如果它返回true则返回true
 否则撤销本次所有的移动（即：(3)(4)中的移牌动作）并返回false
 (6)  返回false
 */

//-----------------------------------------------
volatile bool g_bStopAICal;//玩家停止了自动解答
//-----------------------------------------------
//自动解答
bool Board::AICal()
{
	//玩家等的不耐烦了
	if (g_bStopAICal) {
		//撤销过程的动画效果关闭，这样能在瞬间
		//撤销所有的解答步骤
		m_bRealTimeUpdate = YES;
		return false;
	}
	//自动解答得到的步数超过正常值，尽快结束这种局面
	//此局很可能导致算法无限死循环
	if (!m_pOps->empty() && m_pOps->size() > 200 ) {
		//g_bStopAICal = true;
		return false;
	}
	AutoThrow();
	return GameOver() || Combine() || Splite();//先合并，合不了就拆开
}
/*-------------------------------------------合-------------------------------------------
 对每一除回收列之外的有目标列的非空列
 {
 如果没有目标列
 如果此列是缓存列
 如果有空牌列
 如果拿下来能够节约空间
 拿下来，继续解答		
 否则
 如果目标列只在缓存列（因为可能有两个目标都在缓存列）
 如果有空牌列
 将（任一）目标牌列拿到空牌列中，继续解答         // 从上往下把目标牌列合并到空牌列中
 
 否则如果此列是缓存列（至少有一个目标是牌列）
 拿到（任一）牌列目标上来，继续解答
 
 否则如果可以合并到牌列                                  （空间足够，缓存列和牌列合并到牌列）
 如果能在目标上得到更长的序列牌			// 即使是长度相同也不行
 或目标牌列完全是以K开始的序列牌
 合并到目标牌列上，继续解答
 }
 返回假
 
 继续解答：
 记录此次动作
 自动扔牌
 如果执行自动解答成功返回真
 撤销
 返回假
 ----------------------------------------------------------------------------------------*/
/*-----------------------------------------扔---------------------------------------------
 拆：非空才拆
 
 拆缓存列：	有空牌列就直接拿下来，否则失败
 拆牌列：	此列是非完全序列牌
 先后拆到牌列空列空档，不够不拆。
 否则就是完全序列牌，
 全拆到空档，不够不拆。
 拆完后再拆另一个牌列或空档列（此空档列不能是刚才拆上去的列，不然循环了）
 如果找不到可以拆动的牌列，如果可以找到缓存列否则失败
 ----------------------------------------------------------------------------------------*/
//执行合并动作
bool Board::Combine()
{
	for(uint i = 1; i <= 12; i++) {
		if(IsEmptyCol(i)) continue; 
		if(CombimeCol(i)) return true;
	}
	return false;
}
//执行拆分动作
bool Board::Splite()
{
	//对每个可拆的非完全序列进行拆分
	uint cols[8+1], *pFirst = cols, *pLast = SortByActivity(cols);
	for(;pFirst < pLast; ++pFirst) {
		if(SpliteCol(*pFirst)) return true;
	}
	for(uint i = 9; i <= 12; i++) {
		if(IsEmptyCol(i)) continue; 
		if(SpliteCol(i)) return true;
	}
	return false;
}
//合并牌列：将此列的（整个或部分）序列牌合并到其它列
bool Board::CombimeCol(uint col)
{
	//合并的对象只可能是缓存列或牌列且是非空列
	assert( IsCol(col) && ! ColInRecycle(col) && ! IsEmptyCol(col) );
	
	int desCol = 0, srcCol = 0, cntCards  = 0;
	
	int tar[2];
	GetTarget(col,tar);//寻找此列的目标列
	
	uint ntar = 0;//计算目标列数目
	bool bAllTarInBuf = false;//是否所有目标都在缓存列
	if(tar[0]) {
		++ntar;
		bAllTarInBuf = ColInBuf(tar[0]);
		if(tar[1]) {
			++ntar;
			bAllTarInBuf = bAllTarInBuf && ColInBuf(tar[1]);
		}
	}
	//----------
	//没有目标列
	//----------
	if( ntar == 0 ) {
		//此列是非空牌列没有目标列
		if(!ColInBuf(col)) return false;
		//此列是缓存列没有目标列
		int a = CntEmptyBufs();//a是空档数
		int b = CntEmptyCardCols();//b是空牌列数
		//如果没有空牌列
		if(b == 0) return false;
		//如果有空牌列
		int c = (2*a+b)*(b+1)/2+1;//移动之前的空间
		++a,--b;//假设空档增加空牌列减少
		int d = (2*a+b)*(b+1)/2+1;//移动之后的空间
		if( c >= d ) return false;
		//能增加空间，拿到空牌列，继续解答
		srcCol = col;
		desCol = FindEmptyCardCol();
		cntCards  = 1;
#ifdef DEBUG_ALERT
		ShowMessage("合并缓存列到空牌列，增加空间",srcCol,desCol,cntCards);
#endif
		goto doAI;
	}
	//如果目标列都在缓存列
	//--------------------
	else if( bAllTarInBuf ) {
		int empCardCol = FindEmptyCardCol();
		if(!empCardCol)return false;//如果有空牌列
		//将（任一）目标牌列拿到空牌列中，继续解答
		srcCol = tar[0];
		desCol = empCardCol;
		cntCards  = 1;
#ifdef DEBUG_ALERT
		ShowMessage("合并缓存列到空牌列，且其他牌可以合并到此牌",
					srcCol,desCol,cntCards);
#endif
		goto doAI;
	}
	//至少有一个目标列在牌列
	//------------
	//此列是缓存列
	else if(ColInBuf(col)) {
		//缓存列拿到牌列目标上来，继续解答
		srcCol = col;
		desCol = tar[ ntar == 1 ? 0 : ( ColInCard(tar[0]) ? 0 : 1 ) ];
		assert(tar[0]);
		cntCards  = 1;
#ifdef DEBUG_ALERT
		ShowMessage("合并缓存列到牌列",srcCol,desCol,cntCards);
#endif
		goto doAI;
	}
	//否则此列是牌列
	else {
		srcCol = col;
		if(ntar == 1) { //仅有一个目标列则此目标列肯定是牌列
			desCol = tar[0];
		} else { 
			//有两个目标列，则可能有一个或两个目标列是牌列
			if( !ColInCard(tar[0]) ) { //tar[0]不是牌列则tar[1]肯定是牌列
				desCol = tar[1];
			} else if(ColInCard(tar[1])) { //两个tar都是牌列
				desCol = tar[ CntSeriIn(tar[0]) > CntSeriIn(tar[1]) ? 0 : 1 ];
				//先合并到序列牌长的目标列
			} else {
				desCol = tar[0];
			};
		}
		cntCards = CntMaxMv(desCol,srcCol);
		assert(cntCards > 0);
		//if( cntCards + CntSeriIn(desCol) <= CntSeriIn(srcCol) ) return false;
		//由长序列合并到短序列必须是移动后源列露出废牌才行
		if( cntCards + CntSeriIn(desCol) <= CntSeriIn(srcCol) )
			if(!Trashable(GetCard(srcCol,CntCardsIn(srcCol)-cntCards)))
				return false;
		//可以合并到牌列
#ifdef DEBUG_ALERT
		ShowMessage("合并牌列到牌列，且能得到更长序列牌",srcCol,desCol,cntCards);
#endif
		goto doAI;
	}
	return false;
doAI:	//有牌可以移动哦
	MoveCards(desCol,srcCol,cntCards);//移动
	Record(new COperations(desCol,srcCol,cntCards));//记录移动动作
	AutoThrow();//自动扔牌（自动记录动作）
	if(AICal())return true;//成功解答
	Undo();
	return false;
}

/*
 扔：牌列 | 缓存 ---> 回收
 合：牌列 | 缓存 ---> 牌列
 1. 序列牌整个拿到其他牌列露出空列或剩余牌
 2. 序列牌部分拿到其他牌列露出废牌
 3. 缓存牌拿到其他牌列
 4. 缓存牌拿到空列成为责任牌
 
 拆：牌列 ---> 牌列 | 空档
 */
bool Board::SpliteCol(uint col)
{
	//拆的对象只可能是缓存列或牌列且非空才拆
	assert( IsCol(col) && ! ColInRecycle(col) && ! IsEmptyCol(col) );
	if(ColInBuf(col))//拆缓存列
	{
		//没有空牌列则不能拿下来
		uint empCardCol = FindEmptyCardCol();
		if(empCardCol == 0)
            return false;
		//有空牌列
		//如果拿下来能给别的列提供合的机会就拿下来
		int tar[2];
		GetTarget(col,tar);//寻找目标列
		if(!tar[0] && !tar[1])return false;
#ifdef DEBUG_ALERT
		ShowMessage("拆缓存列，有牌能合并到它上面",col,empCardCol,1);
#endif
		MoveCards(empCardCol,col,1);//记录移动动作
		Record(new COperations(empCardCol,col,1));
		if(AICal())return true;
		Undo();
		return false;
	}
	//拆牌列
	uint empCardCol = FindEmptyCardCol();
	if(empCardCol)//能够直接移动到空牌列？
	{
		int nCntCards     = CntCardsIn(col);
		int nFitFomula    = CntSeriIn(col);
		int nMovableCards = CntMaxMv(empCardCol,col);
		//实际可移动的牌肯定不大于序列牌数
		if(nMovableCards == nFitFomula)
		{
			//完全序列牌列直接移到空牌列没有意义
			if(nFitFomula == nCntCards)return false;
#ifdef DEBUG_ALERT
			ShowMessage("拆序列牌到空牌列",col,empCardCol,nMovableCards);
#endif
			//非完全序列牌列的全部序列牌直接移到空牌列
			MoveCards(empCardCol,col,nMovableCards);
			Record(new COperations(empCardCol,col,nMovableCards));
			if(AICal())return true;
			Undo();
			return false;
		}//else 序列牌不能直接拿到空牌列，则需要分批拆，看下面
	} else { //分批拆
		
		//先后拆到牌列，空列及空档，不够不拆。
		int inUse[12];//记录使用过的空间
		int steps    = 0;//记录使用了多少空间
		int nMoved   = 0;//记录移动过的牌数
		int nCntCard = CntCardsIn(col);
		int nCntSeri = CntSeriIn(col);
		int tarCol   = 0, empCardCol = 0, empBufCol  = 0;
		while(nMoved != nCntSeri)
		{
			int tar[2];
			GetTarget(col,tar);//寻找目标列
			bool t0 = ColInCard(tar[0]);
			bool t1 = ColInCard(tar[1]);
			//没有空牌列
			//如果可以部分合并到其他列时，合并到其他牌列
			if(t0 || t1)
				tarCol = tar[ t0 ? 0 : 1 ];
			else if((empCardCol = FindEmptyCardCol())!=0)//否则如果还有空牌列
				tarCol = empCardCol;
			else if((empBufCol = FindEmptyBuf())!=0)//否则如果还有空档
				tarCol = empBufCol;
			else//否则（拆不开，看下一列）
			{
				while(steps--)Undo();//撤销
				return false;
			}
			int n = CntMaxMv(tarCol,col);
			assert(n>0);
#ifdef DEBUG_ALERT
			ShowMessage("拆序列牌到牌列，空列及空档！",col,tarCol,n);
#endif
  			MoveCards(tarCol,col,n);//记录移动动作
			Record(new COperations(tarCol,col,n));
			nMoved += n;//计算移走的牌数
			inUse[steps++] = tarCol;//记录当前使用的目标列
			//退出循环时，step记录使用了多少空间
			
			//部分序列拿走后露出废牌的这种情况在
			//合并函数中已经予以考虑过了，在此就不必再考虑了
			/*
			 if(nMoved < nCntSeri) {
			 uint bc = BottCard(col);
			 if(Trashable(bc)) {
			 MoveCards(TYPE(bc)+13,col,1);
			 Record(new COperations(TYPE(bc)+13,col,1));
			 if(AICal()) return true;
			 Undo();
			 }
			 }
			 */
		}
		//此列不完全是序列牌
		//------------------
		if(nCntCard != nCntSeri){
			if(AICal()) return true;
			while(steps--)Undo();//不成功则全部撤销
			return false;
		}
		//此列完全是序列牌
		//----------------
		//拆完后还再拆另一个列，它可能是牌列，也可能是缓存列，
		//但绝对不能是正在被使用的列，也不可能是拆掉了的当前列	
		for(int another = 1; another <= 12; another++) {
			assert(IsEmptyCol(col));
			//col列此时为空所以可以被过滤掉
			if(IsEmptyCol(another))continue;
			bool isInUse = false;
			for(int j = 0; j < steps; j++){
				if(another != inUse[j])continue;
				isInUse = true;
				break;
			}
			//过滤掉刚刚被使用的列
			if(isInUse)continue;
			if(SpliteCol(another))return true;//成功解答
			while(steps--)Undo();//不成功则全部撤销
			return false;
		}
	}
	
	return false;
}

//找到一个空牌列
uint Board::FindEmptyCardCol() {
	for(uint i=1;i<=8;i++)
        if (m_colNum[i] == 0)
            return i;
	return 0;
}

//找到一个空档
uint Board::FindEmptyBuf() {
	for(uint i=9;i<=12;i++) 
		if (m_colNum[i] == 0)
            return i;
	return 0;
}

//统计空牌列数
uint Board::CntEmptyCardCols() {
	int cnt = 0;
	for (uint i=1;i<=8;i++)
		if (m_colNum[i] == 0)
            ++cnt;
	return cnt;
}

//统计空档数
uint Board::CntEmptyBufs() {
	int cnt = 0;
	for (uint i=9;i<=12;i++)
		if (m_colNum[i] == 0)
            ++cnt;
	return cnt;
}


//为指定的源列寻找目标列，目标列可能有一个或两个，但是绝对不会超过两个
//如果没有目标列，则返回时，target[0]和target[1]都是零
//搜索非回收列来寻找目标列
void Board::GetTarget(int col, int *target) {
	assert(IsCol(col) && !ColInRecycle(col) && !IsEmptyCol(col));
	
	int *p = target;
	p[0] = p[1] = 0;
	for (uint i = 1; i <= 12; i++) {
		if (i > 8) {
			int d = buff[i-9][m_colNum[i]].tag;
			if(!IS_CARD(d)) continue;//忽略空档
			int s = BottCard(col);
			uint n = NUM(d) - NUM(s);
			uint nSeri = CntSeriIn(col);
			if(n>0 && n<=nSeri && n%2==(TYPE(s)+TYPE(d))%2) {
				*p++ = i;
			}
		} else if (m_colNum[i] && CntMaxMv(i, col)) {
			*p++ = i;//目标是牌列
		}
		if (p >= target + 2)
            return;//目标列绝对不会超过两个
	}
}

//提示下一步
void Board::OnHelpNextstep() {
	// TODO: Add your command handler code here
	if(m_Hints.IsEmpty()) return;
	
	//提示前取消选中状态
	[gameScene restoreCardsPos];
	
	//取出下一步动做的记录并提示玩家
	const COperation pOp = m_Hints.NextHint();

    id act = [CCSequence actions: [CCTintTo actionWithDuration:0.5f red:50 green:200 blue:200],
              [CCDelayTime actionWithDuration:1.0f],
              [CCTintTo actionWithDuration:0.5f red:255 green:255 blue:255],
              nil];
    if (pOp.des <= 8) {
        [cards[pOp.des-1][m_colNum[pOp.des]] runAction: act];
    } else if (pOp.des <= 12) {
        [buff[pOp.des-9][m_colNum[pOp.des]] runAction: act];
    } else {
        [recy[pOp.des-13][m_colNum[pOp.des]] runAction: act];
    }
    
    CCSprite ** ptr = cards[pOp.src-1];
    if (pOp.src <= 8) {
        ptr = cards[pOp.src-1];
    } else if (pOp.src <= 12) {
        ptr = buff[pOp.src-9];
    } else {
        ptr = recy[pOp.src-13];
    }
    for (uint i=m_colNum[pOp.src] - pOp.cnt + 1; i<= m_colNum[pOp.src]; ++i) {
        act = [CCSequence actions: [CCTintTo actionWithDuration:0.5f red:200 green:50 blue:50],
         [CCDelayTime actionWithDuration:1.0f],
         [CCTintTo actionWithDuration:0.5f red:255 green:255 blue:255],
         nil];
    
        [ptr[i] runAction: act];
    }
}

//检查游戏是否结束
//如果没有结束则计算提示步骤
//否则就让玩家选择是否开局或回放存档
void Board::CheckGame() {
	if (!GameOver()) {
		GetHints();
		if (m_Hints.IsEmpty()) {
            [SoundApp playEffect:@"lose.mp3"];
			[gameScene issueMsg:@"You can try to undo some steps" title:@"No way out!"];
            
            if (gameScene->buttonLayer.tag == 0) {
                [gameScene toggleButtons: gameScene];
            }
            
			return;
		}
		return;
	}
	//本局结束了

    EndGame();
}

//执行自动解答
bool Board::DoAICal(void) {
	//备份“快速移动”选项的值
	BOOL quickmv_bk = m_bQuickMove;
	
	//自动扔牌时的动画效果必须暂时关闭
	m_bQuickMove = TRUE;
	
	//开始解答
	m_bAICalRunning = true;
	g_bStopAICal    = false;
	m_bRealTimeUpdate = YES;
	bool bSuccess   = AICal();
	m_bAICalRunning = false;
	g_bStopAICal    = true;
	
	//恢复“快速移动”选项的值
	m_bQuickMove = quickmv_bk;
	
	return bSuccess;
}

//计算下一步的所有可能的动作并记录它（们）
void Board::GetHints()
{
	//清除原来的记录
	m_Hints.ClrHints();
	if (GameOver())
		return;
	
	uint nMove,i,j;
	//考虑合并和回收废牌
	for(i = 1; i <= 12; i++) {
		if (IsEmptyCol(i)) continue;
		uint bc = BottCard(i);
		if (Trashable(bc)) {
			m_Hints.AddOperation(TYPE(bc)+13,i,1);//提示回收底牌（废牌）
		}
	}
	for(i = 1; i <= 12; i++) { 
		if(IsEmptyCol(i)) continue;
		for(j = 1; j <= 8; j++) { 
			if(IsEmptyCol(j) || !(nMove = CntMaxMv(j,i))) continue;
			//合并要得到较长序列或有废牌可以扔掉
			if( CntSeriIn(i)-nMove < CntSeriIn(j) ||
			   Trashable( GetCard( i, CntCardsIn(i)-nMove ) ) ) {
				m_Hints.AddOperation(j,i,nMove);
			}
		}
	}
	if (!m_Hints.IsEmpty()) return;
	
	//考虑拆掉非完全序列牌
	for(i = 1; i <= 8; i++) {
		if(IsEmptyCol(i) || CntSeriIn(i) == CntCardsIn(i)) continue;
		for(j = 1; j <= 12; j++) { //不考虑回收列因为无废牌
			if(!IsEmptyCol(j)) continue;
			m_Hints.AddOperation(j,i,CntMaxMv(j,i));
			break;//可能有多个空列，但只提示移动到其中之一就够了
		}
	}
}
/*
 ////////////////////////////////////////////////////////////////
 能增加空间的列最先考虑拆掉：
 ////////////////////////////////////////////////////////////////
 
 // 拆分兼具合并
 ·对每一非完全序列牌牌列：
 ·按照活牌所占剩余牌的比例由高到低进行排序，对排序后的每一列：
 ·如果序列牌能完全移走（通过合并到其他牌列，拆到空牌列，或移动到空档）
 ·全拆
 
 ·根据缓存列的牌从大到小的顺序
 // 增加空间且增加责任牌
 ·如果此牌可以拿到牌列则拿下来
 // 增加空间且增加责任牌
 ·否则如果此牌拿下来后能增加空间则拿下来
 // 增加责任牌但减少空间
 ·如果此牌拿下来后能成为责任牌则拿下来
 
 // 增加空间但减少责任牌
 ·对每一完全序列牌牌列：
 ·如果序列牌能完全移到空档和牌列
 ·能增加空间
 ·全拆
 ·如果没有空牌列
 ·拿到空档以留出一个空牌列
 
 ·调用自动解答
 */
//关于非空牌列的有关信息：牌列，牌数目，序列牌长，活牌数
struct COL_INF { 
	uint col,nCards,nSeri,act;
	void Set(uint a,uint b,uint c,uint d) {
		col = a; nCards = b; nSeri = c; act = d; 
	}
};
/*
 int CmpAct( const void *arg1, const void *arg2 ) 
 {
 COL_INF *p1 = (COL_INF*)arg1;
 COL_INF *p2 = (COL_INF*)arg2;
 
 int res = p1->act - p2->act;
 
 if(p1->act == 0) {
 if(p2->act == 0) { //都无活牌就先拆牌少的列
 return p2->nCards - p1->nCards;
 } else { //有活牌的列比无活牌的列先拆
 return res;
 }
 } else {
 if(p2->act == 0) { //有活牌的列比无活牌的列先拆
 return res;
 } else { //都有活牌
 int diff = p1->act * (p2->nCards - p2->nSeri) - p2->act * (p1->nCards - p1->nSeri);
 if(diff == 0) { //活牌比例一样大
 if(p1->act == p2->act) { //活牌一样多
 return p2->nSeri - p1->nSeri; //先拆序列牌短的列
 } else { //活牌不一样多
 return res; //拆活牌多的列
 }
 } else { //否则先拆活牌（占剩余牌的）比例较大的列
 return diff;
 }
 }
 }
 
 return res;
 }
 */

//对所有的非空牌列，根据活牌数对每个非空牌列进行排序
//活牌数最多的列排在最前
uint* Board::SortByActivity(uint *pCols)
{
	char bc[8+1],rc[4+1],*p,i;
	for(p = bc, i = 1 ; i <= 8 ; i++) { //获取底牌集
		if(!IsEmptyCol(i)) *p++ = BottCard(i); 
	} *p = 0;
	for(p = rc, i = 13; i <= 16; i++) { //获取废牌集
		if(!IsEmptyCol(i)) *p++ = BottCard(i);
		else *p++ = 0;
	} *p = 0;
	
	//统计非空牌列的有关信息：牌列，牌数目，序列牌长，活牌数
	COL_INF f[8+1],*pLast = f;
	for(i = 1 ; i <= 8 ; i++) {
		if(IsEmptyCol(i)) continue;
		
		uint nCards = CntCardsIn(i);
		uint nSeri = CntSeriIn(i);
		uint nAct = 0;
		
		//统计此列的活牌数目
		char b[8+1],r[4+1];  
		strcpy(b,bc); 
		strcpy(r,rc);//复制底牌集和废牌集分别到b，r
		
        uint idx = m_colNum[(uint)i] - nSeri;
        while (idx > 0) {
            char *pAct = FindActiveCard(cards[i-1][idx].tag,b,r);
			if(pAct) {
				*pAct = cards[i-1][idx].tag;
				++nAct;//统计此列的活牌数目
			}
			-- idx;
        }
        
		//保存有关此列牌的信息
		pLast++->Set(i,nCards,nSeri,nAct);
	}
	pLast->col = 0;
	
	//对牌列按照活牌数排序
	COL_INF *pFirst = f;
	while(pFirst < pLast) { 
		COL_INF *p = pLast-1;
		while(--p >= pFirst) {
			if(p->act < (p+1)->act) {
				COL_INF t = p[0]; 
				p[0] = p[1]; 
				p[1] = t; //交换位置
			}
		}
		++pFirst;//活牌数最最多的列已经放到最前了
	}
	//拷贝排序后的牌列到参数数组中
	for(pFirst = f; pFirst < pLast; ) {
		*pCols++ = pFirst++->col;
	} *pCols = 0;
	return pCols;
}

//看看此牌是否可以回收
BOOL Board::Trashable(uint card) {
	if (!IsCard(card))
		return NO;
	
	uint type = TYPE(card);
	if (IsEmptyCol(type+13))
		return NUM(card) == 1;//只有A可以放入空列
	
	return FitTrash(card,BottCard(type+13));//必须花色、点数都相符才行
}

//看看card是否为活牌
char * Board::FindActiveCard(uint card, char *b, char *r)
{
	assert(IsCard(card));
	
	//查看底牌集，看是否可能拿到其他牌列
	for(;*b;++b) if (FitFormula(*b,card)) return b;
	
	//查看废牌集，看是否符合回收规则
	uint type = TYPE(card);
	uint num  = NUM(card);
	if(r[type] == 0) return num == 1 ? &r[type] : 0; //只有A可以放入空列
	
	return FitTrash(card, (uint)r[type]) ? &r[type] : 0;//必须花色、点数都相符才行
}

#if 0
BOOL Board::CanCloseFrame(CFrameWnd* pFrame) 
{
	// TODO: Add your specialized code here and/or call the base class
	if(!GameOver() && !m_pOps->IsEmpty())
		if(IDNO == AfxMessageBox("不玩了么？",MB_YESNO))
			return FALSE;
	
	return CDocument::CanCloseFrame(pFrame);
}
#endif

BOOL Board::GiveUp() 
{
	//当本局为新局或已结束的时候，可以开始下一局
	if(m_pOps->empty() || GameOver()) return true;
	//否则要提醒玩家是否放弃当前局
	// return IDYES == AfxMessageBox("放弃当前游戏？",MB_YESNO);
	return false;
}

//随机开局，但不再产生已经出现过的局
void Board::OnRand() 
{
    int nUniqueGame = Randomx();

	[Settings setCurGameNo: nUniqueGame];
}

void Board::LabelSelected(int lbl) {
	for (int i=0; i<8; ++i) {
		int cnt = m_colNum[i+1];
		for (int j=1; j<=cnt; ++j) {
			if (NUM(lbl) != NUM(cards[i][j].tag))
				continue;
			[gameScene reorderChild:cards[i][j] z:kLayerCard];
			cards[i][j].color = ccGRAY;
		}
	}
}

void Board::LabelUnselect(int lbl) {
	for (int i=0; i<8; ++i) {
		int cnt = m_colNum[i+1];
		for (int j=1; j<=cnt; ++j) {
			if (NUM(lbl) != NUM(cards[i][j].tag))
				continue;
			cards[i][j].color = ccWHITE;
		}
	}

	reorderCards();
}

