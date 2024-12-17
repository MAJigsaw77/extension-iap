package iap;

#if android
typedef IAP = iap.android.IAPAndroid;
#elseif ios
typedef IAP = iap.android.IAPIOS;
#end
