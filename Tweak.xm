#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <CircularProgressTimer.m>
#import <HexClock.m>

#define kBundlePath @"/Library/PreferenceBundles/CirculateSettings.bundle"
#define SYS_VER_GREAT_OR_EQUAL(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:64] != NSOrderedAscending)
#define kDefaultWhiteColor [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]
#define kDefaultGrayColor [[UIColor alloc] initWithRed:97/255.0f green:97/255.0f blue:97/255.0f alpha:1.00f]
#define kDefaultBlackColor [[UIColor alloc] initWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f]

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

static HexClock * hexClockView;

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
static BOOL drawCircle = true;
static NSInteger circleRadius = 55;
static UIColor * circleBackgroundColor;

static UIColor *secondsColor;
static NSInteger secondsRadius;
static NSInteger secondsWidth;
static NSInteger secondsCircleRadius = 10;

static UIColor *secondsBGColor;
static NSInteger secondsBGRadius;
static NSInteger secondsBGWidth;

static UIColor *minutesColor;
static NSInteger minutesRadius;
static NSInteger minutesWidth;
static NSInteger minutesCircleRadius = 15;

static UIColor *minutesBGColor;
static NSInteger minutesBGRadius;
static NSInteger minutesBGWidth;

static UIColor *hoursColor;
static NSInteger hoursRadius;
static NSInteger hoursWidth;
static NSInteger hoursCircleRadius = 20;

static UIColor *hoursBGColor;
static NSInteger hoursBGRadius;
static NSInteger hoursBGWidth;

static BOOL useStaticBackground = YES;
static UIColor *firstColor;
static UIColor *secondColor;
static CGFloat colorMode = 0.0;
static BOOL redrawBackground = NO;

static BOOL hexTime = NO;
static BOOL hexGradient = NO;

static bool hasAdjusted = NO;

static UIImage * defaultIconImage = nil;
static bool hasDefaultIconImage = NO;

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
-(id)image;
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

%new - (UIImage*)solidImage{
    CGRect rect = CGRectMake(0.0f,0.0f,1.0f,1.0f);
    UIGraphicsBeginImageContext(rect.size);
     CGContextRef context= UIGraphicsGetCurrentContext();

     CGContextSetFillColorWithColor(context,[firstColor CGColor]);
     CGContextFillRect(context,rect);

     UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     return image;
}

%new - (UIImage *)radialGradientImage {

    for (UIView * subView in [self.dcImage subviews]) 
    {
        [subView removeFromSuperview];
    }
    // Render a radial background
    // http://developer.apple.com/library/ios/#documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_shadings/dq_shadings.html
    
    // Initialise
    UIGraphicsBeginImageContext(self.frame.size);
    
    // Create the gradient's colours
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 0,0,0,0,  // Start color
                              0,0,0,0 }; // End color
    [firstColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    [secondColor getRed:&components[4] green:&components[5] blue:&components[6] alpha:&components[7]];
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
    
    // Normalise the 0-1 ranged inputs to the width of the image
    CGPoint gradCenter = CGPointMake(self.bounds.size.width/2,self.bounds.size.height/2);
    float myRadius = MIN(self.bounds.size.width, self.bounds.size.height)/2;
    
    // Draw it!
    CGContextRef context= UIGraphicsGetCurrentContext();

    if(context)
    {
        CGContextDrawRadialGradient (context, myGradient, gradCenter,0, gradCenter, myRadius, kCGGradientDrawsAfterEndLocation);
    }
    
    [self.dcImage.layer renderInContext:context];
    // Grab it as an autoreleased image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    // Clean up
    CGColorSpaceRelease(myColorspace); // Necessary?
    CGGradientRelease(myGradient); // Necessary?
    UIGraphicsEndImageContext(); // Clean up
    return image;
}

%new - (void)redrawBackground
{
    if(redrawBackground && theme < 3.0)
    {
        NSLog(@"Redrawing Background");

        for(CAGradientLayer * layer in [[self.dcImage.layer.sublayers copy] autorelease])
        {
            if([layer isKindOfClass:[CAGradientLayer class]])
                [layer removeFromSuperlayer];
        }

        if(useStaticBackground)
        {
            NSLog(@"Using static background");
            NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
            NSString *imagePath = [bundle pathForResource:@"background" ofType:@"png"];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            self.dcImage.image = image;
        }
        else
        {
            if(colorMode==0.0)
            {
                NSLog(@"ColorMode 0.0");
                CAGradientLayer * gradient = [CAGradientLayer layer];
                gradient.frame = self.dcImage.frame;
                gradient.colors = @[(id)firstColor.CGColor,(id)firstColor.CGColor];
                [self.dcImage.layer addSublayer:gradient];
                self.dcImage.image = nil;
            }
            else if(colorMode==1.0)
            {
                NSLog(@"ColorMode 1.0");
                CAGradientLayer * gradient = [CAGradientLayer layer];
                gradient.frame = self.dcImage.frame;
                gradient.colors = @[(id)firstColor.CGColor,(id)secondColor.CGColor];
                [self.dcImage.layer addSublayer:gradient];
                self.dcImage.image = nil;
            }
            else if(colorMode==2.0)
            {
                NSLog(@"ColorMode 2.0");
                self.dcImage.image = nil;
                [self.dcImage setImage:[self radialGradientImage]];
            }
        }

        CALayer * mask = [CALayer layer];
        UIImage * imgMask = [self _iconBasicOverlayImage];
        mask.contents = (id)[imgMask CGImage];
        mask.frame = CGRectMake(0,0,imgMask.size.width,imgMask.size.height);
        self.dcImage.layer.mask = mask;
        self.dcImage.layer.masksToBounds = YES;
        redrawBackground = NO;
        NSLog(@"Finished Drawing Background");
    }
}

%new - (void)applyMask
{
    CALayer * mask = [CALayer layer];
    UIImage * imgMask = [self _iconBasicOverlayImage];
    mask.contents = (id)[imgMask CGImage];
    mask.frame = CGRectMake(0,0,imgMask.size.width,imgMask.size.height);
    self.dcImage.layer.mask = mask;
    self.dcImage.layer.masksToBounds = YES;
}

%new - (void)setDynamicFrame:(CGRect)frameVar
{
	if (self.dcImage && !hasAdjusted)
	{
		NSLog(@"[Circulate]Resetting the frame: %@", NSStringFromCGRect(frameVar));
		CGRect imageRect = CGRectMake(frameVar.origin.x,frameVar.origin.y,frameVar.size.width,frameVar.size.height);
		[self.dcImage setFrame:imageRect];
        redrawBackground = YES;
        [self redrawBackground];
		hasAdjusted = 1;
	}
}

%new - (bool)isNumeric:(NSString*)checkText
{
	return [[NSScanner scannerWithString:checkText] scanFloat:NULL];
}

%new - (void)drawProgressBarSecondsLeft:(NSInteger)seconds
{
    if(theme==0.0 || theme==1.0)
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
            else if([subView isKindOfClass:[HexClock class]])
            {
                [subView removeFromSuperview];
            }
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
    [progressTimerViewSeconds setCircleRadius:secondsCircleRadius];
    [progressTimerViewSeconds setOuterCircleRadius:circleRadius];

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
    [progressTimerViewMinutes setCircleRadius:minutesCircleRadius];
    [progressTimerViewMinutes setOuterCircleRadius:circleRadius];
    progressTimerViewMinutes.tag = 222;

    [self.dcImage addSubview:progressTimerViewMinutes];
    [progressTimerViewMinutes release];
    progressTimerViewMinutes = nil;
}

%new - (void)drawProgressBarHoursLeft:(NSInteger)hours
{
    if(theme==2.0)
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
            else if([subView isKindOfClass:[HexClock class]])
            {
                [subView removeFromSuperview];
            }
        }
    }

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
    [progressTimerViewHours setCircleRadius:hoursCircleRadius];
    [progressTimerViewHours setDrawCircle:drawCircle];
    [progressTimerViewHours setOuterCircleRadius:circleRadius];
    [progressTimerViewHours setOuterCircleColor:circleBackgroundColor];
    progressTimerViewHours.tag = 333;

    [self.dcImage addSubview:progressTimerViewHours];
    [progressTimerViewHours release];
    progressTimerViewHours = nil;
}

%new - (void)drawHexView:(NSInteger)seconds minutes:(NSInteger)minutes hours:(NSInteger)hours
{
    self.dcImage.image  = nil;
    for (UIView * subView in [self.dcImage subviews])
    {
        if ([subView isKindOfClass:[HexClock class]] || [subView isKindOfClass:[CircularProgressTimer class]]) 
        {
                [subView removeFromSuperview];
        }
    }

    CGRect progressBarFrame = self.dcImage.frame;
    hexClockView = [[%c(HexClock) alloc] initWithFrame:progressBarFrame];
    [hexClockView setSeconds:seconds];
    [hexClockView setMinutes:minutes];
    [hexClockView setHours:hours];
    [hexClockView setEnable24hr:enable24hr];
    [hexClockView setHexGradient:hexGradient];
    [hexClockView setHexTime:hexTime];
    hexClockView.tag = 444;

    [self.dcImage addSubview:hexClockView];
    [hexClockView release];
    hexClockView = nil;
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
	  	
        if(theme < 3.0)
        {
            if(theme==0.0 || theme==1.0)
            {
                [self drawProgressBarSecondsLeft:seconds];
                if(drawMinutes || refreshView)[self drawProgressBarMinutesLeft:minutes];
                if(drawHours || refreshView)[self drawProgressBarHoursLeft:hours];
                refreshView = NO;
            }
            else
            {
                if(drawHours || refreshView)[self drawProgressBarHoursLeft:hours];
                if(drawMinutes || refreshView)[self drawProgressBarMinutesLeft:minutes];
                [self drawProgressBarSecondsLeft:seconds];
                refreshView = NO;
            }

        }else if(theme==3.0)
        {
            [self drawHexView:seconds minutes:minutes hours:[components hour]];
            [self applyMask];
        }
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
    NSLog(@"updateAnimatingState");
	%orig;

	if (enableTweak)
	{
        if([self getDefaultIconImage] == nil)
        {
            [self saveDefaultIconImage:[self contentsImage]];
        }

        CALayer * blackDot = MSHookIvar<CALayer*>(self,"_blackDot");
        blackDot.opacity = 0;
        CALayer * hours = MSHookIvar<CALayer*>(self,"_hours");
        hours.opacity = 0;
        CALayer * minutes = MSHookIvar<CALayer*>(self,"_minutes");
        minutes.opacity = 0;
        CALayer * redDot = MSHookIvar<CALayer*>(self,"_redDot");
        redDot.opacity = 0;
        CALayer * seconds = MSHookIvar<CALayer*>(self,"_seconds");
        seconds.opacity = 0;

        [self _setContentImage:nil];
		[self _setAnimating:0];
		[self.dcImage setHidden:0];
        [self redrawBackground];

	}
	else
	{
        if([self getDefaultIconImage] != nil)
        {
            NSLog(@"Saved image is not nil.");
            [self _setContentImage:[self getDefaultIconImage]];
        }

        CALayer * blackDot = MSHookIvar<CALayer*>(self,"_blackDot");
        blackDot.opacity = 1;
        CALayer * hours = MSHookIvar<CALayer*>(self,"_hours");
        hours.opacity = 1;
        CALayer * minutes = MSHookIvar<CALayer*>(self,"_minutes");
        minutes.opacity = 1;
        CALayer * redDot = MSHookIvar<CALayer*>(self,"_redDot");
        redDot.opacity = 1;
        CALayer * seconds = MSHookIvar<CALayer*>(self,"_seconds");
        seconds.opacity = 1;

		[self _setAnimating:1];
		[self.dcImage setHidden:1];
	}
}

-(id)contentsImage{
    id orig = %orig;
    NSLog(@"_contentsImage: %@",orig);

    if(orig != nil)
        [self saveDefaultIconImage:orig];
    return orig;
}

%new - (UIImage*)getDefaultIconImage
{
    NSLog(@"[Circulate]Retrieving backup image.");
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
    NSString *imagePath = [bundle pathForResource:@"defaultIconImage" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    NSLog(@"Retrieved Image: %@",image);
    return image;
}

%new - (void)saveDefaultIconImage:(UIImage*)image
{
    NSLog(@"[Circulate]Saving backup image.");
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
    NSString * direc = [bundle resourcePath];
    NSString * savePath = [NSString stringWithFormat:@"%@%@",direc,@"/defaultIconImage.png"];
    [UIImagePNGRepresentation(image) writeToFile:savePath atomically:YES];
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

    CGFloat tempchoice = theme;

    theme = !CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) floatValue];

    if(tempchoice!=theme)
    {
        refreshView = YES;
        redrawBackground = YES;
    }

    tempchoice = colorMode;

    colorMode = !CFPreferencesCopyAppValue(CFSTR("colorMode"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("colorMode"), CFSTR("com.joshdoctors.circulate")) floatValue];

    if(tempchoice!=colorMode)
    {
        refreshView = YES;
        redrawBackground = YES;
    }

    bool temp = enable24hr;

    enable24hr = !CFPreferencesCopyAppValue(CFSTR("enable24hr"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enable24hr"), CFSTR("com.joshdoctors.circulate")) boolValue];

    if(temp!=enable24hr)
        refreshView = YES;

    temp = drawCircle;

    drawCircle = !CFPreferencesCopyAppValue(CFSTR("drawCircle"), CFSTR("com.joshdoctors.circulate")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("drawCircle"), CFSTR("com.joshdoctors.circulate")) boolValue];

    if(temp!=drawCircle)
    	refreshView = YES;

    temp = useStaticBackground;

    useStaticBackground = !CFPreferencesCopyAppValue(CFSTR("useStaticBackground"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("useStaticBackground"), CFSTR("com.joshdoctors.circulate")) boolValue];

    if(temp!=useStaticBackground)
    {
        refreshView = YES;
        redrawBackground = YES;
    }

    hexTime = !CFPreferencesCopyAppValue(CFSTR("hexTime"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("hexTime"), CFSTR("com.joshdoctors.circulate")) boolValue];
    hexGradient = !CFPreferencesCopyAppValue(CFSTR("hexGradient"), CFSTR("com.joshdoctors.circulate")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("hexGradient"), CFSTR("com.joshdoctors.circulate")) boolValue];
    
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

    UIColor * tempC = circleBackgroundColor;

    circleBackgroundColor = !CFPreferencesCopyAppValue(CFSTR("circleBackgroundColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultWhiteColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("circleBackgroundColor"), CFSTR("com.joshdoctors.circulate")));
    
    if(![tempC isEqual:circleBackgroundColor])
        refreshView = YES;

    tempC = firstColor;

    firstColor = !CFPreferencesCopyAppValue(CFSTR("firstColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultBlackColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("firstColor"), CFSTR("com.joshdoctors.circulate")));
    
    if(![tempC isEqual:firstColor])
    {
        refreshView = YES;
        redrawBackground = YES;
    }

    tempC = secondColor;

    secondColor = !CFPreferencesCopyAppValue(CFSTR("secondColor"), CFSTR("com.joshdoctors.circulate")) ? kDefaultGrayColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("secondColor"), CFSTR("com.joshdoctors.circulate")));
    
    if(![tempC isEqual:secondColor])
    {
        refreshView = YES;
        redrawBackground = YES;
    }

    tempC = secondsColor;

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

    tempV = secondsCircleRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("secondsCircleRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"4";
    secondsCircleRadius = isNumeric(tempS) ? [tempS intValue] : 10;

     if(tempV!=secondsCircleRadius)
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

    tempV = minutesCircleRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("minutesCircleRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"5";
    minutesCircleRadius = isNumeric(tempS) ? [tempS intValue] : 15;

     if(tempV!=minutesCircleRadius)
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

    tempV = hoursCircleRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("hoursCircleRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"6";
    hoursCircleRadius = isNumeric(tempS) ? [tempS intValue] : 20;

     if(tempV!=hoursCircleRadius)
    	refreshView = YES;

/////////////Values for our Hours Integer Options/////////////////

/////////////Values for our Solar Theme Global Integer Options/////////////////

    tempV = circleRadius;

    tempS = (NSString*)CFPreferencesCopyAppValue(CFSTR("circleRadius"), CFSTR("com.joshdoctors.circulate")) ?: @"20";
    circleRadius = isNumeric(tempS) ? [tempS intValue] : 55;

     if(tempV!=circleRadius)
    	refreshView = YES;
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