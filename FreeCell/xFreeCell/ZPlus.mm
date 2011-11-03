#import <vector>
#import <fstream>

class CBits 
{
	std::vector<uint8_t> m_arrData;
	int  m_iCurByte;
	char m_iCurBit;
public:
	CBits()
	{
		m_iCurByte = -1;
		m_iCurBit = 7;
	}
	
	uint8_t GetAt(int i) const
	{
		assert(i < GetSize());
		int idxByte = i >> 3;//i/8;
		int idxBit  = i & 7;//i%8;
		return (m_arrData[idxByte] >> (7-idxBit)) & 1;
	}
	
	int GetSize(void) const
	{
		return m_iCurByte < 0 ? 0 : m_iCurByte * 8 + m_iCurBit + 1;
	}
	
	void saveToFile(std::fstream & file) {
		file << m_iCurByte << m_iCurBit;
		for(int i = 0; i <= m_iCurByte; ++i)
			file << m_arrData[i];
	}
	
	void loadFromFile(std::fstream & file) {
		file >> m_iCurByte >> m_iCurBit;
		assert(m_iCurByte >= -1);
		m_arrData.resize(m_iCurByte+1);
		for(int i = 0; i <= m_iCurByte; ++i)
			file >> m_arrData[i];
	}

};

struct Sym {
	uint8_t byte, nLen;
};

struct Tree {
	Tree *l,*r;
	Sym sym;
};
typedef Tree * PTREE;

static void DecodingTree(CBits & treeCode,int & idx, PTREE p);
static void DestroyTree(PTREE p);
void Decoding(std::fstream & desFile, std::fstream & srcFile);

void Decoding(std::fstream & dstFile, std::fstream & srcFile)
{
	//打开输入输出文件
	// CArchive ar(&srcFile,CArchive::load);
	
	CBits codes;
	codes.loadFromFile(srcFile);//1.读出压缩文件
	
	Tree tree;
	int i = 0;
	DecodingTree(codes,i,&tree);//2.还原编码树
	
	//3.取出编码并解码还原成超符号后写入文件
	PTREE p = &tree;
	for(int codesLen = codes.GetSize(); i < codesLen; ++i) {
		//search the symbol in huffman tree with code 
		p = codes.GetAt(i) == 0 ? p->l : p->r;
		if(p->l) continue;
		assert(!p->r);
		//found the symbol at leaf of tree
		for(int n = 0; n < p->sym.nLen; ++n) {
			dstFile<<(p->sym.byte);
		}
		p = &tree;
	}
	DestroyTree(tree.l);
	DestroyTree(tree.r);
}

//从treeCode的第i位开始由其后续位串构建一个huffman树,叶子上存放了超符号
void DecodingTree(CBits & treeCode,int & idx, PTREE p)
{
	assert(treeCode.GetSize() > 0);
	
	if(treeCode.GetAt(idx++) == 1) { //为节点创建子树
		DecodingTree(treeCode,idx,p->l = new Tree);
		DecodingTree(treeCode,idx,p->r = new Tree);
	} else { //叶子上存放超符号
		p->l = p->r = NULL;
		int i;
		for(i = 0; i < 8; ++i) {
			p->sym.byte <<= 1;
			p->sym.byte |= treeCode.GetAt(idx++);
		}
		for(i = 0; i < 8; ++i) {
			p->sym.nLen <<= 1;
			p->sym.nLen |= treeCode.GetAt(idx++);
		}
	}
}

void DestroyTree(PTREE p) {
	if(p->l) {
		assert(p->r);
		DestroyTree(p->l); p->l = NULL;
		DestroyTree(p->r); p->r = NULL;
	}
	delete p;
}

