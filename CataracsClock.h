//
//  CataracsClock.h
//  CataracsClock
//

#import <UIKit/UIKit.h>

@interface CataracsClock : UIView
@property (nonatomic) NSInteger minutes;
@property (nonatomic) NSInteger hours;
@property (nonatomic) UIFont *  fontLight;
@property (nonatomic) UIFont *  fontHeavy;
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
