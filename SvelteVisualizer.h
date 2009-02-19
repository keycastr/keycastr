//
//  SvelteVisualizer.h
//  KeyCastr
//
//  Created by Stephen Deken on 2/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KCVisualizer.h"

@interface SvelteVisualizerFactory : KCVisualizerFactory <KCVisualizerFactory>
{
}

-(NSString*) visualizerNibName;
-(Class) visualizerClass;
-(NSString*) visualizerName;

@end

@interface SvelteVisualizer : KCVisualizer <KCVisualizer>
{
	NSWindow* visualizerWindow;
}

-(NSString*) visualizerName;

@end
