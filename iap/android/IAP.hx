package extension.iap.android;

import extension.iap.IAP;
import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.Lib;
import haxe.Json;

#if (haxe_ver >= 4)
import lime.system.JNI;
#else
import openfl.utils.JNI;
#end

@:allow(extension.iap) class IAP {

	public static var initCounter:Int = 0;

	public static var available (get, null):Bool;
	public static var manualTransactionMode (get, set):Bool;
	public static var inventory(default, null):Inventory = null;
	private static var initialized = false;
	private static var tempProductsData:Array<IAProduct> = [];

	// Event dispatcher composition
	private static var dispatcher = new EventDispatcher ();
	private static var cleanupJobs:Array<Void -> Void> = [];

	/**
	 * Initializes the extension.
	 *
	 * @param publicKey (Android). Your application's public key, encoded in base64.
	 *     This is used for verification of purchase signatures. You can find your app's base64-encoded
	 *     public key in your application's page on Google Play Developer Console. Note that this
	 *     is NOT your "developer public key".
	 *
	 * Related Events (IAPEvent):
	 * 		PURCHASE_INIT: Fired when the initialization was successful
	 * 		PURCHASE_INIT_FAILED: Fired when the initialization failed
	 */

	public static function initialize (publicKey:String = ""):Void {

		if (initialized)
		{
			trace("IAP: already initialized - cleanup it");
			return;
		}

		if (funcInit == null) {
			funcInit = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "initialize", "(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V");
		}

		inventory = new Inventory(null);
		funcInit (publicKey, new IAPHandler ());

		initialized = true;
	}

	public static function cleanup ():Void {
		inventory = null;		
		for (job in cleanupJobs)
		{
			job();
		}
		cleanupJobs = [];
		//If initialized = false, everything is recreated when cleanup() is called
		// This should work fine in the new implementation. If have a problem , uncomment it
		//initialized = false;
	}

	/**
	 * Sends a purchase intent for a given product.
	 *
	 * @param productID (iOS & Android). The unique Id for the desired product (Android Sku).
	 * @param devPayload (Android). Extra data (developer payload), which will be returned with the purchase data
	 *     when the purchase completes. This extra data will be permanently bound to that purchase
	 *     and will always be returned when the purchase is queried.
	 *
	 * Related Events (IAPEvent):
	 * 		PURCHASE_SUCCESS: Fired when the purchase attempt was successful
	 * 		PURCHASE_FAILURE: Fired when the purchase attempt failed
	 * 		PURCHASE_CANCEL: Fired when the purchase attempt was cancelled by the user
	 */

	public static function purchase (productID:String, devPayload:String = ""):Void {

		try {

			if (funcBuy == null) {
				funcBuy = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "buy", "(Ljava/lang/String;Ljava/lang/String;)V");
			}

			funcBuy (productID, devPayload);

		}
		catch (err : Error)
		{
			trace(err.getStackTrace());
		}
	}


	/**
	 * Retrieves localized information about a list of products.
	 * 
	 * @param inArg. A String with the product Id, or an Array of Strings with multiple product Ids.
	 * 
	 * Related Events (IAPEvent): 
	 * 		PURCHASE_PRODUCT_DATA_COMPLETE: Fired when the products data has been retrieved. 
	 * 			The event will come with a productsData array.
	 * 			This method also populates the productDetailsMap property of the inventory, so it can be accessed anytime after calling it.
	 */
	
	public static function requestProductData (ids:Array<String>):Void {

		try {

			if (funcQuerySkuDetails == null) {
				funcQuerySkuDetails = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "querySkuDetails", "([Ljava/lang/String;)V");
			}
			funcQuerySkuDetails(ids);
		}
		catch (err : Error)
		{
			trace(err.getStackTrace());
		}
	}

	/**
	 * Sends a consume intent for a given product.
	 *
	 * @param purchase. The previously purchased product.
	 *
	 * Related Events (IAPEvent):
	 * 		PURCHASE_CONSUME_SUCCESS: Fired when the consume attempt was successful
	 * 		PURCHASE_CONSUME_FAILURE: Fired when the consume attempt failed
	 */

	public static function consume (purchase:Purchase):Void {

		try {
		
			if (funcConsume == null) {
				funcConsume = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "consume", "(Ljava/lang/String;Ljava/lang/String;)V");
			}
			funcConsume (purchase.originalJson, purchase.signature);

		}
		catch (err : Error)
		{
			trace(err.getStackTrace());
		}

	}

	/**
	 * Sends a acknowledgePurchase intent for a given product.
	 *
	 * @param purchase. The previously purchased product.
	 *
	 * Related Events (IAPEvent):
	 * 		PURCHASE_ACKNOWLEDGE_SUCCESS: Fired when the acknowledgePurchase attempt was successful
	 * 		PURCHASE_ACKNOWLEDGE_FAILURE: Fired when the acknowledgePurchase attempt failed
	 */

	public static function acknowledgePurchase (purchase:Purchase):Void {

		if (funcAcknowledgePurchase == null) {
			funcAcknowledgePurchase = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "acknowledgePurchase", "(Ljava/lang/String;Ljava/lang/String;)V");
		}
		funcAcknowledgePurchase (purchase.originalJson, purchase.signature);

	}

	public static function queryInventory (queryItemDetails:Bool = false, moreItems:Array<String> = null):Void {
		try {
		
			if (funcQueryInventory == null) {
				funcQueryInventory = JNI.createStaticMethod ("org/haxe/extension/iap/InAppPurchase", "queryInventory", "()V");
			}

			funcQueryInventory();
		}
		catch (err : Error)
		{
			trace(err.getStackTrace());
		}
	}

	// Getter & Setter Methods


	private static function get_available ():Bool {

		return true;

	}

	private static function get_manualTransactionMode ():Bool {

		return false;

	}

	private static function set_manualTransactionMode (val:Bool):Bool {

		return false;

	}

	// Event Dispatcher composition methods

	public static function addEventListener (type:String, listener:Dynamic, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {

		dispatcher.addEventListener (type, listener, useCapture, priority, useWeakReference);
		cleanupJobs.push(dispatcher.removeEventListener.bind(type, listener, useCapture));
	}

	public static function removeEventListener (type:String, listener:Dynamic, capture:Bool = false):Void {

		dispatcher.removeEventListener (type, listener, capture);

	}

	public static function dispatchEvent (event:Event):Bool {
		// fix for runinig callback from extension in proper gui thread
		haxe.Timer.delay(function() {
			dispatcher.dispatchEvent (event);
		}, 0);

		return true;
	}

	public static function hasEventListener (type:String):Bool {

		return dispatcher.hasEventListener (type);

	}

	// Native Methods
	private static var funcInit:Dynamic;
	private static var funcBuy:Dynamic;
	private static var funcConsume:Dynamic;
	private static var funcAcknowledgePurchase:Dynamic;
	private static var funcRestore:Dynamic;
	private static var funcQueryInventory:Dynamic;
	private static var funcQuerySkuDetails:Dynamic;
	private static var funcTest:Dynamic;
}


#if (!display)


private class IAPHandler {

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function new () { }

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onCanceledPurchase (message:String):Void {
		IAP.dispatcher.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_CANCEL));
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onFailedConsume (response:String):Void {
		var dynResp:Dynamic = Json.parse(response);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_CONSUME_FAILURE);
		evt.productID = Reflect.field(Reflect.field(dynResp, "product"), "productId");
		evt.message = Reflect.field(Reflect.field(dynResp, "result"), "message");
		IAP.dispatchEvent (evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onConsume (response:String):Void {
		trace('onConsume: $response');

		var dynResp:Dynamic = Json.parse(response);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_CONSUME_SUCCESS);
		evt.productID = Reflect.field(dynResp, "productId");		
		IAP.dispatchEvent(evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onFailedAcknowledgePurchase (response:String):Void {
		var dynResp:Dynamic = Json.parse(response);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_ACKNOWLEDGE_FAILURE);
		evt.productID = Reflect.field(Reflect.field(dynResp, "product"), "productId");
		evt.message = Reflect.field(Reflect.field(dynResp, "result"), "message");
		IAP.dispatchEvent (evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onAcknowledgePurchase (response:String):Void {
		trace('onAcknowledgePurchase: $response');

		var dynResp:Dynamic = Json.parse(response);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_ACKNOWLEDGE_SUCCESS);
		evt.productID = Reflect.field(dynResp, "productId");		
		IAP.dispatchEvent(evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onFailedPurchase (response:String):Void {
		var dynResp:Dynamic = Json.parse(response);
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_FAILURE);
		if (Reflect.field(dynResp, "product") != null) evt.productID = Reflect.field(Reflect.field(dynResp, "product"), "productId");
		evt.message = Reflect.field(Reflect.field(dynResp, "result"), "message");
		IAP.dispatchEvent (evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onPurchase (response:String, itemType:String, signature:String):Void {
		var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_SUCCESS);

		evt.purchase = new Purchase(response, itemType, signature);
		evt.productID = evt.purchase.productID;
		IAP.inventory.purchaseMap.set(evt.purchase.productID, evt.purchase);

		IAP.dispatchEvent (evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	public function onRequestProductDataComplete(response:String):Void {

		if (response == "Failure") {
			IAP.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_FAILED));

		} else {

			var dynResp:Dynamic = Json.parse(response);
			var evt:IAPEvent = new IAPEvent (IAPEvent.PURCHASE_PRODUCT_DATA_COMPLETE);
			evt.productsData = new Array<IAProduct>();

			var dynDescriptions:Array<Dynamic> = Reflect.field(dynResp, "products");
			var dynItmValue:Dynamic;
			var prod:IAProduct;

			if (dynDescriptions != null) {
				for (dynItm in dynDescriptions) {
					prod = { productID: Reflect.field(dynItm, "productId") };
					prod.type = Reflect.field(dynItm, "type");
					prod.localizedPrice = Reflect.field(dynItm, "price");
					prod.priceAmountMicros = Reflect.field(dynItm, "price_amount_micros");
					prod.price = prod.priceAmountMicros / 1000 / 1000;
					prod.priceCurrencyCode = Reflect.field(dynItm, "price_currency_code");
					prod.localizedTitle = Reflect.field(dynItm, "title");
					prod.localizedDescription = Reflect.field(dynItm, "description");
					evt.productsData.push(prod);
				}
			}

			IAP.dispatchEvent (evt);
		}
	}

	public function onQueryInventoryComplete(response:String):Void {

		var dynResp:Dynamic = Json.parse(response);
		IAP.inventory = new Inventory(dynResp);

		var evt:IAPEvent = new IAPEvent (IAPEvent.QUERY_INVENTORY_COMPLETE);		
		IAP.dispatchEvent(evt);
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	
	public function onStarted (response:String):Void {
		if (response == "Success") {
			IAP.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT));
		} else {
			IAP.dispatchEvent (new IAPEvent (IAPEvent.PURCHASE_INIT_FAILED));
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

}

#end
