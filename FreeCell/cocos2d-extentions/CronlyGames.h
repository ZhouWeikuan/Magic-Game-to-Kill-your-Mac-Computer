#import "cocos2d.h"

extern float calcRotation(CGPoint old, CGPoint now);
extern void Sleep(int millisecond);
extern long getCurrentMillisecond();


@interface CCNode (Game)
- (void) removeSelf:(id)sender;
- (CCSprite*) addSprite:(NSString*)file pos:(CGPoint)pos z:(int)z; 
- (CCMenuItemSprite*) addMenuItem:(NSString*)n sele:(NSString*)s call:(SEL)c pos:(CGPoint)p;
- (CCMenuItemSprite*) addMenuItem:(NSString*)n sele:(NSString*)s dis:(NSString*)d call:(SEL)c pos:(CGPoint)p;
- (void) updateMenuItem:(CCMenuItemSprite*)item normal:(NSString*)n sele:(NSString*)s;

- (CCMenuItemSprite*) addFrameCacheMenuItem:(NSString*)n sele:(NSString*)s call:(SEL)c pos:(CGPoint)p;
@end

@interface CCAnimation (Game)
- (void) addFrameWithFile:(NSString*)file;
+ (CCParticleSystem*) getClearEffect;
@end

@interface CCSprite (Game)
- (void) updateTextureWithFile:(NSString*)file;
+(id)spriteWithFile:(NSString*)filename;
@end
