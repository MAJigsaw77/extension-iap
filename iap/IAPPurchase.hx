package iap;

import haxe.Int64;

class IAPPurchase
{
	public final orderId:String;
	public final packageName:String;
	public final developerPayload:String;
	public final productId:Array<String>;
	public final purchaseTime:Int64;
	public final token:String;
	public final autoRenewing:Bool;
	public final stringifyedJson:String;
	public final signature:String;

	public function new(json:Dynamic, signature:String):Void
	{
		orderId = json.orderId;
		packageName = json.packageName;
		developerPayload = json.developerPayload;
		productId = json.productId;
		purchaseTime = json.purchaseTime;
		token = json.purchaseToken;
		autoRenewing = json.autoRenewing;

		this.stringifyedJson = haxe.Json.stringify(json);
		this.signature = signature;
	}
}
