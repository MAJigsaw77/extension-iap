package iap.android;

#if android
import admob.android.util.JNICache;
import lime.app.Event;
import lime.utils.Log;

class IAPAndroid
{
	public static var onStarted:Event<Bool->Void> = new Event<Bool->Void>();
	public static var onConsume:Event<String->Void> = new Event<String->Void>();

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

/**
 * Internal callback handler for AdMob events.
 */
@:noCompletion
private class CallBackHandler #if (lime >= "8.0.0") implements lime.system.JNI.JNISafety #end
{
	public function new():Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onStarted(status:Bool):Void
	{
		if (IAPAndroid.onStarted != null)
			IAPAndroid.onStarted(status);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onConsume(purchase:String):Void
	{
		if (IAPAndroid.onConsume != null)
		{
			final purchaseJson:Dynamic = haxe.Json.parse(purchase);

			if (purchaseJson != null && Reflect.hasField(purchaseJson, 'productId'))
				IAPAndroid.onConsume(Reflect.field(purchaseJson, 'productId'));
		}
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedConsume(error:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onAcknowledgePurchase(purchase:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedAcknowledgePurchase(error:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onPurchase(purchase:String, signature:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onCanceledPurchase(reason:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onFailedPurchase(error:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onRequestProductDataComplete(result:String):Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onQueryPurchasesFinished(result:String):Void {}
}
#end
