/**
 * UpperControlBar.m
 * 
 * Responsible for the upper control bar
 *
 * Copyright 2011 
 *   - Sebastian Schuler
 *   - Jennifer Schoendorf
 *   - Stan Patzschke
 */

#import "UpperControlBar.h"

@implementation UpperControlBar

- (void) drawRect:(CGRect)rect {
        
    CGContextRef context = UIGraphicsGetCurrentContext();
     
    [[UIColor colorWithWhite:0 alpha:0.6f] set];
    CGContextFillRect(context, rect);
     
    self.backgroundColor = [UIColor clearColor];
    self.tintColor = [UIColor whiteColor];  
}

@end
