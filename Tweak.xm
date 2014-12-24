#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <CircularProgressTimer.m>

#define kBundlePath @"/Library/PreferenceBundles/CirculateSettings.bundle"
#define SYS_VER_GREAT_OR_EQUAL(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:64] != NSOrderedAscending)
#define kDefaultWhiteColor [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
#define kDefaultGrayColor [[UIColor alloc] initWithRed:97/255.0f green:97/255.0f blue:97/255.0f alpha:1.00f]


@interface UIImage ()
@property (assign,nonatomic) CGRect mediaImageSubRect;
-(CGRect)mediaImageSubRect;
@end

@interface SBIcon : NSObject
-(id)leafIdentifier;
@end

@interface SBIconView : UIView
@end

@implementation SBIconView
@end

@interface SBIconImageView : SBIconView
@end

@implementation SBIconImageView
@end

@interface SBLiveIconImageView : SBIconImageView
@end

@implementation SBLiveIconImageView
@end

@implementation SBClockApplicationIconImageView : SBLiveIconImageView
@end

static NSTimer * timer;
static CircularProgressTimer * progressTimerViewSeconds;
static CircularProgressTimer * progressTimerViewMinutes;
static CircularProgressTimer * progressTimerViewHours;
static NSInteger minutesCache = -1;
static NSInteger hoursCache = -1;
static BOOL enableTweak = NO;
static CGFloat theme = 0.0;
static BOOL enable24hr = NO;
static BOOL drawHours = false;
static BOOL drawMinutes = false;
static BOOL drawGuideS = true;
static BOOL drawGuideM = true;
static BOOL drawGuideH = true;
static BOOL refreshView = false;

static UIColor *secondsColor;
static NSInteger secondsRadius;
static NSInteger secondsWidth;

static UIColor *secondsBGColor;
static NSInteger secondsBGRadius;
static NSInteger secondsBGWidth;

static UIColor *minutesColor;
static NSInteger minutesRadius;
static NSInteger minutesWidth;

static UIColor *minutesBGColor;
static NSInteger minutesBGRadius;
static NSInteger minutesBGWidth;

static UIColor *hoursColor;
static NSInteger hoursRadius;
static NSInteger hoursWidth;

static UIColor *hoursBGColor;
static NSInteger hoursBGRadius;
static NSInteger hoursBGWidth;

static bool hasAdjusted = NO;

@interface SBCirculateIconImageView : SBClockApplicationIconImageView
-(id)initWithFrame:(CGRect)frame;
- (UIImageView*)dcImage;
- (void)setDcImage:(UIImageView*)value;
-(void)dealloc;
-(void)updateAnimatingState;
-(void)updateImageAnimated:(BOOL)animated;
- (void)rotateImageView;
-(void)setIsSpinning:(BOOL)value;
-(bool)isSpinning;
-(void)setDynamicFrame:(CGRect)frame;
-(void)setHasAdjusted:(BOOL)value;
-(bool)hasAdjusted;
- (void)updateCircularProgressBar;
- (void)drawProgressBarSecondsLeft:(NSInteger)seconds;
- (void)drawProgressBarMinutesLeft:(NSInteger)minutes;
- (void)drawProgressBarHoursLeft:(NSInteger)hours;
@end

static bool isNumeric(NSString* checkText)
{
	return [[NSScanner scannerWithString:checkText] scanFloat:NULL];
}

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

%subclass SBCirculateIconImageView : SBClockApplicationIconImageView

%new - (UIImageView*)dcImage
{
	return objc_getAssociatedObject(self,@selector(dcImage));
}

%new - (void)setDcImage:(UIImageView*)value
{
	objc_setAssociatedObject(self,@selector(dcImage),value,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new - (void)setDynamicFrame:(CGRect)frameVar
{
	if (self.dcImage && !hasAdjusted)
	{
		NSLog(@"[Circulate]Resetting the frame: %@", NSStringFromCGRect(frameVar));
		CGRect imageRect = CGRectMake(frameVar.origin.x,frameVar.origin.y,frameVar.size.width,frameVar.size.height);
		[self.dcImage setFrame:imageRect];
		CALayer * mask = [CALayer layer];
		UIImage * imgMask = [self _iconBasicOverlayImage];
		mask.contents = (id)[imgMask CGImage];
		mask.frame = CGRectMake(0,0,imgMask.size.width,imgMask.size.height);
		self.dcImage.layer.mask = mask;
		self.dcImage.layer.masksToBounds = YES;
		hasAdjusted = 1;
	}
}

%new - (bool)isNumeric:(NSString*)checkText
{
	return [[NSScanner scannerWithString:checkText] scanFloat:NULL];
}


%new - (void)drawProgressBarSecondsLeft:(NSInteger)seconds
{
	for (UIView * subView in [self.dcImage subviews]) 
	{
        if ([subView isKindOfClass:[CircularProgressTimer class]]) 
        {
        	if(subView.tag==111 || refreshView)
           		[subView removeFromSuperview];
           	else
           		if(subView.tag==222 && drawMinutes)
           			[subView removeFromSuperview];
           	else
           		if(subView.tag==333 && drawHours)
           			[subView removeFromSuperview];
        }
    }

    CGRect progressBarFrame = self.dcImage.frame;
    progressTimerViewSeconds = [[%c(CircularProgressTimer) alloc] initWithFrame:progressBarFrame];
    [progressTimerViewSeconds setCenter:self.dcImage.center];
    [progressTimerViewSeconds setPercent:seconds];
    [progressTimerViewSeconds setInstanceColor: secondsColor];
    [progressTimerViewSeconds setRadius:secondsRadius];
    [progressTimerViewSeconds setWidth:secondsWidth];
    [progressTimerViewSeconds setDrawGuide:drawGuideS];
    [progressTimerViewSeconds setMarginColor:secondsBGColor];
    [progressTimerViewSeconds setMarginRadius:secondsBGRadius];
    [progressTimerViewSeconds setMarginWidth:secondsBGWidth];
    [progressTimerViewSeconds setTheme:theme];
    [progressTimerViewSeconds setPosition:0];
    progressTimerViewSeconds.tag = 111;

    [self.dcImage addSubview:progressTimerViewSeconds];
    [progressTimerViewSeconds release];
    progressTimerViewSeconds = nil;
}

%new - (void)drawProgressBarMinutesLeft:(NSInteger)minutes
{
    CGRect progressBarFrame = self.dcImage.frame;
    progressTimerViewMinutes = [[%c(CircularProgressTimer) alloc] initWithFrame:progressBarFrame];
    [progressTimerViewMinutes setCenter:self.dcImage.center];
    [progressTimerViewMinutes setPercent:minutes];
    [progressTimerViewMinutes setInstanceColor:minutesColor];
    [progressTimerViewMinutes setRadius:minutesRadius];
    [progressTimerViewMinutes setWidth:minutesWidth];
    [progressTimerViewMinutes setDrawGuide:drawGuideM];
    [progressTimerViewMinutes setMarginColor:minutesBGColor];
    [progressTimerViewMinutes setMarginRadius:minutesBGRadius];
    [progressTimerViewMinutes setMarginWidth:minutesBGWidth];
    [progressTimerViewMinutes setTheme:theme];
    [progressTimerViewMinutes setPosition:1];
    progressTimerViewMinutes.tag = 222;

    [self.dcImage addSubview:progressTimerViewMinutes];
    [progressTimerViewMinutes release];
    progressTimerViewMinutes = nil;
}

%new - (void)drawProgressBarHoursLeft:(NSInteger)hours
{
    CGRect progressBarFrame = self.dcImage.frame;
    progressTimerViewHours = [[%c(CircularProgressTimer) alloc] initWithFrame:progressBarFrame];
    [progressTimerViewHours setCenter:self.dcImage.center];
    [progressTimerViewHours setPercent:hours];
    [progressTimerViewHours setInstanceColor: hoursColor];
    [progressTimerViewHours setRadius:hoursRadius];
    [progressTimerViewHours setWidth:hoursWidth];
    [progressTimerViewHours setDrawGuide:drawGuideH];
    [progressTimerViewHours setMarginColor:hoursBGColor];
    [progressTimerViewHours setMarginRadius:hoursBGRadius];
    [progressTimerViewHours setMarginWidth:hoursBGWidth];
    [progressTimerViewHours setTheme:theme];
    [progressTimerViewHours setPosition:2];
    progressTimerViewHours.tag = 333;

    [self.dcImage addSubview:progressTimerViewHours];
    [progressTimerViewHours release];
    progressTimerViewHours = nil;
}

-(id)initWithFrame:(CGRect)frame
{
	id orig = %orig;

	if (orig != nil)
	{
		NSLog(@"[Circulate]Init");
		NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
		NSString *imagePath = [bundle pathForResource:@"background" ofType:@"png"];
		UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		self.dcImage = [[UIImageView alloc] initWithImage: image];
		CGRect iconRect = CGRectMake(0,0,0,0);
		[self.dcImage setFrame: iconRect];
		self.dcImage.clipsToBounds = YES;
		self.dcImage.tag = 1234;
		hasAdjusted = 0;
		[self addSubview:self.dcImage];
		timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(updateCircularProgressBar)
                                           userInfo:nil
                                            repeats:YES];
	}
	return orig;
}

%new - (void)updateCircularProgressBar
{
	if(hasAdjusted && enableTweak)
	{
		NSDate *today = [NSDate date];
		NSCalendar *gregorian = [[[NSCalendar alloc]
		                         initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDateComponents *components =
		                    [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:today];

		NSInteger hours = [components hour];

        if(enable24hr)
        {
		    hours = ((float)hours/23.0)*60;
        }
        else
        {
            if(hours > 11)
                hours = hours - 12;

            hours = ((float)hours/12.0)*60;
        }

		NSInteger minutes = [components minute];
		NSInteger seconds = [components second];

		if(hours != hoursCache)
		{
			drawHours = YES;
			hoursCache = hours;
		}

		if(minutes != minutesCache)
		{
			drawMinutes = YES;
			minutesCache = minutes;
		}
	  	
	  	[self drawProgressBarSecondsLeft:seconds];
	    if(drawMinutes || refreshView)[self drawProgressBarMinutesLeft:minutes];
	    if(drawHours || refreshView)[self drawProgressBarHoursLeft:hours];
	    refreshView = NO;
	}
}

-(void)dealloc
{
	NSLog(@"[Circulate]Deallocated");
	hasAdjusted = 0;
	[timer invalidate];
	[self.dcImage release];
	%orig;
}

-(void)updateAnimatingState
{
	%orig;

	if (enableTweak)
	{
		[self _setAnimating:0];
		[self.dcImage setHidden:0];
	}
	else
	{
		[self _setAnimating:1];
		[self.dcImage setHidden:1];
	}
}

%end

%hook SBIconView

-(void)_setIcon:(id)icon animated:(BOOL)animated
{
	%orig;

	if ([[icon leafIdentifier] isEqualToString:@"com.apple.mobiletimer"])
	{
		NSLog(@"[Circulate]_setIcon for mobiletimer");
		
		SBClockApplicationIconImageView * img = MSHookIvar<SBClockApplicationIconImageView*>(self,"_iconImageView");

		if([img isKindOfClass:%c(SBClockApplicationIconImageView)])
		{
			NSLog(@"[Circulate]Our image ivar is of the correct class.");
			[img setDynamicFrame:[img bounds]];
		}	
	}
}

%end

static void loadPrefs() 
{
    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.circulate"));

    enableTweak = !CFPreferencesCopyAppValue(CFSTR("enableTweak"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enableTweak"), CFSTR("com.joshdoctors.circulate")) boolValue];
    if (enableTweak) {
        NSLog(@"[Circulate] We are enabled");
    } else {
        NSLog(@"[Circulate] We are NOT enabled");
    }

    CGFloat temptheme = theme;

    theme = !CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) floatValue];

    if(temptheme!=theme)
        refreshView = YES;

    bool temp = enable24hr;

    enable24hr = !CFPreferencesCopyAppValue(CFSTR("enable24hr"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enable24hr"), CFSTR("com.joshdoctors.circulate")) boolValue];

    if(temp!=enable24hr)
        refreshView = YES;
    
    temp = drawGuideS;

    drawGuideS  = !CFPreferencesCopyAppValue(CFSTR("drawGuideS"), CFSTR("com.joshdoctors.circulate")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("drawGuideS"), CFSTR("com.joshdoctors.circulate")) boolValue];
    
    if(temp!=drawGuideS)
    	refreshView = YES;

    temp = drawGuideM;

    drawGuideM   = !CFPreferencesCopyAppValue(CFSTR("drawGuideM"), CFSTR("com.joshdoctors.circulate")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("drawGuideM"), CFSTR("com.joshdoctors.circulate")) boolValue];
    
     if(temp!=drawGuideM)
    	refreshView = YES;

    temp = drawGuideH;

    drawGuideH   = !CFPreferencesCopyAppValue(CFSTR("drawGuideH"), CFSTR("com.joshdoctors.circulate")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("drawGuideH"), CFSTR("com.joshdoctors.circulate")) boolValue];
    
     if(temp!=drawGuideH)
    	refreshView = YES;

    UIColor * tempC = secondsColor;

    secondsColor = !CFPreferencesCopyAppValue(CFSTR("secondsColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultWhiteColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("secondsColor"), CFSTR("com.joshdoctors.circulate")));
    
     if(![tempC isEqual:secondsColor])
    	refreshView = YES;

    tempC = minutesColor;

    minutesColor = !CFPreferencesCopyAppValue(CFSTR("minutesColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultWhiteColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("minutesColor"), CFSTR("com.joshdoctors.circulate")));
    
    if(![tempC isEqual:minutesColor])
    	refreshView = YES;

    tempC = hoursColor;

    hoursColor   = !CFPreferencesCopyAppValue(CFSTR("hoursColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultWhiteColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("hoursColor"), CFSTR("com.joshdoctors.circulate")));

    if(![tempC isEqual:hoursColor])
    	refreshView = YES;

    tempC = secondsBGColor;

    secondsBGColor = !CFPreferencesCopyAppValue(CFSTR("secondsBGColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultGrayColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("secondsBGColor"), CFSTR("com.joshdoctors.circulate")));
    
     if(![tempC isEqual:secondsBGColor])
    	refreshView = YES;

    tempC = minutesBGColor;

    minutesBGColor = !CFPreferencesCopyAppValue(CFSTR("minutesBGColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultGrayColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("minutesBGColor"), CFSTR("com.joshdoctors.circulate")));
    
    if(![tempC isEqual:minutesBGColor])
    	refreshView = YES;

    tempC = hoursBGColor;

    hoursBGColor   = !CFPreferencesCopyAppValue(CFSTR("hoursBGColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultGrayColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("hoursBGColor"), CFSTR("com.joshdoctors.circulate")));

    if(![tempC isEqual:hoursBGColor])
    	refreshView = YES;

/////////////Values for our Seconds Integer Options/////////////////
    NSInteger tempV = secondsRadius;

    NSString * tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("secondsRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"11";
    secondsRadius = isNumeric(tempS) ? [tempS intValue] : 11;

    if(tempV!=secondsRadius)
    	refreshView = YES;

    tempV = secondsBGRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("secondsBGRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"11";
    secondsBGRadius = isNumeric(tempS) ? [tempS intValue] : 11;

    if(tempV!=secondsBGRadius)
    	refreshView = YES;

    tempV = secondsWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("secondsWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    secondsWidth = isNumeric(tempS) ? [tempS intValue] : 5;

    if(tempV!=secondsWidth)
    	refreshView = YES;

    tempV = secondsBGWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("secondsBGWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    secondsBGWidth = isNumeric(tempS) ? [tempS intValue] : 5;

     if(tempV!=secondsBGWidth)
    	refreshView = YES;
/////////////Values for our Seconds Integer Options/////////////////

/////////////Values for our Minutes Integer Options/////////////////

    tempV = minutesRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("minutesRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"18";
    minutesRadius = isNumeric(tempS) ? [tempS intValue] : 18;

    if(tempV!=minutesRadius)
    	refreshView = YES;

    tempV = minutesBGRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("minutesBGRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"18";
    minutesBGRadius = isNumeric(tempS) ? [tempS intValue] : 18;

    if(tempV!=minutesBGRadius)
    	refreshView = YES;

    tempV = minutesWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("minutesWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    minutesWidth = isNumeric(tempS) ? [tempS intValue] : 5;

    if(tempV!=minutesWidth)
    	refreshView = YES;

    tempV = minutesBGWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("minutesBGWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    minutesBGWidth = isNumeric(tempS) ? [tempS intValue] : 5;

     if(tempV!=minutesBGWidth)
    	refreshView = YES;
/////////////Values for our Minutes Integer Options/////////////////

/////////////Values for our Hours Integer Options/////////////////

    tempV = hoursRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("hoursRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"25";
    hoursRadius = isNumeric(tempS) ? [tempS intValue] : 25;

    if(tempV!=hoursRadius)
    	refreshView = YES;

    tempV = hoursBGRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("hoursBGRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"25";
    hoursBGRadius = isNumeric(tempS) ? [tempS intValue] : 25;

    if(tempV!=hoursBGRadius)
    	refreshView = YES;

    tempV = hoursWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("hoursWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    hoursWidth = isNumeric(tempS) ? [tempS intValue] : 5;

    if(tempV!=hoursWidth)
    	refreshView = YES;

    tempV = hoursBGWidth;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("hoursBGWidth"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    hoursBGWidth = isNumeric(tempS) ? [tempS intValue] : 5;

     if(tempV!=hoursBGWidth)
    	refreshView = YES;

/////////////Values for our Hours Integer Options/////////////////
}

%hook SBClockApplicationIcon

-(Class)iconImageViewClassForLocation:(int)arg1
{
	return %c(SBCirculateIconImageView);
}

%end

%ctor
{
	NSLog(@"[Circulate]Loading Circulate");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPrefs,
                                CFSTR("com.joshdoctors.circulate/settingschanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPrefs();
	refreshView = YES;
}