#pragma once

typedef struct {
    void (*onBillingClientSetup)(bool success);
    void (*onBillingClientDebugLog)(const char* message);
    void (*onQueryProductDetails)(const char* productDetails[], size_t count);
    void (*onPurchaseCompleted)(const char* productId);
    void (*onRestoreCompleted)(const char* productIds[], size_t count);
} BillingCallbacks;

void initIAP(BillingCallbacks callbacks);
void fetchProductsIAP(const char** productIdentifiers, size_t count);
void purchaseProductIAP(const char* productId);
void restorePurchasesIAP();
