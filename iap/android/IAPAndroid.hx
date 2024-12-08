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
	 * Event dispatched when an debug log occurs during IAP processing.
	 * @param message A string representing the message.
	 */
	public static var onDebugLog(default, null):Event<String->Void> = new Event<String->Void>();

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
	 * Event dispatched when purchase details are finished being queried.
	 * @param purchases An array of IAPPurchase objects representing the queried purchases.
	 */
	public static var onQueryInAppPurchases(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	/**
	 * Event dispatched when purchase details are finished being queried.
	 * @param purchases An array of IAPPurchase objects representing the queried purchases.
	 */
	public static var onQuerySubsPurchases(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	/**
	 * Event dispatched when product details are finished being queried.
	 * @param result An array of IAPProductDetails objects representing the queried product details.
	 */
	public static var onQueryInAppProductDetails(default, null):Event<Array<IAPProductDetails>->Void> = new Event<Array<IAPProductDetails>->Void>();

	/**
	 * Event dispatched when product details are finished being queried.
	 * @param result An array of IAPProductDetails objects representing the queried product details.
	 */
	public static var onQuerySubsProductDetails(default, null):Event<Array<IAPProductDetails>->Void> = new Event<Array<IAPProductDetails>->Void>();

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
	 * Initiates a subscription for a product.
	 * @param productDetails The IAPProductDetails object representing the product to be subscribed to.
	 */
	public static function subscribe(productDetails:IAPProductDetails):Void
	{
		if (!initialized)
		{
			Log.warn('IAP is not initialized. Subscription cannot proceed.');
			return;
		}

		final subscribeJNI:Null<Dynamic> = JNICache.createStaticMethod('org/haxe/extension/IAP', 'subscribe', '(Ljava/lang/String;)V');

		if (subscribeJNI != null)
			subscribeJNI(productDetails.productId);
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
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onDebugLog(message:String):Void
	{
		IAPAndroid.onDebugLog.dispatch(message);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQueryInAppPurchases(result:String):Void
	{
		final parsedResult:Dynamic = haxe.Json.parse(result);

		if (parsedResult != null)
		{
			final purchases:Array<IAPPurchase> = [];

			if (parsedResult.purchases != null)
			{
				for (purchase in (parsedResult.purchases : Array<Dynamic>))
					purchases.push(new IAPPurchase(purchase.originalJson, purchase.signature));
			}

			IAPAndroid.onQueryInAppPurchases.dispatch(purchases);
		}
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQuerySubsPurchases(result:String):Void
	{
		final parsedResult:Dynamic = haxe.Json.parse(result);

		if (parsedResult != null)
		{
			final purchases:Array<IAPPurchase> = [];

			if (parsedResult.purchases != null)
			{
				for (purchase in (parsedResult.purchases : Array<Dynamic>))
					purchases.push(new IAPPurchase(purchase.originalJson, purchase.signature));
			}

			IAPAndroid.onQuerySubsPurchases.dispatch(purchases);
		}
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQueryInAppProductDetails(result:String):Void
	{
		final parsedResult:Dynamic = haxe.Json.parse(result);

		if (parsedResult != null)
		{
			final productsDetails:Array<IAPProductDetails> = [];

			if (parsedResult.purchases != null)
			{
				for (productDetails in (parsedResult.purchases : Array<Dynamic>))
					productsDetails.push(new IAPProductDetails(productDetails));
			}

			IAPAndroid.onQueryInAppProductDetails.dispatch(productsDetails);
		}
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQuerySubsProductDetails(result:String):Void
	{
		final parsedResult:Dynamic = haxe.Json.parse(result);

		if (parsedResult != null)
		{
			final productsDetails:Array<IAPProductDetails> = [];

			if (parsedResult.purchases != null)
			{
				for (productDetails in (parsedResult.purchases : Array<Dynamic>))
					productsDetails.push(new IAPProductDetails(productDetails));
			}

			IAPAndroid.onQuerySubsProductDetails.dispatch(productsDetails);
		}
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
}
#end
