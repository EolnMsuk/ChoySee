#import "ChoySeeUpdateChecker.h"
#import "../Shared.h"

static NSString *const ChoySeeLatestReleaseEndpoint = @"https://api.github.com/repos/EolnMsuk/ChoySee/releases/latest";
static NSUInteger const ChoySeeReleaseResponseLimit = 64 * 1024;

static NSArray<NSString *> *ChoySeeVersionParts(NSString *version)
{
	if (![version isKindOfClass:NSString.class] || version.length > 128) return nil;
	static NSRegularExpression *pattern;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		pattern = [NSRegularExpression regularExpressionWithPattern:
			@"\\Av?(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(?:-b[0-9]+)?\\z"
			options:0 error:NULL];
	});
	NSTextCheckingResult *match = [pattern firstMatchInString:version options:0 range:NSMakeRange(0, version.length)];
	if (!match) return nil;
	return @[[version substringWithRange:[match rangeAtIndex:1]],
		[version substringWithRange:[match rangeAtIndex:2]],
		[version substringWithRange:[match rangeAtIndex:3]]];
}

static BOOL ChoySeeVersionIsNewer(NSArray<NSString *> *remote, NSArray<NSString *> *installed)
{
	// Each part has no leading zeroes, so decimal comparison needs no integer conversion.
	for (NSUInteger index = 0; index < remote.count; index++) {
		NSString *remotePart = remote[index];
		NSString *installedPart = installed[index];
		if (remotePart.length != installedPart.length) return remotePart.length > installedPart.length;
		NSComparisonResult order = [remotePart compare:installedPart options:NSLiteralSearch];
		if (order != NSOrderedSame) return order == NSOrderedDescending;
	}
	return NO;
}

static BOOL ChoySeeIsJSONFalse(id value)
{
	return [value isKindOfClass:NSNumber.class]
		&& CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()
		&& ![value boolValue];
}

@interface ChoySeeUpdateChecker () <NSURLSessionDataDelegate>
@end

@implementation ChoySeeUpdateChecker {
	NSURLSession *_session;
	NSURLSessionDataTask *_task;
	NSMutableData *_responseData;
	NSArray<NSString *> *_installedParts;
	NSMutableArray<ChoySeeUpdateCompletion> *_completions;
	NSString *_failureMessage;
}

+ (void)checkInstalledVersion:(NSString *)version completion:(ChoySeeUpdateCompletion)completion
{
	NSAssert(NSThread.isMainThread, @"Updates must be requested from Settings on the main thread");
	static ChoySeeUpdateChecker *checker;
	static dispatch_once_t once;
	dispatch_once(&once, ^{ checker = [ChoySeeUpdateChecker new]; });
	[checker startCheckForVersion:version completion:completion];
}

- (void)startCheckForVersion:(NSString *)version completion:(ChoySeeUpdateCompletion)completion
{
	if (_task) {
		[_completions addObject:[completion copy]];
		return;
	}
	_installedParts = ChoySeeVersionParts(version);
	if (!_installedParts) {
		completion(nil, nil, localize(@"UPDATE_INVALID_INSTALLED_VERSION"));
		return;
	}

	NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
	configuration.timeoutIntervalForRequest = 15;
	configuration.timeoutIntervalForResource = 20;
	configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	configuration.URLCache = nil;
	configuration.HTTPCookieStorage = nil;
	configuration.HTTPShouldSetCookies = NO;
	configuration.URLCredentialStorage = nil;
	// The transfer is asynchronous. Main-queue delegates serialize the bounded response and the row state.
	_session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:NSOperationQueue.mainQueue];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ChoySeeLatestReleaseEndpoint]];
	[request setValue:@"application/vnd.github+json" forHTTPHeaderField:@"Accept"];
	[request setValue:[@"ChoySee-Preferences/" stringByAppendingString:version] forHTTPHeaderField:@"User-Agent"];
	_responseData = [NSMutableData data];
	_completions = [NSMutableArray arrayWithObject:[completion copy]];
	_task = [_session dataTaskWithRequest:request];
	[_task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
	willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request
	completionHandler:(void (^)(NSURLRequest *))completionHandler
{
	if (task == _task) _failureMessage = localize(@"UPDATE_REDIRECT_REFUSED");
	completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
	didReceiveResponse:(NSURLResponse *)response
	completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
	if (task != _task || _failureMessage) {
		completionHandler(NSURLSessionResponseCancel);
		return;
	}
	NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
	if (![http isKindOfClass:NSHTTPURLResponse.class]
		|| ![http.URL.absoluteString isEqualToString:ChoySeeLatestReleaseEndpoint]) {
		_failureMessage = localize(@"UPDATE_INVALID_RESPONSE");
	} else if (http.statusCode == 404) {
		_failureMessage = localize(@"UPDATE_NO_STABLE_RELEASE");
	} else if (http.statusCode != 200) {
		_failureMessage = [NSString stringWithFormat:localize(@"UPDATE_HTTP_FAILURE"), (long)http.statusCode];
	} else if (http.expectedContentLength > (int64_t)ChoySeeReleaseResponseLimit) {
		_failureMessage = localize(@"UPDATE_RESPONSE_TOO_LARGE");
	}
	completionHandler(_failureMessage ? NSURLSessionResponseCancel : NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data
{
	if (task != _task || _failureMessage) return;
	if (data.length > ChoySeeReleaseResponseLimit - _responseData.length) {
		_failureMessage = localize(@"UPDATE_RESPONSE_TOO_LARGE");
		[task cancel];
		return;
	}
	[_responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	if (task != _task) return;

	NSString *tag = nil;
	NSURL *newerReleaseURL = nil;
	NSString *failure = _failureMessage;
	if (!failure && error) {
		failure = [NSString stringWithFormat:localize(@"UPDATE_NETWORK_FAILURE"), error.localizedDescription];
	}
	if (!failure) {
		id parsed = [NSJSONSerialization JSONObjectWithData:_responseData options:0 error:NULL];
		NSDictionary *release = [parsed isKindOfClass:NSDictionary.class] ? parsed : nil;
		NSString *candidateTag = release[@"tag_name"];
		NSArray<NSString *> *remoteParts = ChoySeeVersionParts(candidateTag);
		NSString *expectedURL = remoteParts
			? [@"https://github.com/EolnMsuk/ChoySee/releases/tag/" stringByAppendingString:candidateTag] : nil;
		id link = release[@"html_url"];
		if (!remoteParts || !ChoySeeIsJSONFalse(release[@"draft"]) || !ChoySeeIsJSONFalse(release[@"prerelease"])
			|| ![link isKindOfClass:NSString.class] || ![link isEqualToString:expectedURL]) {
			failure = localize(@"UPDATE_INVALID_RESPONSE");
		} else {
			tag = candidateTag;
			if (ChoySeeVersionIsNewer(remoteParts, _installedParts)) {
				newerReleaseURL = [NSURL URLWithString:expectedURL];
			}
		}
	}
	NSArray<ChoySeeUpdateCompletion> *completions = _completions;
	[session finishTasksAndInvalidate];
	_session = nil;
	_task = nil;
	_completions = nil;
	_responseData = nil;
	_installedParts = nil;
	_failureMessage = nil;
	for (ChoySeeUpdateCompletion completion in completions) {
		completion(tag, newerReleaseURL, failure);
	}
}
@end
