//
//  KCUtility.h
//  KeyCastr
//
//  Created by Stephen Deken on 10/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define FAIL_LOUDLY( x, s ) KCFailLoudly( x, s )

void KCFailLoudly( int expr, NSString *message );
