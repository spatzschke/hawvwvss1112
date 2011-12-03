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
        
    CGContextRef context = UIGraphicsGetCurrentContext();
     
    [[UIColor colorWithWhite:0 alpha:0.6f] set];
    CGContextFillRect(context, rect);
     
    self.backgroundColor = [UIColor clearColor];
    self.tintColor = [UIColor whiteColor];  
}

@end
