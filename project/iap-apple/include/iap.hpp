#pragma once

#include <stddef.h>

typedef struct {
    void (*onBillingClientSetup)(bool success);
    void (*onBillingClientDebugLog)(const char* message);
    void (*onQueryProductDetails)(const char* data);
    void (*onPurchaseCompleted)(const char* data);
    void (*onRestoreCompleted)(const char* data);
} IAPCallbacks;

void initIAP(IAPCallbacks callbacks);
void queryProductDetailsIAP(const char** productIdentifiers, size_t count);
void purchaseProductIAP(const char* productId);
void restorePurchasesIAP();
bool canMakePurchasesIAP();
