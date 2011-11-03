#import "CronlyGames.h"
#import "AllGames.h"

void Sleep(int millisecond) {
	[NSThread sleepForTimeInterval:0.001 * millisecond];
}

float calcAngle(CGPoint old, CGPoint now){
    now.x -= old.x;
    now.y -= old.y;
    return ccpAngle(ccp(0.f, -1.f), ccp(now.x, now.y));
}

float calcRotation(CGPoint old, CGPoint now){
    float radius = calcAngle(old, now);
    radius = CC_RADIANS_TO_DEGREES(radius);
    if (now.x - old.x > 0){
        radius = 360 - radius;
    }
    // NSLog(@"the angle is (%f, %f) = %f", now.x, now.y, radius);
	
    return radius;
}

long getCurrentMillisecond() {
    static NSTimeInterval origin = CACurrentMediaTime();
    NSTimeInterval now = CACurrentMediaTime() - origin;
    now *= 1000.0f;
 
	return (long)now;
}

@implementation CCNode (Game)
- (CCSprite*) addSprite:(NSString*)file pos:(CGPoint)pos z:(int)z
{
	CCSprite * ret  = [CCSprite spriteWithFile:file];
	[self addChild:ret z:z];
	ret.position	= pos;
	return ret;
}
- (void) removeSelf:(id)sender {
	[self removeFromParentAndCleanup: YES];
}

- (CCMenuItemSprite*) addMenuItem:(NSString*)n sele:(NSString*)s call:(SEL)c pos:(CGPoint)p
{
    CCSprite *norm = [CCSprite spriteWithFile:n];
    CCSprite *sele = [CCSprite spriteWithFile:s];
	
    CCMenuItemSprite * item = [CCMenuItemSprite itemFromNormalSprite:norm selectedSprite:sele target:self selector:c];
    item.position = p;
	
    return item;
}
- (CCMenuItemSprite*) addMenuItem:(NSString*)n sele:(NSString*)s dis:(NSString*)d call:(SEL)c pos:(CGPoint)p;
{
	CCSprite *norm = [CCSprite spriteWithFile:n];
    CCSprite *sele = [CCSprite spriteWithFile:s];
    CCSprite * dis = [CCSprite spriteWithFile:d];
	
    CCMenuItemSprite * item = [CCMenuItemSprite itemFromNormalSprite:norm
													  selectedSprite:sele
													  disabledSprite:dis
															  target:self
															selector:c];
    item.position = p;
	
    return item;
}
- (void) updateMenuItem:(CCMenuItemSprite*)item normal:(NSString*)n sele:(NSString*)s {
	CCSprite * obj = (CCSprite*)item.normalImage;
	[obj updateTextureWithFile: n];
	obj = (CCSprite*)item.selectedImage;
	[obj updateTextureWithFile: s];
}

- (CCMenuItemSprite*) addFrameCacheMenuItem:(NSString*)n sele:(NSString*)s call:(SEL)c pos:(CGPoint)p
{
    CCSpriteFrameCache * cache = [CCSpriteFrameCache sharedSpriteFrameCache];
    CCSprite *norm = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName: n]];
    CCSprite *sele = [CCSprite spriteWithSpriteFrame: [cache spriteFrameByName: s]];
	
    CCMenuItemSprite * item = [CCMenuItemSprite itemFromNormalSprite:norm selectedSprite:sele target:self selector:c];
    item.position = p;
	
    return item;
}
@end

@implementation CCAnimation (Game)
- (void) addFrameWithFile:(NSString*)file {
	CCTexture2D * tex = [[CCTextureCache sharedTextureCache] addImage:file];
	CGRect rect = CGRectZero;
	rect.size = tex.contentSize;
	CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:tex rect:rect];
	
	[self addFrame: frame];
}
+ (CCParticleSystem*) getClearEffect {
	float fontScale = 1.0f;//float fontScale = (isIPad()?1.0f:0.5f);
	CCParticleSystem * e = [CCParticleFlower node];
	e.autoRemoveOnFinish = YES;
	
	NSString * key = @"stars.png";
	e.texture = [[CCTextureCache sharedTextureCache] addImage:key];
	e.duration = 0.7f;
	e.speed = 72 * fontScale;
	e.speedVar = 10 * fontScale;

	e.startSize = 20.0f * fontScale;
	e.startSizeVar = 5.0f * fontScale;
	
	return e;
}
@end

@implementation CCSprite (Game)
- (void) updateTextureWithFile:(NSString*)file {
	CCTexture2D * tex = [[CCTextureCache sharedTextureCache] addImage:file];
	self.texture = tex;
}
+(id)spriteWithFile:(NSString*)filename {
	return [[[self alloc] initWithFile:filename] autorelease];
}
@end

