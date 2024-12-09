#import "StoreKitManager.hpp"

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface StoreKitManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *availableProducts;
@property (nonatomic, assign) StoreKitCallbacks *callbacks;
@end

@implementation StoreKitManager

+ (instancetype)sharedInstance
{
	static StoreKitManager *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[StoreKitManager alloc] init];
	});
	return instance;
}

- (instancetype)init
{
	self = [super init];

	if (self)
	{
		[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

		self.availableProducts = [NSMutableDictionary dictionary];
	}

	return self;
}

- (void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSMutableArray *productsArray = [NSMutableArray array];

	for (SKProduct *product in response.products)
	{
		[productsArray addObject:@{
			@"id": product.productIdentifier,
   			@"title": product.localizedTitle,
      			@"description": product.localizedDescription,
	 		@"price": product.price.stringValue
    		}];

		self.availableProducts[product.productIdentifier] = product;
	}
	
	if (self.callbacks && self.callbacks->onProductsQueried)
	{
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:productsArray options:0 error:nil];
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		self.callbacks->onProductsQueried(jsonString.UTF8String);
	}
}

@end

void StoreKit_Init(StoreKitCallbacks *callbacks)
{
	[StoreKitManager sharedInstance].callbacks = callbacks;
}

void StoreKit_QueryProducts(const char **productIDs, int productCount)
{
	NSMutableSet *productIdentifiers = [NSMutableSet set];

	for (int i = 0; i < productCount; i++)
	{
		NSString *productID = [NSString stringWithUTF8String:productIDs[i]];
		[productIdentifiers addObject:productID];
	}
	
	SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
	[StoreKitManager sharedInstance].productsRequest = request;
	request.delegate = [StoreKitManager sharedInstance];
	[request start];
}

void StoreKit_Purchase(const char *productID)
{
	NSString *productIDString = [NSString stringWithUTF8String:productID];

	SKProduct *product = [StoreKitManager sharedInstance].availableProducts[productIDString];

	if (product)
		[[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
	else
		NSLog(@"[StoreKit] Product not found: %@", productIDString);
}

void StoreKit_RestorePurchases()
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

void StoreKit_Destroy()
{
	StoreKitManager *manager = [StoreKitManager sharedInstance];
	manager.callbacks = NULL;
	[manager.availableProducts removeAllObjects];
}
