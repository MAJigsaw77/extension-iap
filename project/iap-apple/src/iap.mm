#include "iap.hpp"

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol BillingUpdatesListener <NSObject>
- (void)onBillingClientSetup:(BOOL)success;
- (void)onBillingClientDebugLog:(NSString *)message;
- (void)onQueryProductDetails:(NSArray<SKProduct *> *)productDetails;
- (void)onPurchaseCompleted:(SKPaymentTransaction *)transaction;
- (void)onRestoreCompleted:(NSArray<SKPaymentTransaction *> *)transactions;
@end

@interface BillingManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, weak) id<BillingUpdatesListener> billingUpdatesListener;
@property (nonatomic, strong) NSMutableArray<SKProduct *> *availableProducts;
- (instancetype)initWithUpdatesListener:(id<BillingUpdatesListener>)listener;
- (void)startConnection;
- (void)queryProductDetails:(NSArray<NSString *> *)productIdentifiers;
- (void)initiatePurchaseFlow:(NSString *)productIdentifier;
- (void)restorePurchases;
- (BOOL)canMakePayments;
- (void)destroy;
@end

@implementation BillingManager

- (instancetype)initWithUpdatesListener:(id<BillingUpdatesListener>)listener
{
	self = [super init];

	if (self)
	{
		self.billingUpdatesListener = listener;
		self.availableProducts = [NSMutableArray array];
	}

	return self;
}

- (void)startConnection
{
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	[self.billingUpdatesListener onBillingClientSetup:YES];
	[self.billingUpdatesListener onBillingClientDebugLog:@"Billing connection started."];
}

- (void)queryProductDetails:(NSArray<NSString *> *)productIdentifiers
{
	if (!productIdentifiers || productIdentifiers.count == 0)
	{
		[self.billingUpdatesListener onBillingClientDebugLog:@"No product identifiers provided."];
		return;
	}

	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
	productsRequest.delegate = self;
	[productsRequest start];
}

- (void)initiatePurchaseFlow:(NSString *)productIdentifier
{
	SKProduct *product = [self findProductByIdentifier:productIdentifier];

	if (!product)
	{
		[self.billingUpdatesListener onBillingClientDebugLog:[NSString stringWithFormat:@"Product not found: %@", productIdentifier]];
		return;
	}

	[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
}

- (void)restorePurchases
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (BOOL)canMakePayments
{
	return [SKPaymentQueue canMakePayments];
}

- (void)destroy
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];

	[self.billingUpdatesListener onBillingClientDebugLog:@"Billing connection destroyed."];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if (response.products.count > 0)
	{
		[self.availableProducts removeAllObjects];
		[self.availableProducts addObjectsFromArray:response.products];
		[self.billingUpdatesListener onQueryProductDetails:response.products];
	}
	else
		[self.billingUpdatesListener onBillingClientDebugLog:@"No products found."];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	[self.billingUpdatesListener onBillingClientDebugLog:[NSString stringWithFormat:@"Failed to fetch products: %@", error.localizedDescription]];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				[self.billingUpdatesListener onPurchaseCompleted:transaction];

				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

				break;
			case SKPaymentTransactionStateRestored:
				[self.billingUpdatesListener onRestoreCompleted:queue.transactions];

				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

				break;
			case SKPaymentTransactionStateFailed:
				[self.billingUpdatesListener onBillingClientDebugLog:[NSString stringWithFormat:@"Purchase failed: %@", transaction.error.localizedDescription]];

				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

				break;
			default:
				break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	[self.billingUpdatesListener onRestoreCompleted:queue.transactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	[self.billingUpdatesListener onBillingClientDebugLog:[NSString stringWithFormat:@"Failed to restore purchases: %@", error.localizedDescription]];
}

- (SKProduct *)findProductByIdentifier:(NSString *)identifier
{
	for (SKProduct *product in self.availableProducts)
	{
		if ([product.productIdentifier isEqualToString:identifier])
			return product;
	}

	return nil;
}

@end

@interface IAP : NSObject <BillingUpdatesListener>
@property (nonatomic, strong) BillingManager *billingManager;
@property (nonatomic, assign) IAPCallbacks callbacks;
@end

@implementation IAP

+ (instancetype)sharedInstance
{
	static IAP *sharedInstance = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedInstance = [[IAP alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	if (self)
		_billingManager = [[BillingManager alloc] initWithUpdatesListener:self];

	return self;
}

- (void)setCallbacks:(IAPCallbacks)callbacks
{
	_callbacks = callbacks;
}

- (void)onBillingClientSetup:(BOOL)success
{
	if (self.callbacks.onBillingClientSetup)
		self.callbacks.onBillingClientSetup(success);
}

- (void)onBillingClientDebugLog:(NSString *)message
{
	if (self.callbacks.onBillingClientDebugLog)
		self.callbacks.onBillingClientDebugLog([message UTF8String]);
}

- (void)onQueryProductDetails:(NSArray<SKProduct *> *)productDetails
{
	if (self.callbacks.onQueryProductDetails)
	{
		NSMutableArray *productsArray = [NSMutableArray array];

		for (SKProduct *product in productDetails)
		{
			[productsArray addObject:@{
				@"productIdentifier": product.productIdentifier ?:@"",
				@"localizedTitle": product.localizedTitle ?:@"",
				@"localizedDescription": product.localizedDescription ?:@"",
				@"price": product.price.stringValue ?:@"0.00",
				@"priceLocale": product.priceLocale.localeIdentifier ?:@""
			}];
		}

		NSError *error = nil;

		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:productsArray options:0 error:&error];

		if (!error)
			self.callbacks.onQueryProductDetails([[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String]);
	}
}

- (void)onPurchaseCompleted:(SKPaymentTransaction *)transaction
{
	if (self.callbacks.onPurchaseCompleted)
	{
		NSDictionary *transactionJSON =@{
			@"transactionIdentifier": transaction.transactionIdentifier ?:@"",
			@"productIdentifier": transaction.payment.productIdentifier ?:@"",
			@"transactionDate": transaction.transactionDate ?@([transaction.transactionDate timeIntervalSince1970]) :@(0),
			@"transactionState":@(transaction.transactionState)
		};

		NSError *error = nil;

		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:transactionJSON options:0 error:&error];

		if (!error)
			self.callbacks.onPurchaseCompleted([[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String]);
	}
}

- (void)onRestoreCompleted:(NSArray<SKPaymentTransaction *> *)transactions
{
	if (self.callbacks.onRestoreCompleted)
	{
		NSMutableArray *transactionsArray = [NSMutableArray array];

		for (SKPaymentTransaction *transaction in transactions)
		{
			[transactionsArray addObject:@{
				@"transactionIdentifier": transaction.transactionIdentifier ?:@"",
				@"productIdentifier": transaction.payment.productIdentifier ?:@"",
				@"transactionDate": transaction.transactionDate ?@([transaction.transactionDate timeIntervalSince1970]) :@(0),
				@"transactionState":@(transaction.transactionState)
			}];
		}

		NSError *error = nil;

		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:transactionsArray options:0 error:&error];

		if (!error)
			self.callbacks.onRestoreCompleted([[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String]);
	}
}
@end

void initIAP(IAPCallbacks callbacks)
{
	[[IAP sharedInstance] setCallbacks:callbacks];

	[[[IAP sharedInstance] billingManager] startConnection];
}

void queryProductDetailsIAP(const char** productIdentifiers, size_t count)
{
	NSMutableArray<NSString *> *objcProductIdentifiers = [NSMutableArray array];

	for (size_t i = 0; i < count; ++i)
		[objcProductIdentifiers addObject:[NSString stringWithUTF8String:productIdentifiers[i]]];

	[[[IAP sharedInstance] billingManager] queryProductDetails:objcProductIdentifiers];
}

void purchaseProductIAP(const char* productId)
{
	[[[IAP sharedInstance] billingManager] initiatePurchaseFlow:[NSString stringWithUTF8String:productId]];
}

void restorePurchasesIAP()
{
	[[[IAP sharedInstance] billingManager] restorePurchases];
}

bool canMakePurchasesIAP()
{
	[[[IAP sharedInstance] billingManager] canMakePayments];
}
