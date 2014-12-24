#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>

#define kResetSettingsAlertTag 101

static CGFloat theme = 0.0;

@interface CirculateSettingsListController: PSListController {
}
@end

@interface ViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@end

@implementation CirculateSettingsListController
- (id)specifiers {
	
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"CirculateSettings" target:self] retain];
	}
	return _specifiers;

}

-(void)resetSettings 
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Settings"
		message:@"Are you sure you want to reset settings?"
		delegate:self     
		cancelButtonTitle:@"No" 
		otherButtonTitles:@"Yes", nil];
	alert.tag = kResetSettingsAlertTag;
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
    	if (alertView.tag == kResetSettingsAlertTag) {

    		NSLog(@"[Circulate]Resetting settings");
    		CFPreferencesSetAppValue(CFSTR("enable24hr"), CFSTR("0"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("theme"), CFSTR("0.0"), CFSTR("com.joshdoctors.circulate"));

    		PSSpecifier * espec = [self specifierForID:@"enable24hrswitch"];
    		[self setPreferenceValue:@(NO) specifier:espec];
    		[self reloadSpecifier:espec animated:YES];

    		PSSpecifier * tspec = [self specifierForID:@"themeList"];
    		[self setPreferenceValue:@(0.0) specifier:tspec];
    		[self reloadSpecifier:tspec animated:NO];

    		CFPreferencesSetAppValue(CFSTR("drawGuideS"), CFSTR("1"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("drawGuideM"), CFSTR("1"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("drawGuideH"), CFSTR("1"), CFSTR("com.joshdoctors.circulate"));

    		CFPreferencesSetAppValue(CFSTR("secondsColor"), CFSTR("#FFFFFF:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("secondsBGColor"), CFSTR("#616161:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("secondsRadius"), CFSTR("11"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("secondsBGRadius"), CFSTR("11"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("secondsWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("secondsBGWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));

    		CFPreferencesSetAppValue(CFSTR("minutesColor"), CFSTR("#FFFFFF:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("minutesBGColor"), CFSTR("#616161:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("minutesRadius"), CFSTR("18"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("minutesBGRadius"), CFSTR("18"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("minutesWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("minutesBGWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));

    		CFPreferencesSetAppValue(CFSTR("hoursColor"), CFSTR("#FFFFFF:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("hoursBGColor"), CFSTR("#616161:1.000000"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("hoursRadius"), CFSTR("25"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("hoursBGRadius"), CFSTR("25"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("hoursWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));
    		CFPreferencesSetAppValue(CFSTR("hoursBGWidth"), CFSTR("5"), CFSTR("com.joshdoctors.circulate"));

    		CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.circulate"));
    		CFNotificationCenterPostNotification(
    			CFNotificationCenterGetDarwinNotifyCenter(),
    			CFSTR("com.joshdoctors.circulate/settingschanged"),
    			NULL,
    			NULL,
    			YES
    			);
    	}
    }
}

-(void)twitter {

	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/Fewjative"]];
}

-(void)save
{
    [self.view endEditing:YES];
}

@end

@interface SecondsSettingsListController: PSListController {
}
@end

@implementation SecondsSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {

		theme = (!CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) floatValue]);

		if(theme==0.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"SecondsSettingsCircles" target:self] retain];    
		else if(theme==1.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"SecondsSettingsBars" target:self] retain];
	}
	return _specifiers;

}


-(void)save
{
    [self.view endEditing:YES];
}

@end

@interface MinutesSettingsListController: PSListController {
}
@end

@implementation MinutesSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {

		theme = (!CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) floatValue]);

		if(theme==0.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"MinutesSettingsCircles" target:self] retain];
		else if(theme==1.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"MinutesSettingsBars" target:self] retain];
	}
	return _specifiers;

}

-(void)save
{
    [self.view endEditing:YES];
}

@end

@interface HoursSettingsListController: PSListController {
}
@end

@implementation HoursSettingsListController
- (id)specifiers {
	if(_specifiers == nil) {

		theme = (!CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) ? 0.0 : [(id)CFPreferencesCopyAppValue(CFSTR("theme"), CFSTR("com.joshdoctors.circulate")) floatValue]);

		if(theme==0.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"HoursSettingsCircles" target:self] retain];
		else if(theme==1.0)
			_specifiers = [[self loadSpecifiersFromPlistName:@"HoursSettingsBars" target:self] retain];
	}
	return _specifiers;

}


-(void)save
{
    [self.view endEditing:YES];
}

@end
