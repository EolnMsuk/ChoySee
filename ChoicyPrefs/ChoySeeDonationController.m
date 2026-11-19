#import "ChoySeeDonationController.h"
#import "ChoySeeSettingsPresentation.h"
#import "../Shared.h"

static NSString *const ChoySeeVenmoURL = @"https://venmo.com/EolnMsuk/";

@protocol ChoySeeBrowserConfiguration <NSObject>
@property (nonatomic) BOOL allowURLOverrides;
@end

@protocol ChoySeeBrowserWorkspace <NSObject>
+ (id<ChoySeeBrowserWorkspace>)defaultWorkspace;
- (void)openURL:(NSURL *)URL configuration:(id)configuration
	completionHandler:(void (^)(NSDictionary *, NSError *))completion;
@end

static void ChoySeeShowBrowserError(UIViewController *controller, NSString *messageKey)
{
	if (!ChoySeeCanPresent(controller)) return;
	NSString *message = [NSString stringWithFormat:localize(messageKey), ChoySeeVenmoURL];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:localize(@"BROWSER_OPEN_FAILED")
		message:message preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:localize(@"OK") style:UIAlertActionStyleCancel handler:nil]];
	[controller presentViewController:alert animated:YES completion:nil];
}

static void ChoySeeOpenVenmo(UIViewController *controller)
{
	if (!ChoySeeCanPresent(controller)) return;

	Class<ChoySeeBrowserWorkspace> workspaceClass = (Class<ChoySeeBrowserWorkspace>)NSClassFromString(@"LSApplicationWorkspace");
	id<ChoySeeBrowserWorkspace> workspace = nil;
	if ([workspaceClass respondsToSelector:@selector(defaultWorkspace)]) {
		workspace = [workspaceClass defaultWorkspace];
	}
	id<ChoySeeBrowserConfiguration> configuration = [NSClassFromString(@"_LSOpenConfiguration") new];
	if (![configuration respondsToSelector:@selector(setAllowURLOverrides:)]
		|| ![workspace respondsToSelector:@selector(openURL:configuration:completionHandler:)]) {
		ChoySeeShowBrowserError(controller, @"VENMO_BROWSER_UNAVAILABLE");
		return;
	}

	// Use the selected browser even when Venmo is installed as a universal-link handler.
	configuration.allowURLOverrides = NO;
	__weak UIViewController *weakController = controller;
	[workspace openURL:[NSURL URLWithString:ChoySeeVenmoURL] configuration:configuration
		completionHandler:^(NSDictionary *result, NSError *error) {
			if (!error) return;
			dispatch_async(dispatch_get_main_queue(), ^{
				ChoySeeShowBrowserError(weakController, @"VENMO_BROWSER_FAILED");
			});
		}];
}

static NSArray<NSDictionary<NSString *, NSString *> *> *ChoySeeWallets(void)
{
	static NSArray *wallets;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		wallets = @[
			@{@"coin": @"BTC", @"network": @"Bitcoin Network", @"address": @"31uHLpioo1TbxAmo9kM7rrKcLz3wvcoZaL"},
			@{@"coin": @"ETH", @"network": @"Ethereum Network", @"address": @"0x6060BEA4305BC4259bcF1db5eDbe756b7b74a895"},
			@{@"coin": @"USDT", @"network": @"Ethereum Network", @"address": @"0x17f0c9d7229E9A1Ad1cAccbfEe7979CF39F2301F"},
			@{@"coin": @"USDC", @"network": @"Ethereum Network", @"address": @"0xD69Dc2a18e64E071d096435dD6f9DdD52B10785c"},
			@{@"coin": @"RNDR / ERC-20", @"network": @"Ethereum Network", @"address": @"0x9cc3fCc3b41a31cDC07E33930F1d622c3ed690E9"},
			@{@"coin": @"LTC", @"network": @"Litecoin Network", @"address": @"MNWMWwueZBoQSd7Ms9meQ1cMfeY16BA7E1"},
			@{@"coin": @"SOL", @"network": @"Solana Network", @"address": @"H2ydj95396KRErC4nMtK5B2BAjobPTyUh7LpYBFSmFnP"},
			@{@"coin": @"BNB", @"network": @"BNB Smart Chain Network", @"address": @"0x314148b89744663ad9F1Fb8EA6862a62abf2fC93"}
		];
	});
	return wallets;
}

@interface ChoySeeWalletCell : UITableViewCell
- (void)showWallet:(NSDictionary<NSString *, NSString *> *)wallet copied:(BOOL)copied;
- (void)showCoin:(NSString *)coin copied:(BOOL)copied;
@end

@implementation ChoySeeWalletCell {
	UILabel *_coinLabel;
	UILabel *_networkLabel;
	UILabel *_addressLabel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier
{
	self = [super initWithStyle:style reuseIdentifier:identifier];
	if (!self) return nil;

	UIColor *primary = UIColor.blackColor;
	UIColor *secondary = UIColor.darkGrayColor;
	if (@available(iOS 13.0, *)) {
		primary = UIColor.labelColor;
		secondary = UIColor.secondaryLabelColor;
	}
	_coinLabel = [UILabel new];
	_networkLabel = [UILabel new];
	_addressLabel = [UILabel new];
	_coinLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	_networkLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
	_addressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_coinLabel.textColor = primary;
	_networkLabel.textColor = secondary;
	_addressLabel.textColor = primary;
	_addressLabel.lineBreakMode = NSLineBreakByCharWrapping;

	NSArray<UILabel *> *labels = @[_coinLabel, _networkLabel, _addressLabel];
	for (UILabel *label in labels) {
		label.numberOfLines = 0;
		label.adjustsFontForContentSizeCategory = YES;
	}
	UIStackView *details = [[UIStackView alloc] initWithArrangedSubviews:labels];
	details.axis = UILayoutConstraintAxisVertical;
	details.spacing = 4;
	details.translatesAutoresizingMaskIntoConstraints = NO;
	[self.contentView addSubview:details];

	UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[details.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
		[details.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
		[details.topAnchor constraintEqualToAnchor:margins.topAnchor constant:4],
		[details.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor constant:-4]
	]];
	self.isAccessibilityElement = YES;
	self.accessibilityTraits = UIAccessibilityTraitButton;
	self.accessibilityHint = localize(@"WALLET_COPY_HINT");
	return self;
}

- (void)showWallet:(NSDictionary<NSString *, NSString *> *)wallet copied:(BOOL)copied
{
	NSString *coin = wallet[@"coin"];
	[self showCoin:coin copied:copied];
	_networkLabel.text = wallet[@"network"];
	_addressLabel.text = wallet[@"address"];
	self.accessibilityLabel = [@[coin, _networkLabel.text, _addressLabel.text] componentsJoinedByString:@", "];
}

- (void)showCoin:(NSString *)coin copied:(BOOL)copied
{
	NSString *status = copied ? localize(@"WALLET_COPIED") : nil;
	_coinLabel.text = status ? [NSString stringWithFormat:@"%@ · %@", coin, status] : coin;
	self.accessibilityValue = status;
}
@end

@interface ChoySeeDonationController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@implementation ChoySeeDonationController {
	UITableView *_walletTable;
	NSMutableDictionary<NSIndexPath *, NSObject *> *_copyTokens;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = localize(@"CRYPTO_WALLETS");
	self.view.backgroundColor = UIColor.whiteColor;
	if (@available(iOS 13.0, *)) self.view.backgroundColor = UIColor.systemBackgroundColor;
	_copyTokens = [NSMutableDictionary dictionary];

	_walletTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	_walletTable.backgroundColor = self.view.backgroundColor;
	_walletTable.translatesAutoresizingMaskIntoConstraints = NO;
	_walletTable.rowHeight = UITableViewAutomaticDimension;
	_walletTable.estimatedRowHeight = 120;
	[_walletTable registerClass:ChoySeeWalletCell.class forCellReuseIdentifier:@"Wallet"];
	_walletTable.dataSource = self;
	_walletTable.delegate = self;
	[self.view addSubview:_walletTable];

	UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
	[cancel setTitle:localize(@"CANCEL") forState:UIControlStateNormal];
	cancel.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
	cancel.titleLabel.adjustsFontForContentSizeCategory = YES;
	cancel.translatesAutoresizingMaskIntoConstraints = NO;
	[cancel addTarget:self action:@selector(closeWallets) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:cancel];

	NSLayoutXAxisAnchor *leading;
	NSLayoutXAxisAnchor *trailing;
	NSLayoutYAxisAnchor *top;
	NSLayoutYAxisAnchor *bottom;
	if (@available(iOS 11.0, *)) {
		UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
		leading = safeArea.leadingAnchor;
		trailing = safeArea.trailingAnchor;
		top = safeArea.topAnchor;
		bottom = safeArea.bottomAnchor;
		_walletTable.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
	} else {
		leading = self.view.leadingAnchor;
		trailing = self.view.trailingAnchor;
		top = self.topLayoutGuide.bottomAnchor;
		bottom = self.bottomLayoutGuide.topAnchor;
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
	[NSLayoutConstraint activateConstraints:@[
		[_walletTable.leadingAnchor constraintEqualToAnchor:leading],
		[_walletTable.trailingAnchor constraintEqualToAnchor:trailing],
		[_walletTable.topAnchor constraintEqualToAnchor:top],
		[_walletTable.bottomAnchor constraintEqualToAnchor:cancel.topAnchor],
		[cancel.leadingAnchor constraintEqualToAnchor:leading constant:16],
		[cancel.trailingAnchor constraintEqualToAnchor:trailing constant:-16],
		[cancel.bottomAnchor constraintEqualToAnchor:bottom constant:-8],
		[cancel.heightAnchor constraintGreaterThanOrEqualToConstant:44]
	]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return ChoySeeWallets().count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path
{
	ChoySeeWalletCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Wallet" forIndexPath:path];
	[cell showWallet:ChoySeeWallets()[path.row] copied:(_copyTokens[path] != nil)];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path
{
	[tableView deselectRowAtIndexPath:path animated:YES];
	NSDictionary<NSString *, NSString *> *wallet = ChoySeeWallets()[path.row];
	NSString *coin = wallet[@"coin"];
	UIPasteboard.generalPasteboard.string = wallet[@"address"];

	NSObject *token = [NSObject new];
	_copyTokens[path] = token;
	ChoySeeWalletCell *cell = (ChoySeeWalletCell *)[tableView cellForRowAtIndexPath:path];
	[cell showCoin:coin copied:YES];
	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
		[NSString stringWithFormat:localize(@"WALLET_COPY_ANNOUNCEMENT"), coin]);

	__weak ChoySeeDonationController *weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		ChoySeeDonationController *controller = weakSelf;
		if (!controller || controller->_copyTokens[path] != token) return;
		[controller->_copyTokens removeObjectForKey:path];
		ChoySeeWalletCell *visibleCell = (ChoySeeWalletCell *)[controller->_walletTable cellForRowAtIndexPath:path];
		[visibleCell showCoin:coin copied:NO];
	});
}

- (void)closeWallets
{
	[self dismissViewControllerAnimated:YES completion:nil];
}
@end

static void ChoySeeAfterDonationSheet(UIAlertController *sheet, dispatch_block_t nextAction)
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (sheet.isBeingDismissed && [sheet.transitionCoordinator animateAlongsideTransition:nil
			completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
				if (!context.isCancelled) nextAction();
			}]) return;
		if (sheet.presentingViewController) {
			[sheet dismissViewControllerAnimated:YES completion:nextAction];
		} else {
			nextAction();
		}
	});
}

void ChoySeePresentDonationMenu(UIViewController *controller, UIView *anchor)
{
	NSCAssert(NSThread.isMainThread, @"The donation menu must be presented on the main thread");
	if (!ChoySeeCanPresent(controller)) return;

	UIAlertController *sheet = [UIAlertController alertControllerWithTitle:localize(@"DONATE")
		message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	__weak UIViewController *weakController = controller;
	__weak UIAlertController *weakSheet = sheet;
	[sheet addAction:[UIAlertAction actionWithTitle:localize(@"VENMO") style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action) {
			ChoySeeAfterDonationSheet(weakSheet, ^{ ChoySeeOpenVenmo(weakController); });
		}]];
	[sheet addAction:[UIAlertAction actionWithTitle:localize(@"CRYPTO") style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *action) {
			ChoySeeAfterDonationSheet(weakSheet, ^{
				UIViewController *presenter = weakController;
				if (!ChoySeeCanPresent(presenter)) return;
				UINavigationController *wallets = [[UINavigationController alloc]
					initWithRootViewController:[ChoySeeDonationController new]];
				wallets.modalPresentationStyle = UIModalPresentationFormSheet;
				wallets.preferredContentSize = CGSizeMake(500, 640);
				[presenter presentViewController:wallets animated:YES completion:nil];
			});
		}]];
	[sheet addAction:[UIAlertAction actionWithTitle:localize(@"CANCEL") style:UIAlertActionStyleCancel handler:nil]];

	UIPopoverPresentationController *popover = sheet.popoverPresentationController;
	if (anchor.window == controller.view.window) {
		popover.sourceView = anchor;
		popover.sourceRect = anchor.bounds;
	} else {
		popover.sourceView = controller.view;
		popover.sourceRect = CGRectMake(CGRectGetMidX(controller.view.bounds), CGRectGetMidY(controller.view.bounds), 1, 1);
	}
	[controller presentViewController:sheet animated:YES completion:nil];
}
