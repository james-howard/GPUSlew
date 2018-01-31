//
//  AppDelegate.m
//  GPUSlew
//
//  Created by James Howard on 1/16/18.
//  Copyright © 2018 James Howard. All rights reserved.
//

#import "AppDelegate.h"

#import "MetalRenderer.h"
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate () {
    MetalRenderer *_renderer;
    NSMutableArray *_timings;
}

@property (weak) IBOutlet NSWindow *window;
@property IBOutlet NSButton *animateCheck;
@property IBOutlet NSView *animateView;
@property IBOutlet NSTextField *minField;
@property IBOutlet NSTextField *maxField;
@property IBOutlet NSTextField *avgField;
@property IBOutlet NSTextField *gpuField;

@property NSTimer *renderTimer;
@property NSTimer *summaryTimer;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _timings = [NSMutableArray new];
    _renderTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(render:) userInfo:nil repeats:YES];
    _summaryTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(summarize:) userInfo:nil repeats:YES];
    _renderer = [MetalRenderer new];
}

- (void)render:(NSTimer *)timer {
    [_renderer renderWithCompletion:^(NSTimeInterval renderTime) {
        [_timings addObject:@(renderTime)];
    }];
}

- (void)summarize:(NSTimer *)timer {
    if (_timings.count == 0) {
        return;
    }
    
    NSTimeInterval min = 1.0;
    NSTimeInterval max = 0.0;
    NSTimeInterval sum = 0.0;
    for (NSNumber *timing in _timings) {
        NSTimeInterval ti = timing.doubleValue;
        min = MIN(ti, min);
        max = MAX(ti, max);
        sum += ti;
    }
    NSTimeInterval avg = sum / (double)_timings.count;
    [_timings removeAllObjects];
    
    _minField.stringValue = [NSString stringWithFormat:@"%.2lfms", min * 1000.0];
    _maxField.stringValue = [NSString stringWithFormat:@"%.2lfms", max * 1000.0];
    _avgField.stringValue = [NSString stringWithFormat:@"%.2lfms | %.0lf FPS", avg * 1000.0, 1.0 / avg];
    
    _gpuField.stringValue = _renderer.gpuName ?: @"";
}

- (IBAction)toggleAnimation:(id)sender {
    BOOL animate = [_animateCheck state] == NSOnState;
    if (animate) {
        _animateView.hidden = NO;
        CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        a.fromValue = (__bridge id)[[NSColor whiteColor] CGColor];
        a.toValue = (__bridge id)[[NSColor blackColor] CGColor];
        a.duration = 1.0;
        a.repeatCount = FLT_MAX;
        a.autoreverses = YES;
        [_animateView.layer addAnimation:a forKey:@"color"];
    } else {
        [_animateView.layer removeAllAnimations];
        _animateView.layer = nil;
    }
}

@end
