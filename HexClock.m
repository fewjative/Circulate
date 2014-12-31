#import "HexClock.h"

static UIColor* parseColor(NSString* string) {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

static UIColor * lighterColor(UIColor * c){
    CGFloat r,g,b,a;
    if([c getRed:&r green:&g blue:&b alpha:&a])
    {
        return [UIColor colorWithRed:MIN(r + 0.2,1.0)
                               green:MIN(g + 0.2,1.0)
                                blue:MIN(b + 0.2,1.0)
                                alpha:1.0];

    }
    return nil;
}

@implementation HexClock

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        _size = 14;
        _font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:_size];
        _fontHeight = _font.pointSize;
        _yOffset = (frame.size.height - _fontHeight)/2.0;
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGRect textRect = CGRectMake(0,_yOffset,rect.size.width,_fontHeight);

    NSLog(@"font: %@",_font);
    NSLog(@"fontheight: %ld",(long)_fontHeight);
    NSLog(@"yOFF: %ld",(long)_yOffset);
    NSLog(@"textRect: %@",NSStringFromCGRect(textRect));

    NSString *hStr;
    NSString *mStr;
    NSString *sStr;

    if(!_enable24hr)
    {
        if(_hours > 12)
            _hours = _hours - 12;
    }

    if(_hours <=9)
        hStr = [NSString stringWithFormat:@"0%ld",(long)_hours];
    else    
        hStr = [NSString stringWithFormat:@"%ld",(long)_hours];

    if(_minutes <=9)
        mStr = [NSString stringWithFormat:@"0%ld",(long)_minutes];
    else    
       mStr = [NSString stringWithFormat:@"%ld",(long)_minutes];

    if(_seconds <=9)
       sStr = [NSString stringWithFormat:@"0%ld",(long)_seconds];
    else    
        sStr = [NSString stringWithFormat:@"%ld",(long)_seconds];

    NSString * colorString =[NSString stringWithFormat:@"#%@%@%@",hStr,mStr,sStr];
    NSDictionary * attributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    UIColor * color = parseColor(colorString);

    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByClipping;
    textStyle.alignment = NSTextAlignmentCenter;
   
   NSDictionary * stringAttrs = @{NSFontAttributeName:_font, NSParagraphStyleAttributeName:textStyle, NSForegroundColorAttributeName:[UIColor whiteColor]};

    if(!_hexGradient)
    {
        UIBezierPath * guidePath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:0];
        [color setFill];
        [guidePath fill];

        if(_hexTime)
        {
            [colorString drawInRect:textRect withAttributes:stringAttrs];
            NSLog(@"colorString: %@",colorString);
        }
        else
        {
            NSString * timeString =[NSString stringWithFormat:@"%@:%@:%@",hStr,mStr,sStr];
            [timeString drawInRect:textRect withAttributes:stringAttrs];
            NSLog(@"timeString: %@",timeString);
        }
    }
    else
    {
        UIColor * lighter = lighterColor(color);
        UIView * globalView = [[UIView alloc] initWithFrame:rect];

        for (UIView * subView in [self subviews]) 
        {
            [subView removeFromSuperview];
        }

        CAGradientLayer * gradient = [CAGradientLayer layer];
        gradient.frame = rect;
        gradient.colors = @[(id)lighter.CGColor,(id)color.CGColor];

        CATextLayer * label = [[CATextLayer alloc] init];
        [label setFont:_font];
        [label setFontSize:_size];
        [label setFrame:textRect];

        if(_hexTime)
        {
           [label setString:colorString];
        }
        else
        {
            NSString * timeString =[NSString stringWithFormat:@"%@:%@:%@",hStr,mStr,sStr];
           [label setString:timeString];
        }

        [label setAlignmentMode:kCAAlignmentCenter];
        [label setForegroundColor:[[UIColor whiteColor] CGColor]];
        [label setContentsScale:[[UIScreen mainScreen] scale]];

        [globalView.layer insertSublayer:label atIndex:0];
        [globalView.layer insertSublayer:gradient atIndex:0];


        [self addSubview:globalView];
        [label release];
        [globalView release];
    }
}

@end
