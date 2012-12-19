//
//  WaveformView.m
//  Favourites
//
//  Created by Jacob Persson on 2012-12-18.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WaveformView.h"
#import "UIColor+Helpers.h"

@implementation WaveformView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib
{
    if (!self.tint) {
        // If no color is set use blue as default
        self.tint = [UIColor blueColor];
    }
}

- (void)setWaveformImage:(UIImage *)waveformImage
{
    _waveformImage = waveformImage;
    [self setNeedsDisplay];
}

- (void)setTint:(UIColor *)tint
{
    _tint = tint;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIColor *startColor = [self.tint desaturateColor];
    UIColor *endColor = self.tint;
    
    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;
    
    [startColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [endColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    // Draw background pattern
    CGGradientRef gradient;
    CGColorSpaceRef colorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = {
        r1, g1, b1, a1, // Start color
        r2, g2, b2, a2  // End color
    };
    
    colorspace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents (colorspace, components, locations, num_locations);
    
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = 0.0;
    myStartPoint.y = 0.0;
    myEndPoint.x = 0.0;
    myEndPoint.y = self.bounds.size.height;
    CGContextDrawLinearGradient (ctx, gradient, myStartPoint, myEndPoint, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    
    // Etch out the waveform
    [self.waveformImage drawInRect:rect blendMode:kCGBlendModeDestinationOut alpha:1.0];
}

@end
