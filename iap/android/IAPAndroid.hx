package iap.android;

#if android
import iap.android.util.JNICache;
import iap.IAPProductDetails;
import iap.IAPPurchase;
import lime.app.Event;
import lime.utils.Log;

class IAPAndroid
{
	public static var onStarted(default, null):Event<Bool->Void> = new Event<Bool->Void>();

	public static var onConsume(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();
	public static var onFailedConsume(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	public static var onAcknowledgePurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();
	public static var onFailedAcknowledgePurchase(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	public static var onPurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();
	public static var onCanceledPurchase(default, null):Event<IAPPurchase->Void> = new Event<IAPPurchase->Void>();
	public static var onFailedPurchase(default, null):Event<String->IAPPurchase->Void> = new Event<String->IAPPurchase->Void>();

	public static var onQueryProductDetailsFinished(default, null):Event<String->Void> = new Event<String->Void>();
	public static var onQueryPurchasesFinished(default, null):Event<Array<IAPPurchase>->Void> = new Event<Array<IAPPurchase>->Void>();

	@:noCompletion
	private static var initialized:Bool = false;

	public static function init(publicKey:String):Void
	{
		if (initialized)
			return;

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'init', '(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V')(publicKey, new CallBackHandler());

		initialized = true;
	}

	public static function purchase(productDetails:IAPProductDetails):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'purchase', '(Ljava/lang/String;)V')(productDetails.productId);
	}

	public static function consume(purchase:IAPPurchase):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'consume', '(Ljava/lang/String;Ljava/lang/String;)V')(purchase.stringifyedJson, purchase.signature);
	}

	public static function acknowledgePurchase(purchase:IAPPurchase):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'acknowledgePurchase', '(Ljava/lang/String;Ljava/lang/String;)V')(purchase.stringifyedJson, purchase.signature);
	}

	public static function queryProductDetails(ids:Array<String>):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'queryProductDetails', '([Ljava/lang/String;)V')(ids);
	}

	public static function queryPurchases():Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'queryPurchases', '()V')();
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

		IAPAndroid.onQueryProductDetailsFinished.dispatch(result);
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
}
#end
