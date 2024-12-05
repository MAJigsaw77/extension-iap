package iap;

import haxe.Int64;

@:nullSafety
class IAPPurchase
{
	public final orderId:String;
	public final packageName:String;
	public final developerPayload:String;
	public final productId:Array<String>;
	public final purchaseTime:Int64;
	public final token:String;
	public final autoRenewing:Bool;

	public final signature:String;
	public final stringifyedJson:String;

	public function new(json:Dynamic, signature:String):Void
	{
		orderId = json.orderId;
		packageName = json.packageName;
		developerPayload = json.developerPayload;
		productId = json.productId;
		purchaseTime = json.purchaseTime;
		token = json.purchaseToken;
		autoRenewing = json.autoRenewing;

		this.signature = signature;
		this.stringifyedJson = haxe.Json.stringify(json);
	}
}
