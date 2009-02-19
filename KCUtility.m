//
//  KCUtility.m
//  KeyCastr
//
//  Created by Stephen Deken on 10/15/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "KCUtility.h"

void KCFailLoudly( int expr, NSString *message )
{
	if (expr)
	{
		if (NSApp == nil)
			NSApplicationLoad();
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Close"];
		[alert setMessageText:@"Catastropic Error Encountered"];
		[alert setInformativeText:[NSString stringWithFormat:@"%@\n\nKeyCastr will now terminate.", message]];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
		[NSApp terminate:nil];
	}
}