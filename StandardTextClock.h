#import <UIKit/UIKit.h>

@interface StandardTextClock : UIView
@property (nonatomic) NSInteger seconds;
@property (nonatomic) NSInteger minutes;
@property (nonatomic) NSInteger hours;
@property (nonatomic) UIFont *  font;
@property (nonatomic) NSInteger size;
@property (nonatomic) CGFloat fontHeight;
@property (nonatomic) CGFloat yOffset;
@property (nonatomic) BOOL enable24hr;
@property (nonatomic) BOOL includeSeconds;
@property (nonatomic) UIColor * textColor;
@end
