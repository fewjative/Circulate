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
    if(_theme==0.0)
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
    else if(_theme==1.0)
    {
        CGRect barRect;
        CGRect guideRect;
        NSInteger origin;
        CGFloat frameWidth = rect.size.width;
        CGFloat padding = (frameWidth*3/17.0);
        CGFloat barSpace = (frameWidth*1/17.0);

        if(self.position==0)//far right bar - seconds
        {
            origin = (padding*3)+(barSpace*2);
        }
        else if(self.position==1)//middle bar - minutes
        {
            origin = (padding*2)+barSpace;
        }
        else//left bar - hours
        {
            origin =  padding;
        }

        if(self.drawGuide)
        {
           guideRect = CGRectMake(rect.origin.x+origin,rect.origin.y+padding,padding,(frameWidth*11/17.0));
           UIBezierPath * guidePath = [UIBezierPath bezierPathWithRoundedRect:guideRect cornerRadius:0];
           [self.marginColor setFill];
           [guidePath fill];
        }
        barRect = CGRectMake(rect.origin.x+origin,rect.origin.y+padding+(frameWidth*11/17.0)*(1-(self.percent/60.0)),padding,(frameWidth*11/17.0)*(self.percent/60.0));
        UIBezierPath * barPath = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:0];
        [self.instanceColor setFill];
        [barPath fill];
    }
    else if(_theme==2.0)
    {
       CGPoint center;
       center.x = rect.origin.x + rect.size.width/2;
       center.y = rect.origin.y + rect.size.height/2;
       CGContextRef ctx = UIGraphicsGetCurrentContext();
       CGContextSaveGState(ctx);

        if(self.position==2)
        {
            if(_drawCircle)
            {
               CGContextSetLineWidth(ctx, 1.0);
               CGContextSetStrokeColorWithColor(ctx, _outerCircleColor.CGColor);
               CGRect circle = CGRectMake(center.x-_outerCircleRadius/2.0,center.y-_outerCircleRadius/2.0,_outerCircleRadius,_outerCircleRadius);
               CGContextAddEllipseInRect(ctx,circle);
               CGContextStrokePath(ctx);
            }
        }

       float timeAsRadians = (float)_percent/60.0 * 2.0 * M_PI - M_PI_2;

       CGPoint newCenter;

       newCenter.x = center.x + _outerCircleRadius/2.0 * cos(timeAsRadians);
       newCenter.y = center.y + _outerCircleRadius/2.0 * sin(timeAsRadians);

       CGContextSetFillColor(ctx, CGColorGetComponents(_instanceColor.CGColor));
       CGRect circle = CGRectMake(newCenter.x-_circleRadius/2.0,newCenter.y-_circleRadius/2.0,_circleRadius,_circleRadius);
       CGContextAddEllipseInRect(ctx,circle);
       CGContextFillPath(ctx);

       CGContextRestoreGState(ctx);
    }
}

- (void)setup
{
    //Leaving this in case I feel the need to use it sometime.
}

@end
