#import <vector>
#import <fstream>

inline int CARD(int num,int type) {
    return (num + type*13);   
}
inline BOOL IS_CARD(int card) {
    return (card<=52 && card>=1);
}

//  | 1 ... 13 | 14 ... 26 | 27 ... 39  | 40 ... 52 |
//  | A ...  K |  A ...  K |  A ...  K  |  A ...  K |
//  | - 黑桃 -  | － 红桃 － |  － 梅花－   |  － 方块－ |
//花色: 0黑桃 1红桃 2梅花 3方块
inline uint TYPE(uint card) {
    return ((card-1)/13);
}
//点数 1－13
inline uint NUM(uint card) {
    return ((card-1)%13+1);
}
inline BOOL COL_IN_CARD(int col) {
    return (col <= 8);
}
inline BOOL COL_IN_BUFF(int col) {
    return (col>=9 && col<=12);
}
inline BOOL COL_IN_RECY(int col) {
    return (col>=13);
}

const CGPoint ptOrg = CGPointMake(1,17);//牌局左上角

const int CARD_HEI = 76; // 每张牌的高度height
const int CARD_WID = 48; // 每张牌的宽度width
const int CARD_INT = 8;

// 代表1-8列中每两堆牌之间的间隔(interval)
// （第9,16两列分别与窗口两边的间距也是这个值）
const int PILE_VINT = 8; // 牌列与缓存列间垂直方向上的间隔
const int PILE_HINT = 9*CARD_INT; //缓存列与回收列之间的水平间隔
const int CARD_UNCOVER = 18; // 当被一张牌压着的时候，此露出的部分的高度

//usage: clr[BIG/SML][HT/HX/MH/FK][UP/DN][X/Y]...
const uint8_t BIG=0, SML=1, big=16, sml=8;
const uint8_t clr[2][4][2][2] = {
	{	{	{0 *big,1 *big},//黑桃上
		{1 *big,1 *big},//黑桃下
	},{	{0 *big,2 *big},//红桃上
		{1 *big,2 *big},//红桃下
	},{	{0 *big,3 *big},//梅花上
		{1 *big,3 *big},//梅花下
	},{	{0 *big,4 *big},//方块上
		{1 *big,4 *big},//方块下
	}
	},{	{	{0 *sml,0 *sml},
		{0 *sml,1 *sml}
	},{	{1 *sml,0 *sml},
		{1 *sml,1 *sml}
	},{	{2 *sml,0 *sml},
		{2 *sml,1 *sml}
	},{	{3 *sml,0 *sml},
		{3 *sml,1 *sml}
	}
	}
};
//牌A－－牌10的图像数据
const uint8_t x12   = CARD_WID      /  2;
const uint8_t x13   = CARD_WID *  9 / 30;
const uint8_t x23   = CARD_WID * 21 / 30;
const uint8_t y12   = CARD_HEI      /  2;
const uint8_t y15   = CARD_HEI      /  5;
const uint8_t y25   = CARD_HEI *  2 /  5;
const uint8_t y35   = CARD_HEI *  3 /  5;
const uint8_t y45   = CARD_HEI *  4 /  5;
const uint8_t y310  = CARD_HEI *  3 / 10;
const uint8_t y710  = CARD_HEI *  7 / 10;
const uint8_t y720  = CARD_HEI *  7 / 20;
const uint8_t y1320 = CARD_HEI * 13 / 20;

const uint8_t cA[] = { x12 , y12 , 1, };
const uint8_t c2[] = { x12 , y15 , 1, x12 , y45 , 0, };
const uint8_t c3[] = { x12 , y15 , 1, x12 , y45 , 0, x12 , y12 , 1, };
const uint8_t c4[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y45 , 0, x23 , y45 , 0, };
const uint8_t c5[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y45 , 0, x23 , y45 , 0, x12 , y12 , 1, };
const uint8_t c6[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y45 , 0, x23 , y45 , 0, x13 , y12 , 1, x23 , y12 , 1, };
const uint8_t c7[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y45 , 0, x23 , y45 , 0, x13 , y12 , 1, x23 , y12 , 1, x12 , y720 , 1 , };
const uint8_t c8[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y25 , 1, x23 , y25 , 1, x13 , y35 , 0, x23 , y35 , 0, x13 , y45  , 0 , x23 , y45   , 0 };
const uint8_t c9[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y25 , 1, x23 , y25 , 1, x13 , y35 , 0, x23 , y35 , 0, x13 , y45  , 0 , x23 , y45   , 0 , x12 , y12  , 1 , };
const uint8_t c10[]= { x13 , y15 , 1, x23 , y15 , 1, x13 , y25 , 1, x23 , y25 , 1, x13 , y35 , 0, x23 , y35 , 0, x13 , y45  , 0 , x23 , y45   , 0 , x12 , y310 , 1 , x12 , y710 , 0 , };
const uint8_t c8FK[] = { x13 , y15 , 1, x23 , y15 , 1, x13 , y45 , 0, x23 , y45 , 0, x13 , y12 , 1, x23 , y12 , 1, x12 , y720 , 1 , x12 , y1320 , 0 , };

// const uint modeCrWr = CFile::modeWrite | CFile::modeCreate;
// const uint modeRead = CFile::modeRead;
// const uint16_t dwFlags = OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT;
// static const char * filter = "接龙存档文件(*.rep)|*.rep||";//文件名过滤器

//步骤计数的字体高度
const uint stepFont = 22;

//解码
// void Decoding(CFile & desFile, CFile & srcFile);

//////////////////////////////////////////////////////////
class COperation
{

public:
	uint8_t des;
	uint8_t src;//记录从第src列移动cnt张牌到第des列
	uint8_t cnt;
	
	COperation() 
	: des(0),src(0),cnt(0) 
	{ }
	
	COperation(uint d,uint s,uint n) 
	: des(d),src(s),cnt(n) 
	{ }
	
	void saveToFile(std::fstream & file) {
		file<<src<<des<<cnt;
	}
	void readFromFile(std::fstream & file) {
		file>>src>>des>>cnt;
	}
};
//////////////////////////////////////////////////////////
class COperations
{
public:
	COperations():pOps() 
	{	
	}
	
	COperations(uint des,uint src,uint n):pOps() 
	{
		pOps.push_back(COperation(des,src,n)); 
	}
	
	void AddOperation(uint des,uint src,uint n) { 
		pOps.push_back(COperation(des,src,n)); 
	}
	
	void ClrOps() {
		pOps.clear();
	}
	
	~COperations() { 
		ClrOps();
	}
	
	// void Serialize(CArchive &ar) {
	//	pOps->Serialize(ar);
	// }
	
	std::vector<COperation> pOps;
};

//////////////////////////////////////////////////////////
//记录下一步的所有可能的移动步骤用于提示
class HINTS : public COperations
{
	int curHint;
public:
	HINTS() {
		curHint = 0;
	}
	//
	// before call NextHint, you must firstly 
	// call COperations::AddOperation to fill
	// the operation list, for it should NOT be 
	// empty
	//
	const COperation NextHint(void) {
		assert(!pOps.empty());
		
		return pOps.back();
	}
	void ClrHints(void) {
		ClrOps();
		curHint = 0;
	}
	BOOL IsEmpty() {
		return pOps.empty();
	}
};

///////////////////////////////////
struct CARD_POS {
	uint col;
	uint idx;
};
///////////////////////////////////

#define MIN_GAME_NUMBER 1
#define MAX_GAME_NUMBER 0x7FFFFFFF


