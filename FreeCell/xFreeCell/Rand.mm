#import <stdlib.h>
#import "Datatype.h"

static double rand_num = 0;

//线性同余法产生随机数 x[n+1] = ( x[n] * a + c ) % m
int my_rand(void) {
	int n = int( rand_num * 8121 + 28411) % (RAND_MAX+1);
	rand_num = n;
	return n;
}

void my_srand(int seed) {
	if(seed > RAND_MAX || seed < 0) seed &= RAND_MAX;
	rand_num = seed;
}


//random_shuffle利用rand来打乱顺序，由于所有rand都已被my_rand代替，所以
//random_shuffle不必重新定义。即使线性同余法产生的随机数并不十分完美，
//只要random_shuffle算法够好，洗牌效果仍可接受。
