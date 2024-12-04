package iap;

import haxe.Int64;

@:nullSafety
class IAPPurchase
{
	public var key:String = '';
	public var orderId:String = '';
	public var packageName:String = '';
	public var developerPayload:String = '';
	public var productId:String = '';
	public var purchaseTime:Int64 = 0;
	public var token:String = '';
	public var autoRenewing:Bool = false;
	public var signature:String = '';

	public function new():Void {}

	public static function fromJson(json:Dynamic):IAPPurchase
	{
		final purchase:IAPPurchase = new IAPPurchase();
		purchase.key = json.key;
		purchase.orderId = json.originalJson.orderId;
		purchase.packageName = json.originalJson.packageName;
		purchase.developerPayload = json.originalJson.developerPayload;
		purchase.productId = json.originalJson.productId;
		purchase.purchaseTime = json.originalJson.purchaseTime;
		purchase.token = json.originalJson.purchaseToken;
		purchase.autoRenewing = json.originalJson.autoRenewing;
		purchase.signature = json.signature;
		return purchase;
	}
}
