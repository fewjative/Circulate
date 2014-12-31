#import <UIKit/UIKit.h>

@interface HexClock : UIView
@property (nonatomic) NSInteger seconds;
@property (nonatomic) NSInteger minutes;
@property (nonatomic) NSInteger hours;
@property (nonatomic) UIFont *  font;
@property (nonatomic) NSInteger size;
@property (nonatomic) CGFloat fontHeight;
@property (nonatomic) CGFloat yOffset;
@property (nonatomic) BOOL enable24hr;
@property (nonatomic) BOOL hexGradient;
@property (nonatomic) BOOL hexTime;
@end
