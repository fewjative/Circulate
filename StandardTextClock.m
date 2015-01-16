#import "StandardTextClock.h"

@implementation StandardTextClock

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{

    if(_includeSeconds)
        _size = 14;
    else
        _size = 20;

    _font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:_size];
    _fontHeight = _font.pointSize;
    _yOffset = (rect.size.height - _fontHeight)/2.2;

    CGRect textRect = CGRectMake(0,_yOffset,rect.size.width,_fontHeight);

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

    NSDictionary * attributes = @{NSForegroundColorAttributeName:_textColor};

    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByClipping;
    textStyle.alignment = NSTextAlignmentCenter;
   
    NSDictionary * stringAttrs = @{NSFontAttributeName:_font, NSParagraphStyleAttributeName:textStyle, NSForegroundColorAttributeName:_textColor};

    NSString * timeString;
    if(_includeSeconds)
        timeString = [NSString stringWithFormat:@"%@:%@:%@",hStr,mStr,sStr];
    else
        timeString = [NSString stringWithFormat:@"%@:%@",hStr,mStr];

    [timeString drawInRect:textRect withAttributes:stringAttrs];
    [textStyle release];
    textStyle = nil;
}

@end
