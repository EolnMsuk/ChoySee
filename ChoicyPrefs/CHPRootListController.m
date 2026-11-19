// Copyright (c) 2019-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "CHPRootListController.h"
#import "../Shared.h"
#import "CHPDaemonList.h"
#import "CHPTweakList.h"
#import <mach-o/dyld.h>
#import "CHPPreferences.h"
#import "CHPApplicationListSubcontrollerController.h"
#import "CHPProcessConfigurationListController.h"
#import "ChoySeeDonationController.h"
#import "ChoySeeSettingsPresentation.h"
#import "ChoySeeUpdateChecker.h"
#import "CoreServices.h"
#import "../ChoicyPrefsMigrator.h"
#import "../ChoicyRoot.h"

NSArray *dylibsBeforeChoicy;

#import <dirent.h>

NSDictionary *preferences;

void choicy_reloadPreferences()
{
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ choicy_reloadPreferences(); });
		return;
	}
	NSDictionary *updated = [NSDictionary dictionaryWithContentsOfFile:kChoicyPrefsPlistPath] ?: @{};
	BOOL changed = ![preferences isEqualToDictionary:updated];
	preferences = updated;
	if (changed) {
		choicyInvalidateApplicationPluginCache();
		[[NSNotificationCenter defaultCenter] postNotificationName:kChoicyPreferencesDidReloadNotification object:nil];
	}
}

static void choicyPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	choicy_reloadPreferences();
}

NSMutableDictionary *preferencesForWriting()
{
	if (preferences.count) {
		return preferences.mutableCopy;
	}
	else {
		NSMutableDictionary *mutablePrefs = [NSMutableDictionary new];
		[ChoicyPrefsMigrator updatePreferenceVersion:mutablePrefs];
		return mutablePrefs;
	}
}

void writePreferences(NSMutableDictionary *mutablePrefs)
{
	[mutablePrefs writeToFile:kChoicyPrefsPlistPath atomically:YES];
	choicy_reloadPreferences();
	[CHPListController sendChoicyPrefsPostNotification];
}

NSArray *getInjectionLibraries()
{
	static NSArray *injectionLibraries = nil;

	if (!injectionLibraries) {
		NSMutableArray *injectionLibrariesM = [NSMutableArray new];

		for (uint32_t i = 0; i < _dyld_image_count(); i++) {
			const char *pathC = _dyld_get_image_name(i);
			NSString *path = [NSString stringWithUTF8String:pathC];

			if ([path hasSuffix:@"/usr/lib/substitute-inserter.dylib"]) {
				[injectionLibrariesM addObject:path];
			}
			else if ([path hasSuffix:@"/usr/lib/substitute-loader.dylib"]) {
				[injectionLibrariesM addObject:path];
			}
			else if ([path hasSuffix:@"/usr/lib/TweakInject.dylib"]) {
				[injectionLibrariesM addObject:path];
			}
			else if ([path hasSuffix:@"/usr/lib/substrate/SubstrateInserter.dylib"]) {
				[injectionLibrariesM addObject:path];
			} else if ([path hasSuffix:@"/usr/lib/substrate/SubstrateLoader.dylib"]) {
				[injectionLibrariesM addObject:path];
			}
		}

		injectionLibraries = injectionLibrariesM.copy;
	}

	return injectionLibraries;
}

NSString *getInjectionPlatform()
{
	static NSString *injectionPlatform = nil;

	if (!injectionPlatform) {
		for (uint32_t i = 0; i < _dyld_image_count(); i++) {
			const char *pathC = _dyld_get_image_name(i);
			NSString *path = [NSString stringWithUTF8String:pathC];

			if ([path hasSuffix:@"/usr/lib/substitute-inserter.dylib"]) {
				injectionPlatform = @"Substitute";
			}
			else if ([path hasSuffix:@"/usr/lib/TweakInject.dylib"]) {
				injectionPlatform = @"libhooker";
			}
			else if ([path hasSuffix:@"/usr/lib/substrate/SubstrateInserter.dylib"]) {
				injectionPlatform = @"Substrate";
			}
		}

		if (!injectionPlatform) {
			injectionPlatform = localize(@"THE_INJECTION_PLATFORM");
		}
	}

	return injectionPlatform;
}

@interface PSListController (ChoicyNavigation)
- (id)controllerForSpecifier:(PSSpecifier *)specifier;
@end

@interface CHPRootListController ()
@property (nonatomic) BOOL choicyOpenScheduled;
@property (nonatomic) BOOL updateCheckInProgress;
@property (nonatomic) BOOL showUpdateResult;
- (void)choicy_schedulePendingApplicationSettings;
- (void)choicy_openPendingApplicationSettings;
@end

static NSString *const ChoySeeUpdatesSpecifierID = @"CheckUpdates";

static void choicyOpenRequestReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CHPRootListController *controller = (__bridge CHPRootListController *)observer;
	dispatch_async(dispatch_get_main_queue(), ^{ [controller choicy_schedulePendingApplicationSettings]; });
}

@implementation CHPRootListController

- (NSMutableArray *)specifiers
{
	BOOL needsDefaults = !_specifiers;
	NSMutableArray *specifiers = [super specifiers];
	if (needsDefaults) {
		for (PSSpecifier *specifier in specifiers) {
			NSString *key = [specifier propertyForKey:@"key"];
			if ([key isEqualToString:kChoicyPrefsKeyTagCustomAppsEnabled] || [key isEqualToString:kChoicyPrefsKeyOpenInChoicyOptionEnabled]) {
				[specifier setProperty:@(choicyAppOptionsDefaultEnabled()) forKey:@"default"];
			}
			if ([specifier.identifier isEqualToString:ChoySeeUpdatesSpecifierID]) {
				[specifier setProperty:@(!self.updateCheckInProgress) forKey:@"enabled"];
			}
		}
	}
	return specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier
{
	NSString *key = [specifier propertyForKey:@"key"];
	if ([key isEqualToString:kChoicyPrefsKeyTagCustomAppsEnabled] || [key isEqualToString:kChoicyPrefsKeyOpenInChoicyOptionEnabled]) {
		NSDictionary *snapshot = [NSDictionary dictionaryWithContentsOfFile:kChoicyPrefsPlistPath];
		return @(parseNumberBool(snapshot[key], choicyAppOptionsDefaultEnabled()));
	}
	return [super readPreferenceValue:specifier];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self, kChoicyOpenRequestNotification, NULL);
}

- (void)choicy_applicationDidBecomeActive:(NSNotification *)notification
{
	[self choicy_schedulePendingApplicationSettings];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self choicy_schedulePendingApplicationSettings];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.showUpdateResult = NO;
}

- (void)choicy_schedulePendingApplicationSettings
{
	if (self.choicyOpenScheduled) return;
	self.choicyOpenScheduled = YES;
	dispatch_async(dispatch_get_main_queue(), ^{
		self.choicyOpenScheduled = NO;
		[self choicy_openPendingApplicationSettings];
	});
}

- (void)choicy_openPendingApplicationSettings
{
	UINavigationController *navigation = self.navigationController;
	NSArray<UIViewController *> *currentControllers = navigation.viewControllers;
	NSUInteger rootIndex = [currentControllers indexOfObjectIdenticalTo:self];
	if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive
		|| rootIndex == NSNotFound || !navigation.viewIfLoaded.window) return;
	NSDictionary *request = choicyPendingApplicationSettingsRequest(YES);
	if (!request) return;

	NSString *requestID = request[@"requestID"];
	NSString *applicationID = request[@"applicationIdentifier"];
	LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:applicationID];
	BOOL installed = proxy.bundleURL.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:proxy.bundleURL.path];
	if (!installed) {
		choicyCancelApplicationSettingsRequest(requestID);
		return;
	}

	__weak typeof(self) weakSelf = self;
	id<UIViewControllerTransitionCoordinator> transition = navigation.transitionCoordinator ?: navigation.topViewController.transitionCoordinator;
	if ([transition animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[weakSelf choicy_schedulePendingApplicationSettings];
	}]) {
		return;
	}

	UIViewController *presenter = navigation.presentedViewController ? navigation : navigation.topViewController;
	if (presenter.presentedViewController) {
		[presenter dismissViewControllerAnimated:NO completion:^{ [weakSelf choicy_schedulePendingApplicationSettings]; }];
		return;
	}
	if (@available(iOS 11.0, *)) {
		navigation.topViewController.navigationItem.searchController.active = NO;
	}

	// Use a fresh Applications list so a previous search cannot filter out the target.
	PSSpecifier *applicationsSpecifier = [self specifierForID:kChoicyApplicationsSpecifierID];
	CHPApplicationListSubcontrollerController *applications = applicationsSpecifier ? [self controllerForSpecifier:applicationsSpecifier] : nil;
	if (![applications isKindOfClass:[CHPApplicationListSubcontrollerController class]]) {
		choicyCancelApplicationSettingsRequest(requestID);
		NSLog(@"ChoySee could not open its Applications list");
		return;
	}
	PSSpecifier *appSpecifier = nil;
	for (PSSpecifier *specifier in applications.specifiers) {
		if ([applicationID isEqual:[specifier propertyForKey:@"applicationIdentifier"]]) {
			appSpecifier = specifier;
			break;
		}
	}
	if (!appSpecifier) {
		appSpecifier = [PSSpecifier preferenceSpecifierNamed:(proxy.localizedName ?: applicationID)
			target:applications set:nil get:nil
			detail:[CHPProcessConfigurationListController class] cell:PSLinkListCell edit:nil];
		appSpecifier.identifier = applicationID;
		[appSpecifier setProperty:applicationID forKey:@"applicationIdentifier"];
		[appSpecifier setProperty:@YES forKey:@"enabled"];
	}
	CHPProcessConfigurationListController *detail = [applications controllerForSpecifier:appSpecifier];
	if (![detail isKindOfClass:[CHPProcessConfigurationListController class]]
		|| ![applicationID isEqual:[detail.specifier propertyForKey:@"applicationIdentifier"]]) {
		choicyCancelApplicationSettingsRequest(requestID);
		NSLog(@"ChoySee could not open its settings for %@", applicationID);
		return;
	}

	NSMutableArray *controllers = [[currentControllers subarrayWithRange:NSMakeRange(0, rootIndex + 1)] mutableCopy];
	[controllers addObject:applications];
	[controllers addObject:detail];
	if (!choicyConsumeApplicationSettingsRequest(requestID)) {
		NSDictionary *latest = choicyPendingApplicationSettingsRequest(YES);
		if (latest && ![requestID isEqual:latest[@"requestID"]]) {
			[self choicy_schedulePendingApplicationSettings];
		}
		return;
	}
	[navigation setViewControllers:controllers animated:NO];
}

- (NSString *)title
{
	return @"ChoySee";
}

- (NSString *)plistName
{
	return @"Root";
}

- (void)openTwitterWithUsername:(NSString *)username
{
	UIApplication *app = [UIApplication sharedApplication];

	if ([app canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
		[app openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", username]]];
	}
	else {
		[app openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@", username]]];
	}
}

- (void)setUpdateCheckInProgress:(BOOL)inProgress
{
	_updateCheckInProgress = inProgress;
	PSSpecifier *row = [self specifierForID:ChoySeeUpdatesSpecifierID];
	[row setProperty:@(!inProgress) forKey:@"enabled"];
	if (row && self.isViewLoaded) [self reloadSpecifier:row];
}

- (void)presentUpdateResultForVersion:(NSString *)installedVersion tag:(NSString *)tag
	newerReleaseURL:(NSURL *)url failure:(NSString *)failure
{
	NSString *title;
	NSString *message;
	if (failure) {
		title = localize(@"UPDATE_CHECK_FAILED");
		message = failure;
	} else {
		title = localize(url ? @"UPDATE_AVAILABLE" : @"UPDATE_UP_TO_DATE");
		message = [NSString stringWithFormat:localize(@"UPDATE_VERSIONS"), installedVersion, tag];
	}
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
		message:message preferredStyle:UIAlertControllerStyleAlert];
	if (url) {
		[alert addAction:[UIAlertAction actionWithTitle:localize(@"UPDATE_VIEW_RELEASE") style:UIAlertActionStyleDefault
			handler:^(UIAlertAction *action) {
				[UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
			}]];
	}
	[alert addAction:[UIAlertAction actionWithTitle:localize(url ? @"CANCEL" : @"OK")
		style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)checkForUpdates
{
	if (self.updateCheckInProgress || !ChoySeeCanPresent(self)) return;
	self.updateCheckInProgress = YES;
	self.showUpdateResult = YES;

	NSString *version = [[NSBundle bundleForClass:CHPRootListController.class]
		objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	__weak CHPRootListController *weakSelf = self;
	[ChoySeeUpdateChecker checkInstalledVersion:version completion:^(NSString *tag, NSURL *url, NSString *failure) {
		CHPRootListController *controller = weakSelf;
		controller.updateCheckInProgress = NO;
		if (controller.showUpdateResult && ChoySeeCanPresent(controller)) {
			[controller presentUpdateResultForVersion:version tag:tag newerReleaseURL:url failure:failure];
		}
		controller.showUpdateResult = NO;
	}];
}

- (void)openGitHub
{
	[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://github.com/EolnMsuk/ChoySee/"]
		options:@{} completionHandler:nil];
}

- (void)openReddit
{
	[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.reddit.com/user/EolnMsuk4334/"]
		options:@{} completionHandler:nil];
}

- (void)presentDonationMenu
{
	PSSpecifier *row = [self specifierForID:@"Donate"];
	NSIndexPath *path = row ? [self indexPathForSpecifier:row] : nil;
	UIView *anchor = path ? [self.table cellForRowAtIndexPath:path] : nil;
	ChoySeePresentDonationMenu(self, anchor);
}

- (void)resetPreferences
{
	UIAlertController *resetPreferencesAlert = [UIAlertController alertControllerWithTitle:localize(@"RESET_PREFERENCES") message:localize(@"RESET_PREFERENCES_MESSAGE") preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *continueAction = [UIAlertAction actionWithTitle:localize(@"CONTINUE") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
		NSError *error = nil;
		if (![[NSFileManager defaultManager] removeItemAtPath:kChoicyPrefsPlistPath error:&error]
			&& !([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileNoSuchFileError)) {
			NSLog(@"ChoySee could not reset preferences: %@", error);
			return;
		}
		choicy_reloadPreferences();
		[self reloadSpecifiers];
		[[self class] sendChoicyPrefsPostNotification];
	}];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:localize(@"CANCEL") style:UIAlertActionStyleDefault handler:nil];
	
	[resetPreferencesAlert addAction:continueAction];
	[resetPreferencesAlert addAction:cancelAction];

	[self presentViewController:resetPreferencesAlert animated:YES completion:nil];
}

void presentNotLoadingFirstWarning(PSListController *plc, BOOL showDontShowAgainOption)
{
	PSSpecifier *dontShowAgainSpecifier = [PSSpecifier preferenceSpecifierNamed:@"dontShowWarningAgain"
					target:plc
					set:nil
					get:nil
					detail:nil
					cell:0
					edit:nil];

	[dontShowAgainSpecifier setProperty:@"com.opa334.choicyprefs" forKey:@"defaults"];
	[dontShowAgainSpecifier setProperty:@"dontShowWarningAgain" forKey:@"key"];
	[dontShowAgainSpecifier setProperty:@"com.opa334.choicyprefs/ReloadPrefs" forKey:@"PostNotification"];

	NSNumber *dontShowAgainNum = nil;
	if (showDontShowAgainOption) {
		dontShowAgainNum = [plc readPreferenceValue:dontShowAgainSpecifier];
	}

	if (![dontShowAgainNum boolValue]) {
		NSString *injectionPlatform = getInjectionPlatform();

		NSString *message = [NSString stringWithFormat:localize(@"TWEAKS_LOADING_BEFORE_CHOICY_ALERT_MESSAGE"), injectionPlatform];

		if ([injectionPlatform isEqualToString:@"Substrate"]) {
			message = [message stringByAppendingString:[@" " stringByAppendingString:localize(@"CHOICYLOADER_ADVICE")]];
		}

		UIAlertController *warningAlert = [UIAlertController alertControllerWithTitle:localize(@"WARNING_ALERT_TITLE") message:message preferredStyle:UIAlertControllerStyleAlert];
	
		if ([injectionPlatform isEqualToString:@"Substrate"]) {
			UIAlertAction *openRepoAction = [UIAlertAction actionWithTitle:localize(@"OPEN_REPO") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://opa334.github.io"]];
			}];

			[warningAlert addAction:openRepoAction];
		}

		if (showDontShowAgainOption) {
			UIAlertAction *dontShowAgainAction = [UIAlertAction actionWithTitle:localize(@"DONT_SHOW_AGAIN") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
				[plc setPreferenceValue:@1 specifier:dontShowAgainSpecifier];
			}];

			[warningAlert addAction:dontShowAgainAction];
		}

		UIAlertAction *closeAction = [UIAlertAction actionWithTitle:localize(@"CLOSE") style:UIAlertActionStyleDefault handler:nil];

		[warningAlert addAction:closeAction];

		if ([warningAlert respondsToSelector:@selector(setPreferredAction:)]) {
			warningAlert.preferredAction = closeAction;
		}

		[plc presentViewController:warningAlert animated:YES completion:nil];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(choicy_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self, choicyOpenRequestReceived, kChoicyOpenRequestNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	if (dylibsBeforeChoicy && !choicyPendingApplicationSettingsRequest(NO)) {
		presentNotLoadingFirstWarning(self, YES);
	}
}

@end

void determineLoadingOrder()
{
	NSMutableArray *dylibsInOrder = [NSMutableArray new];
	NSString *injectionLibrariesPath = [CHPTweakList injectionLibrariesPath];

	BOOL isSubstrate = [getInjectionPlatform() isEqualToString:@"Substrate"];
	if (isSubstrate) {
		//SubstrateLoader doesn't sort anything and instead process the raw output of readdir
		DIR *dir;
		struct dirent *dp;
		dir = opendir(injectionLibrariesPath.UTF8String);
		dp=readdir(dir); //.
		dp=readdir(dir); //..
		while ((dp = readdir(dir)) != NULL) {
			NSString *filename = [NSString stringWithCString:dp->d_name encoding:NSUTF8StringEncoding];

			if ([filename.pathExtension isEqualToString:@"dylib"]) {
				[dylibsInOrder addObject:[filename stringByDeletingPathExtension]];
			}
		}
	}
	else {
		//Anything but substrate sorts the dylibs alphabetically
		NSMutableArray *contents = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:injectionLibrariesPath error:nil] mutableCopy];
		NSArray *plists = [contents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH %@", @"plist"]];
		for (NSString *plist in plists) {
			NSString *dylibName = [plist stringByDeletingPathExtension];
			[dylibsInOrder addObject:dylibName];
		}
		[dylibsInOrder sortUsingSelector:@selector(caseInsensitiveCompare:)];
	}

	NSUInteger choicyIndex = [dylibsInOrder indexOfObject:kChoicyDylibName];

	if (choicyIndex == NSNotFound) return;

	if (choicyIndex != 0) {
		dylibsBeforeChoicy = [dylibsInOrder subarrayWithRange:NSMakeRange(0,choicyIndex)];
	}

	if (dylibsBeforeChoicy && isSubstrate) {
		NSDictionary *targetLoaderAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:JBROOT_PATH_NSSTRING(@"/usr/lib/substrate/SubstrateLoader.dylib") error:nil];

		if ([[targetLoaderAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink]) {
			NSString *destination = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:JBROOT_PATH_NSSTRING(@"/usr/lib/substrate/SubstrateLoader.dylib") error:nil];
			if ([destination hasPrefix:@"/usr/lib/ChoicyLoader.dylib"]) {
				// If ChoicyLoader is installed on Substrate, Choicy always loads first
				dylibsBeforeChoicy = nil;
			}
		}
	}
}

__attribute__((constructor))
static void init(void)
{
	choicy_reloadPreferences();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, choicyPreferencesChanged, CFSTR("com.opa334.choicyprefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	determineLoadingOrder();
}
