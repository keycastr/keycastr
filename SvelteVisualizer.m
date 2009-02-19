//
//  SvelteVisualizer.m
//  KeyCastr
//
//  Created by Stephen Deken on 2/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SvelteVisualizer.h"


@implementation SvelteVisualizerFactory

-(NSString*) visualizerNibName
{
	return @"Svelte";
}

-(Class) visualizerClass
{
	return [SvelteVisualizer class];
}

-(NSString*) visualizerName
{
	return @"Svelte";
}

@end



@implementation SvelteVisualizer

-(NSString*) visualizerName
{
	return @"Svelte";
}

@end
