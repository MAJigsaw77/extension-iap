package iap;

import haxe.Int64;

@:nullSafety
class IAPPurchase
{
	public final key:String;
	public final orderId:String;
	public final packageName:String;
	public final developerPayload:String;
	public final productId:String;
	public final purchaseTime:Int64;
	public final token:String;
	public final autoRenewing:Bool;
	public final signature:String;

	public function new(key:String, signature:String, json:Dynamic):Void
	{
		this.key = key;
		this.signature = signature;

		orderId = json.orderId;
		packageName = json.packageName;
		developerPayload = json.developerPayload;
		productId = json.productId;
		purchaseTime = json.purchaseTime;
		token = json.purchaseToken;
		autoRenewing = json.autoRenewing;
	}
}
