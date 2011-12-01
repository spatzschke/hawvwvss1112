//
//  ControlBar.m
//  HLVideo
//
//  Created by Sebastian Schuler on 01.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ControlBar.h"

@implementation ControlBar

- (void) drawRect:(CGRect)rect {
    
    UIColor *color = [UIColor blackColor];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColor(context, CGColorGetComponents( [color CGColor]));
    CGContextFillRect(context, rect);
    
    self.backgroundColor = [UIColor clearColor];
    self.translucent = YES;
}

@end
