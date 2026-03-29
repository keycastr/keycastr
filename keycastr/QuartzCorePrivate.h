#import <Quartz/Quartz.h>
#import <QuartzCore/QuartzCore.h>

extern NSString *kCAPackageTypeArchive;
extern NSString *kCAPackageTypeCAMLBundle;

@interface CAPackage : NSObject

+ (id)packageWithData:(NSData *)data type:(NSString *)type options:(id)opts error:(NSError **)outError;
+ (id)packageWithContentsOfURL:(NSURL *)url type:(NSString *)type options:(id)opts error:(NSError **)outError;

- (NSArray <NSString *> *)publishedObjectNames;

@property(readonly, getter=isGeometryFlipped) BOOL geometryFlipped;
@property(readonly) CALayer *rootLayer;

@end
