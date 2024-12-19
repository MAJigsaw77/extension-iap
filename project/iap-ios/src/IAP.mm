#import "IAP.hpp"

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

	SKPayment *payment = [SKPayment paymentWithProduct:product];

	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
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
	{
		[self.billingUpdatesListener onBillingClientDebugLog:@"No products found."];
	}
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

@interface IAP() <BillingUpdatesListener>
@property (nonatomic, strong) BillingManager *billingManager;
@property (nonatomic, assign) BillingCallbacks callbacks;
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

- (void)setCallbacks:(BillingCallbacks)callbacks
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
		NSMutableArray<const char*> *productDetailsArray = [NSMutableArray arrayWithCapacity:productDetails.count];
  
		for (SKProduct *product in productDetails)
			[productDetailsArray addObject:[product.productIdentifier UTF8String]];

		self.callbacks.onQueryProductDetails(productDetailsArray.mutableBytes, productDetails.count);
	}
}

- (void)onPurchaseCompleted:(SKPaymentTransaction *)transaction
{
	if (self.callbacks.onPurchaseCompleted)
		self.callbacks.onPurchaseCompleted([transaction.payment.productIdentifier UTF8String]);
}

- (void)onRestoreCompleted:(NSArray<SKPaymentTransaction *> *)transactions
{
	if (self.callbacks.onRestoreCompleted)
	{
		NSMutableArray<const char*> *restoredProducts = [NSMutableArray arrayWithCapacity:transactions.count];

		for (SKPaymentTransaction *transaction in transactions)
			[restoredProducts addObject:[transaction.payment.productIdentifier UTF8String]];

		self.callbacks.onRestoreCompleted(restoredProducts.mutableBytes, transactions.count);
	}
}
@end

void initIAP(BillingCallbacks callbacks)
{
	IAP *iap = [IAP sharedInstance];
	[iap setCallbacks:callbacks];
	[[iap billingManager] startConnection];
}

void fetchProductsIAP(const char** productIdentifiers, size_t count)
{
	NSMutableArray<NSString *> *objcProductIdentifiers = [NSMutableArray array];

	for (size_t i = 0; i < count; ++i)
		[objcProductIdentifiers addObject:[NSString stringWithUTF8String:productIdentifiers[i]]];

	[[IAP sharedInstance] fetchProducts:objcProductIdentifiers];
}

void purchaseProductIAP(const char* productId)
{
	[[IAP sharedInstance] purchaseProduct:[NSString stringWithUTF8String:productId]];
}

void restorePurchasesIAP()
{
	[[IAP sharedInstance] restorePurchases];
}
