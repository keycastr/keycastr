#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

extern NSString *kCAPackageTypeArchive;
extern NSString *kCAPackageTypeCAMLBundle;

@interface CAPackage : NSObject

@property(readonly) CALayer *rootLayer;

+ (id)packageWithData:(NSData *)data type:(NSString *)type options:(id)opts error:(NSError **)outError;
+ (id)packageWithContentsOfURL:(NSURL *)url type:(NSString *)type options:(id)opts error:(NSError **)outError;

@end


@interface CAState : NSObject;
@end


@interface CAStateController : NSObject;

@property (readonly) CALayer* layer;

- (void)setState:(id)state ofLayer:(id)layer transitionSpeed:(float)speed;
- (void)setState:(id)state ofLayer:(id)layer;
- (id)initWithLayer:(id)layer;
- (void)setInitialStatesOfLayer:(id)layer transitionSpeed:(float)speed;

@end
