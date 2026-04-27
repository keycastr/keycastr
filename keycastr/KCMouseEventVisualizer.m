//  Copyright (c) 2022-2023 Andrew Kitchen
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  *    Redistributions of source code must retain the above copyright notice, this
//       list of conditions and the following disclaimer.
//  *    Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions and the following disclaimer in the documentation
//       and/or other materials provided with the distribution.
//  *    Neither the name KeyCastr nor the names of its contributors may be used to
//       endorse or promote products derived from this software without specific
//       prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if !__has_feature(objc_arc)
#error "ARC is required for this file -- enable with --fobjc-arc"
#endif

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import "KCMouseEventVisualizer.h"
#import "KCMouseEvent.h"
#import "NSUserDefaults+Utility.h"
#import "KCKeycastrEvent.h"

NSString * const kKCMouseEffectKey = @"mouse.effect";
NSString * const kKCMouseEffectColor1Key = @"mouse.effectColor1";
NSString * const kKCMouseEffectColor2Key = @"mouse.effectColor2";
NSString * const kKCMouseEffectDurationKey = @"mouse.effectDuration";
NSString * const kKCMouseEffectDensityKey = @"mouse.effectDensity";
NSString * const kKCMouseEffectDiameterKey = @"mouse.effectDiameter";

static NSString *kKCMouseVisualizerDisplayOptionKey = @"mouse.displayOption";

static NSString * const kKCMouseEffectHalo = @"Halo";
static NSString * const kKCMouseEffectBlur = @"Blur";
static NSString * const kKCMouseEffectHaloAndBlur = @"Halo + Blur";
static NSString * const kKCMouseEffectDroplet = @"Droplet";

// Default base diameter (the halo circle, blur core, droplet ring at scale=1) and the upper bound
// the slider exposes — the visualizer window is sized once based on the upper bound, so any
// in-range diameter at any scale fits without clipping.
static CGFloat const kKCMouseEffectDefaultDiameter = 44.0;
static CGFloat const kKCMouseEffectMaxDiameter = 160.0;
static CGFloat const kKCMouseEffectMaxScale = 3.0;
static CGFloat const kKCMouseEffectDefaultDensity = 2.0;
static NSInteger const kKCDropletRingCount = 3;

@interface KCMouseVisualizerWindow : NSWindow

@property (nonatomic, copy) NSString *currentEffect;

- (void)updateWithMouseEvent:(KCMouseEvent *)event;

@end

#pragma mark - KCMouseEventVisualizer

@interface KCMouseEventVisualizer ()

@property (nonatomic, strong) NSArray<NSString *> *mouseDisplayOptionNames;
@property (nonatomic, strong) NSArray<NSString *> *mouseEffectNames;
@property (nonatomic, strong) KCMouseVisualizerWindow *window;

@end

@implementation KCMouseEventVisualizer

@synthesize selectedMouseDisplayOptionIndex = _selectedMouseDisplayOptionIndex;

+ (NSDictionary<NSString *, id> *)defaultPreferences {
    // Defaults are fully opaque so NSColorWell displays a clean swatch (its diagonal "transparency"
    // indicator only appears when alpha < 1). Effect-time alpha is applied via animation opacity.
    NSColor *defaultColor1 = [NSColor colorWithCalibratedRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    NSColor *defaultColor2 = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:1.0 alpha:1.0];
    return @{
        kKCMouseEffectKey: kKCMouseEffectHalo,
        kKCMouseEffectDurationKey: @0.8,
        kKCMouseEffectDensityKey: @(kKCMouseEffectDefaultDensity),
        kKCMouseEffectDiameterKey: @(kKCMouseEffectDefaultDiameter),
        kKCMouseEffectColor1Key: [NSKeyedArchiver archivedDataWithRootObject:defaultColor1 requiringSecureCoding:NO error:NULL],
        kKCMouseEffectColor2Key: [NSKeyedArchiver archivedDataWithRootObject:defaultColor2 requiringSecureCoding:NO error:NULL],
    };
}

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }

    _mouseDisplayOptionNames = @[@"None",
            @"With Mouse Pointer",
            @"With Current Visualizer",
            @"With Pointer and Visualizer"
    ];

    _mouseEffectNames = @[kKCMouseEffectHalo,
                          kKCMouseEffectBlur,
                          kKCMouseEffectHaloAndBlur,
                          kKCMouseEffectDroplet];

    self.selectedMouseDisplayOptionIndex = [NSUserDefaults.standardUserDefaults integerForKey:kKCMouseVisualizerDisplayOptionKey];

    return self;
}

- (void)dealloc {
    [self releaseWindow];
}

- (void)createWindow {
    if (NSApp == nil) return;

    // Sized for the worst-case diameter at max scale plus a small buffer for stroke/shadow overflow.
    CGFloat side = kKCMouseEffectMaxDiameter * kKCMouseEffectMaxScale + 40.0;
    _window = [[KCMouseVisualizerWindow alloc] initWithContentRect:NSMakeRect(0, 0, side, side)
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
    _window.currentEffect = self.currentMouseEffectName;
    [_window orderFrontRegardless];
}

- (void)releaseWindow {
    [_window orderOut:self];
    _window = nil;
}

- (BOOL)isMouseUp:(KCMouseEvent *)mouseEvent {
    return mouseEvent.type == NSEventTypeLeftMouseUp
    || mouseEvent.type == NSEventTypeRightMouseUp
    || mouseEvent.type == NSEventTypeOtherMouseUp;
}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {
    // Options 1 & 3 include displaying the mouse click in the mouse visualizer. MouseUp should always be sent for consistency.
    if (self.selectedMouseDisplayOptionIndex == 1 || self.selectedMouseDisplayOptionIndex == 3 || [self isMouseUp:mouseEvent]) {
        [_window updateWithMouseEvent:mouseEvent];
    }

    // Options 2 & 3 include displaying mouse events in the keystroke visualizer.
    if (self.selectedMouseDisplayOptionIndex >= 2) {
        [self.delegate mouseEventVisualizer:self didNoteMouseEvent:mouseEvent];
    }
}

- (BOOL)isEnabled {
    return (self.selectedMouseDisplayOptionIndex > 0);
}

#pragma mark - KCMouseDisplayOptionsProvider

- (NSString *)currentMouseDisplayOptionName {
    return self.mouseDisplayOptionNames[self.selectedMouseDisplayOptionIndex];
}

- (void)setCurrentMouseDisplayOptionName:(NSString *)currentMouseDisplayOptionName {
    self.selectedMouseDisplayOptionIndex = [self.mouseDisplayOptionNames indexOfObject:currentMouseDisplayOptionName];
}

- (void)setSelectedMouseDisplayOptionIndex:(NSInteger)selectedMouseDisplayOptionIndex {
    _selectedMouseDisplayOptionIndex = selectedMouseDisplayOptionIndex;

    [[NSUserDefaults standardUserDefaults] setInteger:selectedMouseDisplayOptionIndex
                                               forKey:kKCMouseVisualizerDisplayOptionKey];

    [self selectedMouseDisplayOptionDidChange:selectedMouseDisplayOptionIndex];
}

- (void)selectedMouseDisplayOptionDidChange:(NSInteger)selectedMouseDisplayOptionIndex {
    // if NONE or delegate-only then release the _window
    if (selectedMouseDisplayOptionIndex == 0) {
        [self releaseWindow];
    } else if (_window == nil) {
        [self createWindow];
    }
}

- (NSString *)currentMouseEffectName {
    NSString *stored = [[NSUserDefaults standardUserDefaults] stringForKey:kKCMouseEffectKey];
    if ([self.mouseEffectNames containsObject:stored]) {
        return stored;
    }
    return kKCMouseEffectHalo;
}

- (void)setCurrentMouseEffectName:(NSString *)name {
    if (![self.mouseEffectNames containsObject:name]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:kKCMouseEffectKey];
    _window.currentEffect = name;
}

@end

#pragma mark - KCMouseVisualizerWindow

@interface KCMouseVisualizerWindow ()

@property (nonatomic, strong) CAShapeLayer *haloLayer;
@property (nonatomic, strong) CALayer *blurLayer;
@property (nonatomic, strong) NSArray<CAShapeLayer *> *dropletLayers;

@end

@implementation KCMouseVisualizerWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:backing defer:defer]))
        return nil;

    [self setLevel:NSScreenSaverWindowLevel];
    [self setOpaque:NO];
    [self setIgnoresMouseEvents:YES];
    [self setBackgroundColor:[NSColor clearColor]];
    [self setAlphaValue:1];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];

    self.contentView.wantsLayer = YES;

    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    for (NSString *key in [self observedKeys]) {
        [udc addObserver:self forKeyPath:[@"values." stringByAppendingString:key] options:0 context:NULL];
    }

    return self;
}

- (NSArray<NSString *> *)observedKeys {
    return @[kKCMouseEffectColor1Key,
             kKCMouseEffectColor2Key,
             kKCMouseEffectKey,
             kKCMouseEffectDensityKey,
             kKCMouseEffectDiameterKey];
}

- (void)dealloc {
    NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
    for (NSString *key in [self observedKeys]) {
        [udc removeObserver:self forKeyPath:[@"values." stringByAppendingString:key]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self tearDownLayers];
    if ([keyPath hasSuffix:kKCMouseEffectKey]) {
        self.currentEffect = [[NSUserDefaults standardUserDefaults] stringForKey:kKCMouseEffectKey];
    }
}

- (void)tearDownLayers {
    [self.haloLayer removeFromSuperlayer];
    self.haloLayer = nil;
    [self.blurLayer removeFromSuperlayer];
    self.blurLayer = nil;
    for (CAShapeLayer *ring in self.dropletLayers) {
        [ring removeFromSuperlayer];
    }
    self.dropletLayers = nil;
}

#pragma mark - Color/Pref accessors

- (NSColor *)effectColor1 {
    NSColor *c = [[NSUserDefaults standardUserDefaults] colorForKey:kKCMouseEffectColor1Key];
    return c ?: [NSColor colorWithCalibratedRed:0.2 green:0.6 blue:1.0 alpha:0.85];
}

- (NSColor *)effectColor2 {
    NSColor *c = [[NSUserDefaults standardUserDefaults] colorForKey:kKCMouseEffectColor2Key];
    return c ?: [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:1.0 alpha:0.45];
}

- (CGFloat)effectDuration {
    double d = [[NSUserDefaults standardUserDefaults] doubleForKey:kKCMouseEffectDurationKey];
    if (d <= 0.0) d = 0.5;
    return d;
}

- (CGFloat)effectDensity {
    double d = [[NSUserDefaults standardUserDefaults] doubleForKey:kKCMouseEffectDensityKey];
    if (d <= 0.0) d = kKCMouseEffectDefaultDensity;
    return d;
}

- (CGFloat)effectRadius {
    double d = [[NSUserDefaults standardUserDefaults] doubleForKey:kKCMouseEffectDiameterKey];
    if (d <= 0.0) d = kKCMouseEffectDefaultDiameter;
    return d / 2.0;
}

- (NSString *)resolvedEffect {
    NSString *e = self.currentEffect;
    if ([@[kKCMouseEffectHalo, kKCMouseEffectBlur, kKCMouseEffectHaloAndBlur, kKCMouseEffectDroplet] containsObject:e]) {
        return e;
    }
    return kKCMouseEffectHalo;
}

- (NSPoint)windowCenter {
    NSSize size = self.frame.size;
    return NSMakePoint(size.width / 2.0, size.height / 2.0);
}

#pragma mark - Event handling

- (void)updateWithMouseEvent:(KCMouseEvent *)event {
    NSString *effect = [self resolvedEffect];

    switch (event.type) {
        case NSEventTypeLeftMouseDown:
        case NSEventTypeRightMouseDown:
        case NSEventTypeOtherMouseDown: {
            [self centerOnEvent:event];
            [self triggerEffect:effect];
            break;
        }
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeRightMouseDragged:
        case NSEventTypeOtherMouseDragged: {
            // Halo follows the cursor while held; the ripple/blur effects stay anchored at the click site.
            if ([effect isEqualToString:kKCMouseEffectHalo] || [effect isEqualToString:kKCMouseEffectHaloAndBlur]) {
                [self centerOnEvent:event];
            }
            break;
        }
        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseUp:
        case NSEventTypeOtherMouseUp: {
            if ([effect isEqualToString:kKCMouseEffectHalo] || [effect isEqualToString:kKCMouseEffectHaloAndBlur]) {
                [self fadeHalo];
            }
            break;
        }
        default:
            break;
    }
}

- (void)centerOnEvent:(KCMouseEvent *)event {
    NSPoint c = [self windowCenter];
    NSPoint origin = NSMakePoint(event.locationInWindow.x - c.x,
                                 event.locationInWindow.y - c.y);
    [self setFrameOrigin:origin];
}

- (void)triggerEffect:(NSString *)effect {
    if ([effect isEqualToString:kKCMouseEffectHalo]) {
        [self showHaloPersistent];
    } else if ([effect isEqualToString:kKCMouseEffectBlur]) {
        [self runBlurAnimation];
    } else if ([effect isEqualToString:kKCMouseEffectHaloAndBlur]) {
        [self showHaloPersistent];
        [self runBlurAnimation];
    } else if ([effect isEqualToString:kKCMouseEffectDroplet]) {
        [self runDropletAnimation];
    }
}

#pragma mark - Halo

- (void)ensureHaloLayer {
    if (self.haloLayer) return;

    CAShapeLayer *layer = [CAShapeLayer layer];
    CGFloat radius = [self effectRadius];
    CGFloat diameter = 2 * radius;
    CGFloat lineWidth = [self effectDensity];
    NSPoint c = [self windowCenter];
    CGRect rect = CGRectMake(c.x - radius + lineWidth,
                             c.y - radius + lineWidth,
                             diameter - 2 * lineWidth,
                             diameter - 2 * lineWidth);
    layer.path = CGPathCreateWithEllipseInRect(rect, NULL);
    layer.strokeColor = [self effectColor1].CGColor;
    layer.fillColor = NSColor.clearColor.CGColor;
    layer.lineWidth = lineWidth;
    layer.opacity = 0.0;

    [self.contentView.layer addSublayer:layer];
    self.haloLayer = layer;
}

- (void)showHaloPersistent {
    [self ensureHaloLayer];
    // Wrap in a transaction with implicit animations disabled — otherwise CALayer's default
    // 0.25s implicit animation on `opacity` produces a soft fade-in that visibly conflicts
    // with the explicit fade-out animation triggered on mouseUp, reading as a double blink.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.haloLayer.strokeColor = [self effectColor1].CGColor;
    [self.haloLayer removeAllAnimations];
    self.haloLayer.opacity = 1.0;
    [CATransaction commit];
}

- (void)fadeHalo {
    if (!self.haloLayer) return;
    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = @1.0;
    fade.toValue = @0.0;
    fade.duration = [self effectDuration];
    [self.haloLayer addAnimation:fade forKey:@"opacityFade"];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.haloLayer.opacity = 0.0;
    [CATransaction commit];
}

#pragma mark - Blur

- (void)runBlurAnimation {
    [self.blurLayer removeFromSuperlayer];

    CGFloat radius = [self effectRadius];
    CGFloat diameter = 2 * radius;
    NSPoint c = [self windowCenter];
    CGRect bounds = CGRectMake(0, 0, diameter, diameter);

    // Soft-edged disk: a radial gradient layer fading from the chosen color to transparent at the rim.
    // Density controls how much of the radius stays fully opaque before the gradient starts fading.
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.type = kCAGradientLayerRadial;
    NSColor *color = [self effectColor2];
    NSColor *colorAtCenter = [color colorWithAlphaComponent:color.alphaComponent];
    NSColor *colorAtEdge = [color colorWithAlphaComponent:0.0];
    CGFloat density = [self effectDensity];
    // Map density 1..12 → opaque core fraction 0..0.75 of the radius.
    CGFloat opaqueCore = MAX(0.0, MIN(0.85, (density - 1.0) / 14.0));
    layer.colors = @[(__bridge id)colorAtCenter.CGColor, (__bridge id)colorAtCenter.CGColor, (__bridge id)colorAtEdge.CGColor];
    layer.locations = @[@0.0, @(opaqueCore), @1.0];
    layer.startPoint = CGPointMake(0.5, 0.5);
    layer.endPoint = CGPointMake(1.0, 1.0);
    layer.bounds = bounds;
    layer.position = CGPointMake(c.x, c.y);
    layer.opacity = 0.0;

    [self.contentView.layer addSublayer:layer];
    self.blurLayer = layer;

    CGFloat duration = [self effectDuration];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.6;
    scale.toValue = @(kKCMouseEffectMaxScale * 0.7);
    scale.duration = duration;
    scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    CAKeyframeAnimation *opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacity.values = @[@0.0, @1.0, @0.0];
    opacity.keyTimes = @[@0.0, @0.2, @1.0];
    opacity.duration = duration;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = duration;
    group.removedOnCompletion = YES;

    [layer addAnimation:group forKey:@"blurExpand"];
}

#pragma mark - Droplet

- (void)runDropletAnimation {
    for (CAShapeLayer *ring in self.dropletLayers) {
        [ring removeFromSuperlayer];
    }

    CGFloat duration = [self effectDuration];
    CGFloat stagger = duration / (kKCDropletRingCount + 1);
    NSPoint c = [self windowCenter];
    NSColor *color = [self effectColor1];

    NSMutableArray<CAShapeLayer *> *rings = [NSMutableArray array];
    CGFloat radius = [self effectRadius];
    CGFloat diameter = 2 * radius;
    // Droplet rings read a bit thicker than halo at the same density.
    CGFloat ringLineWidth = MAX(2.0, [self effectDensity] * 2.0);
    for (NSInteger i = 0; i < kKCDropletRingCount; i++) {
        CAShapeLayer *ring = [CAShapeLayer layer];
        CGFloat lineWidth = ringLineWidth;
        // Anchor the ring's center on the cursor so transform.scale grows from there
        // instead of scaling around the parent layer's origin.
        ring.bounds = CGRectMake(0, 0, diameter, diameter);
        ring.position = CGPointMake(c.x, c.y);
        ring.path = CGPathCreateWithEllipseInRect(CGRectMake(0, 0, diameter, diameter), NULL);
        ring.fillColor = NSColor.clearColor.CGColor;
        ring.strokeColor = color.CGColor;
        ring.lineWidth = lineWidth;
        ring.opacity = 0.0;
        // Glow halo on both sides of the stroke so the ring reads as a soft wavefront, not a hard outline.
        ring.shadowColor = color.CGColor;
        ring.shadowOpacity = 0.9;
        ring.shadowRadius = 6.0;
        ring.shadowOffset = CGSizeZero;
        ring.masksToBounds = NO;
        [self.contentView.layer addSublayer:ring];
        [rings addObject:ring];

        CGFloat begin = stagger * i;
        CGFloat ringDuration = duration - begin;
        if (ringDuration < 0.1) ringDuration = 0.1;

        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.fromValue = @0.2;
        scale.toValue = @(kKCMouseEffectMaxScale);
        scale.duration = ringDuration;
        scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

        // Slower opacity ramp + lower peak so the rings feel like a swell rather than a strobe.
        CAKeyframeAnimation *opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        opacity.values = @[@0.0, @0.65, @0.0];
        opacity.keyTimes = @[@0.0, @0.4, @1.0];
        opacity.duration = ringDuration;

        // Thin the stroke as it expands so the ring dissipates into the background.
        CABasicAnimation *width = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
        width.fromValue = @(lineWidth);
        width.toValue = @(lineWidth * 0.3);
        width.duration = ringDuration;

        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[scale, opacity, width];
        group.duration = ringDuration;
        group.beginTime = CACurrentMediaTime() + begin;
        group.removedOnCompletion = YES;

        [ring addAnimation:group forKey:@"ripple"];
    }
    self.dropletLayers = rings;
}

@end
