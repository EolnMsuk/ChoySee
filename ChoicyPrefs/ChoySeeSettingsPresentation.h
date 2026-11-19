#import <UIKit/UIKit.h>

static inline BOOL ChoySeeCanPresent(UIViewController *controller)
{
	UIWindow *window = controller.viewIfLoaded.window;
	UINavigationController *navigation = controller.navigationController;
	if (!window || window.hidden || controller.presentedViewController
		|| controller.isBeingDismissed || controller.isMovingFromParentViewController
		|| UIApplication.sharedApplication.applicationState != UIApplicationStateActive) return NO;
	if (navigation && (navigation.topViewController != controller
		|| navigation.presentedViewController || navigation.isBeingDismissed)) return NO;
	if (@available(iOS 13.0, *)) {
		UIWindowScene *scene = window.windowScene;
		if (scene && scene.activationState != UISceneActivationStateForegroundActive) return NO;
	}
	return YES;
}
