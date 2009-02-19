//
//  NSBezierPathRoundedRect.m
//  KeyCastr
//
//  Created by Stephen Deken on 10/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSBezierPath+RoundedRect.h"


@implementation NSBezierPath (RoundedRect)

-(void) appendRoundedRect:(NSRect)rect radius:(float)r
{
	if (r > rect.size.width/2.0 || r > rect.size.height/2.0)
	{
		r = fmin(rect.size.width,rect.size.height) / 2.0;
	}
	float rr = r * 0.55228475;
	NSRect innerRect = rect;
	innerRect.origin.x += r;
	innerRect.origin.y += r;
	innerRect.size.width -= r*2;
	innerRect.size.height -= r*2;
	[self moveToPoint:NSMakePoint(innerRect.origin.x-r,innerRect.origin.y)];
	[self relativeLineToPoint:NSMakePoint(0,innerRect.size.height)];
	[self relativeCurveToPoint:NSMakePoint(r,r) controlPoint1:NSMakePoint(0,rr) controlPoint2:NSMakePoint(r-rr,r)];
	[self relativeLineToPoint:NSMakePoint(innerRect.size.width,0)];
	[self relativeCurveToPoint:NSMakePoint(r,-r) controlPoint1:NSMakePoint(rr,0) controlPoint2:NSMakePoint(r,rr-r)];
	[self relativeLineToPoint:NSMakePoint(0,-innerRect.size.height)];
	[self relativeCurveToPoint:NSMakePoint(-r,-r) controlPoint1:NSMakePoint(0,-rr) controlPoint2:NSMakePoint(rr-r,-r)];
	[self relativeLineToPoint:NSMakePoint(-innerRect.size.width,0)];
	[self relativeCurveToPoint:NSMakePoint(-r,r) controlPoint1:NSMakePoint(-rr,0) controlPoint2:NSMakePoint(-r,rr)];
}

@end
