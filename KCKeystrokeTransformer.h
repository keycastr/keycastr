//
//  KCKeystrokeTranslator.h
//  KeyCastr
//
//  Created by Stephen Deken on 2/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KCKeystrokeTransformer : NSValueTransformer
{
}

+(void) load;
+(BOOL) allowsReverseTransformation;
+(Class) transformedValueClass;
+(KCKeystrokeTransformer*) sharedTransformer;

-(id) transformedValue:(id)value;

@end
