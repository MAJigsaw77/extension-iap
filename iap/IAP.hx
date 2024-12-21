package iap;

#if android
typedef IAP = iap.android.IAPAndroid;
#elseif (mac || ios || tvos)
typedef IAP = iap.apple.IAPApple;
#end
