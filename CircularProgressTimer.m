//
//  CircularProgressTimer.m
//  CircularProgressTimer
//
//  Created by mc on 6/30/13.
//  Copyright (c) 2013 mauricio. All rights reserved.
//

#import "CircularProgressTimer.h"

@implementation CircularProgressTimer

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setup];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    if(self.drawGuide)
    {
        UIBezierPath *marginCircle = [UIBezierPath bezierPath];
        [marginCircle addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                                radius:self.marginRadius
                            startAngle:0
                              endAngle:2 * M_PI
                             clockwise:YES];
        marginCircle.lineWidth = self.marginWidth;
        [self.marginColor setStroke];
        [marginCircle stroke];
    }

    float initialAngleFactor = 1.5 * M_PI;
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                          radius:self.radius
                      startAngle:0 + initialAngleFactor
                        endAngle:(_percent * M_PI) / 30.0 + initialAngleFactor
                       clockwise:YES];
    
    bezierPath.lineWidth = self.width;
    [self.instanceColor setStroke];
    [bezierPath stroke];
}

- (void)setup
{
    //Leaving this in case I feel the need to use it sometime.
}

@end
