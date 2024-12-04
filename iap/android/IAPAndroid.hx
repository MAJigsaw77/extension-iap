package iap.android;

#if android
import admob.android.util.JNICache;
import lime.app.Event;
import lime.utils.Log;

class IAPAndroid
{
	public static var onStarted:Event<Bool->Void> = new Event<Bool->Void>();
	public static var onConsume:Event<String->Void> = new Event<String->Void>();
	public static var onFailedConsume:Event<String->Void> = new Event<String->Void>();
	public static var onAcknowledgePurchase:Event<String->Void> = new Event<String->Void>();
	public static var onFailedAcknowledgePurchase:Event<String->Void> = new Event<String->Void>();
	public static var onPurchase:Event<String->String-> Void> = new Event<String->String->Void>();
	public static var onCanceledPurchase:Event<String->Void> = new Event<String->Void>();
	public static var onFailedPurchase:Event<String->Void> = new Event<String->Void>();
	public static var onRequestProductDataComplete:Event<String->Void> = new Event<String->Void>();
	public static var onQueryPurchasesFinished:Event<String->Void> = new Event<String->Void>();

	@:noCompletion
	private static var initialized:Bool = false;

	public static function init(publicKey:String):Void
	{
		if (initialized)
			return;

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'init', '(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V')(publicKey, new CallBackHandler());

		initialized = true;
	}

	public static function purchase(productID:String, devPayload:String):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'purchase', '(Ljava/lang/String;Ljava/lang/String;)V')(productID, devPayload);
	}

	public static function acknowledgePurchase(purchase:String, signature:String):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'acknowledgePurchase', '(Ljava/lang/String;Ljava/lang/String;)V')(purchase, signature);
	}

	public static function querySkuDetails(ids:Array<String>):Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'querySkuDetails', '([Ljava/lang/String;)V')(ids);
	}

	public static function queryInventory():Void
	{
		if (!initialized)
		{
			Log.warn('IAP not initialized.');
			return;
		}

		JNICache.createStaticMethod('org/haxe/extension/IAP', 'queryInventory', '()V')();
	}
}

@:noCompletion
private class CallBackHandler #if (lime >= "8.0.0") implements lime.system.JNI.JNISafety #end
{
	public function new():Void {}

	@:keep @:runOnMainThread public function onStarted(status:Bool):Void
	{
		IAPAndroid.onStarted.dispatch(status);
	}

	@:keep @:runOnMainThread public function onConsume(purchase:String):Void
	{
		IAPAndroid.onConsume.dispatch(purchase);
	}

	@:keep @:runOnMainThread public function onFailedConsume(error:String):Void
	{
		IAPAndroid.onFailedConsume.dispatch(error);
	}

	@:keep @:runOnMainThread public function onAcknowledgePurchase(purchase:String):Void
	{
		IAPAndroid.onAcknowledgePurchase.dispatch(purchase);
	}

	@:keep @:runOnMainThread public function onFailedAcknowledgePurchase(error:String):Void
	{
		IAPAndroid.onFailedAcknowledgePurchase.dispatch(error);
	}

	@:keep @:runOnMainThread public function onPurchase(purchase:String, signature:String):Void
	{
		IAPAndroid.onPurchase.dispatch(purchase, signature);
	}

	@:keep @:runOnMainThread public function onCanceledPurchase(reason:String):Void
	{
		IAPAndroid.onCanceledPurchase.dispatch(reason);
	}

	@:keep @:runOnMainThread public function onFailedPurchase(error:String):Void
	{
		IAPAndroid.onFailedPurchase.dispatch(error);
	}

	@:keep @:runOnMainThread public function onRequestProductDataComplete(result:String):Void
	{
		IAPAndroid.onRequestProductDataComplete.dispatch(result);
	}

	@:keep @:runOnMainThread public function onQueryPurchasesFinished(result:String):Void
	{
		IAPAndroid.onQueryPurchasesFinished.dispatch(result);
	}
}
#end
