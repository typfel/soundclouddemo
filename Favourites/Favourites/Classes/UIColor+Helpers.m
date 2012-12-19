//
//  UIColor+Helpers.m
//  Favourites
//
//  Created by Jacob Persson on 2012-12-19.
//  Copyright (c) 2012 Jacob Persson. All rights reserved.
//

#import "UIColor+Helpers.h"

@implementation UIColor (Helpers)

- (UIColor *)desaturateColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:MAX(s * 0.5, 0.0)
                          brightness:b
                               alpha:a];
    return nil;
}

@end
