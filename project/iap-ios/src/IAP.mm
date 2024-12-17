#import "IAP.hpp"

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface IAP : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSArray<SKProduct *> *availableProducts;

+ (instancetype)sharedInstance;
- (void)initIAP;

@end

@implementation IAP

+ (instancetype)sharedInstance
{
	static IAP *sharedInstance = nil;

	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (void)initIAP
{
	NSLog(@"Initializing In-App Purchases...");

	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	NSArray<NSString *> *productIdentifiers = @[@"com.example.app.product1", @"com.example.app.product2"];
	[self fetchProducts:productIdentifiers];
}

- (void)fetchProducts:(NSArray<NSString *> *)productIdentifiers
{
	NSLog(@"Fetching products...");

	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
	productsRequest.delegate = self;
	[productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSLog(@"Received product response");

	self.availableProducts = response.products; // Store available products

	for (SKProduct *product in self.availableProducts)
	{
		NSLog(@"Product found: %@ - %@", product.localizedTitle, product.price);
	}

	if (response.invalidProductIdentifiers.count > 0)
	{
		NSLog(@"Invalid product identifiers: %@", response.invalidProductIdentifiers);
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				NSLog(@"Transaction successful: %@", transaction.payment.productIdentifier);
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				NSLog(@"Transaction failed: %@", transaction.error.localizedDescription);
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				NSLog(@"Transaction restored: %@", transaction.payment.productIdentifier);
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			default:
				break;
		}
	}
}

- (void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end

void initIAP()
{
	[[IAP sharedInstance] initIAP];
}
