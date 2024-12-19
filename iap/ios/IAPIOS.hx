package iap.ios;

import iap.ios.IAPProductDetails;
import iap.ios.IAPPurchase;
import lime.app.Event;
import lime.utils.Log;

@:buildXml('<include name="${haxelib:extension - iap}/project/iap-ios/Build.xml" />')
@:headerInclude('IAP.hpp')
class IAPIOS
{
	public static var onSetup(default, null):Event<Bool->Void> = new Event<Bool->Void>();
	public static var onDebugLog(default, null):Event<String->Void> = new Event<String->Void>();
	public static var onQueryInAppProductDetails(default, null):Event<Array<IAPProductDetails>->Void> = new Event<Array<IAPProductDetails>->Void>();
	public static var onPurchaseCompleted(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();
	public static var onRestoreCompleted(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	@:noCompletion
	private static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;

		final callbacks:IAPCallbacks = new IAPCallbacks();
		callbacks.onBillingClientSetup = cpp.Callable.fromStaticFunction(onSetupCallback);
		callbacks.onBillingClientDebugLog = cpp.Callable.fromStaticFunction(onDebugLogCallback);
		callbacks.onQueryProductDetails = cpp.Callable.fromStaticFunction(onQueryProductDetailsCallback);
		callbacks.onPurchaseCompleted = cpp.Callable.fromStaticFunction(onPurchaseCompletedCallback);
		callbacks.onRestoreCompleted = cpp.Callable.fromStaticFunction(onRestoreCompletedCallback);
		initIAP(callbacks);

		initialized = true;
	}

	public static function queryProductDetails(productIdentifiers:Array<String>):Void
	{
		if (!initialized)
			return;

		final rawProductsArray:cpp.RawPointer<cpp.ConstCharStar> = untyped __cpp__('new const char *[{0}]', productIdentifiers.length);

		for (i in 0...productIdentifiers.length)
			rawProductsArray[i] = cpp.ConstCharStar.fromString(productIdentifiers[i]);

		queryProductDetailsIAP(rawProductsArray, productIdentifiers.length);

		untyped __cpp__('delete[] {0}', rawProductsArray);
	}

	@:noCompletion
	private static function onSetupCallback(status:Bool):Void
	{
		IAPIOS.onSetup.dispatch(status);
	}

	@:noCompletion
	private static function onDebugLogCallback(message:cpp.ConstCharStar):Void
	{
		IAPIOS.onDebugLog.dispatch(message);
	}

	@:noCompletion
	private static function onQueryProductDetailsCallback(data:cpp.ConstCharStar):Void
	{
		final parsedProductsDetails:Dynamic = haxe.Json.parse(data);

		if (parsedProductsDetails != null)
		{
			final productsDetails:Array<IAPProductDetails> = [];

			for (productDetails in (parsedProductsDetails : Array<Dynamic>))
				productsDetails.push(new IAPProductDetails(productDetails));

			IAPIOS.onQueryInAppProductDetails.dispatch(productsDetails);
		}
	}

	@:noCompletion
	private static function onPurchaseCompletedCallback(data:cpp.ConstCharStar):Void
	{
		IAPIOS.onPurchaseCompleted.dispatch(new IAPPurchase(haxe.Json.parse(data)));
	}

	@:noCompletion
	private static function onRestoreCompletedCallback(data:cpp.ConstCharStar):Void
	{
		final parsedPurchases:Dynamic = haxe.Json.parse(data);

		if (parsedPurchases != null)
		{
			final purchases:Array<IAPPurchase> = [];

			for (purchase in (parsedPurchases : Array<Dynamic>))
				purchases.push(new IAPPurchase(purchase));

			IAPIOS.onRestoreCompleted.dispatch(purchases);
		}
	}

	@:native('initIAP')
	extern public static function initIAP(callbacks:IAPCallbacks):Void;

	@:native('queryProductDetailsIAP')
	extern public static function queryProductDetailsIAP(productIdentifiers:cpp.RawPointer<cpp.ConstCharStar>, count:cpp.SizeT):Void;

	@:native('purchaseProductIAP')
	extern public static function purchaseProductIAP(productId:cpp.ConstCharStar):Void;

	@:native('restorePurchasesIAP')
	extern public static function restorePurchasesIAP():Void;
}

@:buildXml('<include name="${haxelib:extension - iap}/project/iap-ios/Build.xml" />')
@:include('IAP.hpp')
@:unreflective
@:structAccess
@:noCompletion
@:native('IAPCallbacks')
private extern class IAPCallbacks
{
	function new():Void;

	var onBillingClientSetup:cpp.Callable<(success:Bool) -> Void>;
	var onBillingClientDebugLog:cpp.Callable<(message:cpp.ConstCharStar) -> Void>;
	var onQueryProductDetails:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
	var onPurchaseCompleted:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
	var onRestoreCompleted:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
}
