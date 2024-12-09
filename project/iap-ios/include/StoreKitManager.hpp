#pragma once

typedef struct
{
    void (*onProductsQueried)(const char *productsJson);  // JSON list of products
    void (*onPurchaseCompleted)(const char *productID);    // Successfully purchased product ID
    void (*onPurchaseFailed)(const char *error);           // Error message
    void (*onRestoreCompleted)(void);                     // All purchases restored
    void (*onRestoreFailed)(const char *error);           // Error restoring purchases
} StoreKitCallbacks;

void StoreKit_Init(StoreKitCallbacks *callbacks);
void StoreKit_QueryProducts(const char **productIDs, int productCount);
void StoreKit_Purchase(const char *productID);
void StoreKit_RestorePurchases();
void StoreKit_Destroy();
