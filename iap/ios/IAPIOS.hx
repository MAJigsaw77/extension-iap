package iap.ios;

import iap.ios.IAPProductDetails;
import iap.ios.IAPPurchase;
import lime.app.Event;
import lime.utils.Log;

/**
 * A class that handles in-app purchase (IAP) functionality on iOS, using native platform integration.
 * Provides methods for initializing the IAP system, purchasing products, querying product details, and restoring purchases.
 */
@:buildXml('<include name="${haxelib:extension-iap}/project/iap-ios/Build.xml" />')
@:headerInclude('IAP.hpp')
class IAPIOS
{
	/**
	 * Event dispatched on the IAP system initialization setup.
	 * @param status A boolean indicating the initialization status.
	 */
	public static var onSetup(default, null):Event<Bool->Void> = new Event<Bool->Void>();

	/**
	 * Event dispatched when a debug log occurs during IAP processing.
	 * @param message A string representing the debug message.
	 */
	public static var onDebugLog(default, null):Event<String->Void> = new Event<String->Void>();

	/**
	 * Event dispatched when product details have been successfully queried.
	 * @param result An array of IAPProductDetails objects representing the queried product details.
	 */
	public static var onQueryInAppProductDetails(default, null):Event<Array<IAPProductDetails>->Void> = new Event<Array<IAPProductDetails>->Void>();

	/**
	 * Event dispatched when a purchase has been successfully completed.
	 * @param purchase The IAPPurchase object representing the completed purchase.
	 */
	public static var onPurchaseCompleted(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();

	/**
	 * Event dispatched when restoring purchases has been successfully completed.
	 * @param purchases An array of IAPPurchase objects representing the restored purchases.
	 */
	public static var onRestoreCompleted(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	@:noCompletion
	private static var initialized:Bool = false;

	/**
	 * Initializes the IAP system with necessary callbacks for event handling.
	 * This must be called before any other IAP-related methods.
	 */
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

	/**
	 * Queries product details for a list of product IDs.
	 * @param ids An array of product IDs to query details for.
	 */
	public static function queryProductDetails(ids:Array<String>):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final rawProductsArray:cpp.RawPointer<cpp.ConstCharStar> = untyped __cpp__('new const char *[{0}]', ids.length);

		for (i in 0...ids.length)
			rawProductsArray[i] = cpp.ConstCharStar.fromString(ids[i]);

		queryProductDetailsIAP(rawProductsArray, ids.length);

		untyped __cpp__('delete[] {0}', rawProductsArray);
	}

	/**
	 * Initiates a purchase for a product.
	 * @param productDetails The IAPProductDetails object representing the product to be purchased.
	 */
	public static function purchaseProduct(productDetails:IAPProductDetails):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		purchaseProductIAP(productDetails.productIdentifier);
	}

	/**
	 * Restores previous purchases that were made by the user.
	 */
	public static function restorePurchases():Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		restorePurchasesIAP();
	}

	/**
	 * Checks if the user is allowed to make purchases on the current device.
	 *
	 * The value can be `false` under the following conditions:
	 * - Content & Privacy Restrictions in Screen Time are set to prevent purchases.
	 *   For more information, see [Use parental controls on your child’s iPhone, iPad, and iPod touch](https://support.apple.com/en-us/HT201304).
	 * - The device has a mobile device management (MDM) profile that prevents purchases.
	 *   For more information, see [Device Management](https://support.apple.com/business/).
	 *
	 * If the method returns `true` and your app uses only StoreKit In-App Purchase APIs, the user can authorize purchases in the App Store,
	 * and your app can offer In-App Purchases.
	 *
	 * @return A boolean indicating whether purchases are allowed.
	 */
	public static function canMakePurchases():Bool
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		return canMakePurchasesIAP();
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
	extern public static function purchaseProductIAP(productIdentifier:cpp.ConstCharStar):Void;

	@:native('restorePurchasesIAP')
	extern public static function restorePurchasesIAP():Void;

	@:native('canMakePurchasesIAP')
	extern public static function canMakePurchasesIAP():Bool;
}

@:buildXml('<include name="${haxelib:extension-iap}/project/iap-ios/Build.xml" />')
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
