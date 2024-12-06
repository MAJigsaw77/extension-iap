package iap.android;

#if android
import iap.android.util.JNICache;
import iap.IAPProductDetails;
import iap.IAPPurchase;
import lime.app.Event;
import lime.utils.Log;

/**
 * A class that handles in-app purchase (IAP) functionality on Android, using JNI to interact with the native Android platform.
 * Provides methods for initializing the IAP system, purchasing, consuming, acknowledging purchases, and querying product details.
 */
class IAPAndroid
{
	/**
	 * Event dispatched when the IAP system initialization starts.
	 * @param status A boolean indicating the initialization status.
	 */
	public static var onStarted(default, null):Event<Bool->Void> = new Event<Bool->Void>();

	/**
	 * Event dispatched when a purchase is successfully consumed.
	 * @param purchase The IAPPurchase object representing the consumed purchase.
	 */
	public static var onConsume(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();

	/**
	 * Event dispatched when consuming a purchase fails.
	 * @param error A string representing the error message.
	 * @param purchase The IAPPurchase object representing the purchase that failed to consume.
	 */
	public static var onFailedConsume(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	/**
	 * Event dispatched when a purchase is successfully acknowledged.
	 * @param purchase The IAPPurchase object representing the acknowledged purchase.
	 */
	public static var onAcknowledgePurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();

	/**
	 * Event dispatched when acknowledging a purchase fails.
	 * @param error A string representing the error message.
	 * @param purchase The IAPPurchase object representing the purchase that failed to acknowledge.
	 */
	public static var onFailedAcknowledgePurchase(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	/**
	 * Event dispatched when a purchase is completed.
	 * @param purchase The IAPPurchase object representing the completed purchase.
	 */
	public static var onPurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();

	/**
	 * Event dispatched when a purchase is canceled.
	 * @param purchase The IAPPurchase object representing the canceled purchase.
	 */
	public static var onCanceledPurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();

	/**
	 * Event dispatched when a purchase fails.
	 * @param error A string representing the error message.
	 * @param purchase The IAPPurchase object representing the failed purchase.
	 */
	public static var onFailedPurchase(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	/**
	 * Event dispatched when product details are finished being queried.
	 * @param result An array of IAPProductDetails objects representing the queried product details.
	 */
	public static var onQueryProductDetailsFinished(default, null):Event<Array<IAPProductDetails>->Void> = new Event<Array<IAPProductDetails>->Void>();

	/**
	 * Event dispatched when purchase details are finished being queried.
	 * @param purchases An array of IAPPurchase objects representing the queried purchases.
	 */
	public static var onQueryPurchasesFinished(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	/**
	 * Event dispatched when an error occurs during IAP processing.
	 * @param errorMessage A string representing the error message.
	 */
	public static var onError(default, null):Event<String->Void> = new Event<String->Void>();

	// Flag to indicate if the IAP system has been initialized.
	@:noCompletion
	private static var initialized:Bool = false;

	/**
	 * Initializes the IAP system with a public key for authentication.
	 * @param publicKey The public key used for IAP authentication.
	 */
	public static function init(publicKey:String):Void
	{
		if (initialized)
			return;

		final initJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'init', '(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V');

		if (initJNI != null)
		{
			initJNI(publicKey, new CallBackHandler());

			initialized = true;
		}
	}

	/**
	 * Initiates a purchase for a product.
	 * @param productDetails The IAPProductDetails object representing the product to be purchased.
	 */
	public static function purchase(productDetails:IAPProductDetails):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final purchaseJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'purchase', '(Ljava/lang/String;)V');

		if (purchaseJNI != null)
			purchaseJNI(productDetails.productId);
	}

	/**
	 * Consumes a purchased product.
	 * @param purchase The IAPPurchase object representing the purchase to be consumed.
	 */
	public static function consume(purchase:IAPPurchase):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final consumeJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'consume', '(Ljava/lang/String;Ljava/lang/String;)V');

		if (consumeJNI != null)
			consumeJNI(purchase.stringifyedJson, purchase.signature);
	}

	/**
	 * Acknowledges a purchased product.
	 * @param purchase The IAPPurchase object representing the purchase to be acknowledged.
	 */
	public static function acknowledgePurchase(purchase:IAPPurchase):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final acknowledgePurchaseJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'acknowledgePurchase',
			'(Ljava/lang/String;Ljava/lang/String;)V');

		if (acknowledgePurchaseJNI != null)
			acknowledgePurchaseJNI(purchase.stringifyedJson, purchase.signature);
	}

	/**
	 * Queries product details asynchronously.
	 * @param ids An array of product IDs to query details for.
	 */
	public static function queryInAppProductDetailsAsync(ids:Array<String>):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final queryInAppProductDetailsJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'queryInAppProductDetailsAsync',
			'([Ljava/lang/String;)V');

		if (queryInAppProductDetailsJNI != null)
			queryInAppProductDetailsJNI(ids);
	}

	/**
	 * Queries subscription product details asynchronously.
	 * @param ids An array of subscription product IDs to query details for.
	 */
	public static function querySubsProductDetailsAsync(ids:Array<String>):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final querySubsProductDetailsJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'querySubsProductDetailsAsync',
			'([Ljava/lang/String;)V');

		if (querySubsProductDetailsJNI != null)
			querySubsProductDetailsJNI(ids);
	}

	/**
	 * Queries in-app purchases asynchronously.
	 */
	public static function queryInAppPurchasesAsync():Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final queryInAppPurchasesJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'queryInAppPurchasesAsync', '()V');

		if (queryInAppPurchasesJNI != null)
			queryInAppPurchasesJNI();
	}

	/**
	 * Queries subscription purchases asynchronously.
	 */
	public static function querySubsPurchasesAsync():Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		final querySubsPurchasesJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'querySubsPurchasesAsync', '()V');

		if (querySubsPurchasesJNI != null)
			querySubsPurchasesJNI();
	}
}

@:noCompletion
private class CallBackHandler #if (lime >= "8.0.0") implements lime.system.JNI.JNISafety #end
{
	public function new():Void {}

	@:keep
	@:runOnMainThread
	public function onStarted(status:Bool):Void
	{
		IAPAndroid.onStarted.dispatch(status);
	}

	@:keep
	@:runOnMainThread public function onConsume(purchase:String, signature:String):Void
	{
		IAPAndroid.onConsume.dispatch(new IAPPurchase(haxe.Json.parse(purchase), signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedConsume(error:String):Void
	{
		final error:Dynamic = haxe.Json.parse(error);

		if (error != null)
			IAPAndroid.onFailedAcknowledgePurchase.dispatch(error.result, new IAPPurchase(error.purchase.originalJson, error.purchase.signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onAcknowledgePurchase(purchase:String, signature:String):Void
	{
		IAPAndroid.onAcknowledgePurchase.dispatch(new IAPPurchase(haxe.Json.parse(purchase), signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedAcknowledgePurchase(error:String):Void
	{
		final error:Dynamic = haxe.Json.parse(error);

		if (error != null)
			IAPAndroid.onFailedAcknowledgePurchase.dispatch(error.result, new IAPPurchase(error.purchase.originalJson, error.purchase.signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onPurchase(purchase:String, signature:String):Void
	{
		IAPAndroid.onPurchase.dispatch(new IAPPurchase(haxe.Json.parse(purchase), signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onCanceledPurchase(purchase:String, signature:String):Void
	{
		IAPAndroid.onCanceledPurchase.dispatch(new IAPPurchase(haxe.Json.parse(purchase), signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedPurchase(error:String):Void
	{
		final error:Dynamic = haxe.Json.parse(error);

		if (error != null)
			IAPAndroid.onFailedPurchase.dispatch(error.result, new IAPPurchase(error.purchase.originalJson, error.purchase.signature));
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQueryProductDetailsFinished(result:String):Void
	{
		final productsDetails:Array<IAPProductDetails> = [];

		for (productDetails in (haxe.Json.parse(result).purchases : Array<Dynamic>))
			productsDetails.push(new IAPProductDetails(productDetails));

		IAPAndroid.onQueryProductDetailsFinished.dispatch(productsDetails);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQueryPurchasesFinished(result:String):Void
	{
		final purchases:Array<IAPPurchase> = [];

		for (purchase in (haxe.Json.parse(result).purchases : Array<Dynamic>))
			purchases.push(new IAPPurchase(purchase.originalJson, purchase.signature));

		IAPAndroid.onQueryPurchasesFinished.dispatch(purchases);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onError(errorMessage:String):Void
	{
		IAPAndroid.onError.dispatch(errorMessage);
	}
}
#end
