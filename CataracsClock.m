#import "CataracsClock.h"

/*
@interface CataracsClock : UIView
@property (nonatomic) NSInteger minutes;
@property (nonatomic) NSInteger hours;
@property (nonatomic) UIFont *  font;
@property (nonatomic) NSInteger size;
@property (nonatomic) CGFloat fontHeight;
@property (nonatomic) CGFloat yOffset;
@property (nonatomic) BOOL enable24hr;

@property (nonatomic) CGFloat width;
@property (nonatomic) BOOL boldHours;
@property (nonatomic) BOOL isVertical;
@property (nonatomic) NSString * separator;
@property (nonatomic) UIColor * fontColor;
@property (nonatomic) UIColor * boxColor;
@end
*/

@implementation CataracsClock

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
	_size = 17;
	_fontLight = [UIFont fontWithName:@"Avenir-Light" size:_size];
    _fontHeavy = [UIFont fontWithName:@"Avenir-Heavy" size:_size];
    _fontHeight = _fontLight.pointSize;

    if(!_enable24hr)
    {
        if(_hours > 12)
            _hours = _hours - 12;
    }

    NSString *hStr;
    NSString *mStr;

    if(_hours <=9)
        hStr = [NSString stringWithFormat:@"0%ld",(long)_hours];
    else    
        hStr = [NSString stringWithFormat:@"%ld",(long)_hours];

    if(_minutes <=9)
        mStr = [NSString stringWithFormat:@"0%ld",(long)_minutes];
    else    
       mStr = [NSString stringWithFormat:@"%ld",(long)_minutes];

   NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
   textStyle.lineBreakMode = NSLineBreakByClipping;
   textStyle.alignment = NSTextAlignmentCenter;

  if(_isVertical)
  {

  		//17/62 = .2742
  		//We have used 8/17.0 for padding. we need text + buffer + text.
  		//Middle padding should be (2/17.0)
  		//(2/17)+(2/17)+(17 px)  + (2/17) + (17px) + (2/17)+(2/17)
  		//(10/17)  + 4.66px + 4.66px
  		//9.32580

        //CGFloat firstyOff = (3.0/17.0)*rect.size.width;
        //CGRect firstTextRect = CGRectMake(0,firstyOff,rect.size.width,_fontHeight);
        //CGRect secondTextRect = CGRectMake(0,firstTextRect.origin.y + _fontHeight,rect.size.width,_fontHeight);
  		CGFloat textBlock = 17.0 +17.0 + (2.0/17.0)*rect.size.width;
  		_yOffset = (rect.size.height - textBlock)/2.0;
  		CGRect firstTextRect = CGRectMake(0,_yOffset,rect.size.width,_fontHeight);
  		CGRect secondTextRect = CGRectMake(0,(8.0/17.0)*rect.size.width,rect.size.width,_fontHeight);

        NSMutableAttributedString * firstStr = [[NSMutableAttributedString alloc] initWithString:hStr];
        if(_boldHours)
        	[firstStr addAttribute:NSFontAttributeName value:_fontHeavy range:NSMakeRange(0,[firstStr length])];
		else
			[firstStr addAttribute:NSFontAttributeName value:_fontLight range:NSMakeRange(0,[firstStr length])];

        [firstStr addAttribute:NSForegroundColorAttributeName value:_fontColor range:NSMakeRange(0,[firstStr length])];
        [firstStr addAttribute:NSParagraphStyleAttributeName value:textStyle range:NSMakeRange(0,[firstStr length])];

     	[firstStr drawInRect:firstTextRect];

     	NSMutableAttributedString * secondStr = [[NSMutableAttributedString alloc] initWithString:mStr];
		[secondStr addAttribute:NSFontAttributeName value:_fontLight range:NSMakeRange(0,[secondStr length])];
        [secondStr addAttribute:NSForegroundColorAttributeName value:_fontColor range:NSMakeRange(0,[secondStr length])];
        [secondStr addAttribute:NSParagraphStyleAttributeName value:textStyle range:NSMakeRange(0,[secondStr length])];

        [secondStr drawInRect:secondTextRect];

        [firstStr release];
        firstStr = nil;
        [secondStr release];
        secondStr = nil;

	    CGRect timeOutline = CGRectMake((4.0/17.0)*rect.size.width,(2.0/17.0)*rect.size.width,(9.0/17.0)*rect.size.width,(13.0/17.0)*rect.size.width);
	    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:timeOutline];
	    rectPath.lineWidth = _width;
	    [_boxColor setStroke];
	    [rectPath stroke];
  }
  else
  {

  	_yOffset = (rect.size.height - _fontHeight)/2.2;
  	CGRect textRect = CGRectMake(0,_yOffset,rect.size.width,_fontHeight);

    if(!_boldHours)
    {
     
      NSString * timeString = [NSString stringWithFormat:@"%@%@%@",hStr,_separator,mStr];
      NSDictionary * attributes = @{NSForegroundColorAttributeName:_fontColor};
      NSDictionary * stringAttrs = @{NSFontAttributeName:_fontLight, NSParagraphStyleAttributeName:textStyle, NSForegroundColorAttributeName:_fontColor};
      [timeString drawInRect:textRect withAttributes:stringAttrs];

    }
    else
    {
        NSString * timeString = [NSString stringWithFormat:@"%@%@%@",hStr,_separator,mStr];
        NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:timeString];
        [str addAttribute:NSFontAttributeName value:_fontHeavy range:NSMakeRange(0,[str length] - 2)];
        [str addAttribute:NSFontAttributeName value:_fontLight range:NSMakeRange([str length] - 2, 2)];
        [str addAttribute:NSForegroundColorAttributeName value:_fontColor range:NSMakeRange(0,[str length])];
        [str addAttribute:NSParagraphStyleAttributeName value:textStyle range:NSMakeRange(0,[str length])];
        [str drawInRect:textRect];
        [str release];
        str = nil;
    }

    CGFloat padding = (2.0/17.0)*rect.size.width;
    CGRect timeOutline = CGRectMake(padding,(5.0/17.0)*rect.size.width,(13.0/17.0)*rect.size.width,(7.0/17.0)*rect.size.width);
    UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:timeOutline];
    rectPath.lineWidth = _width;
    [_boxColor setStroke];
    [rectPath stroke];
  }

  [textStyle release];
  textStyle = nil;
}

@end
