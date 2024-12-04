package iap;

import iap.IAPSubscriptionOffer;

@:nullSafety
class IAPPurchase
{
	public var productID:String = '';
	public var productType:String = '';
	public var title:String = '';
	public var name:String = '';
	public var description:String = '';
	public var formattedPrice:Null<String> = null;
	public var priceAmountMicros:Float = 0.0;
	public var priceCurrencyCode:Null<String> = null;
	public var subscriptionOffers:Array<IAPSubscriptionOffer> = [];

	public function new():Void {}

	public static function fromJson(json:Dynamic):IAPPurchase
	{
		final purchase:IAPPurchase = new IAPPurchase();
		purchase.productID = json.productID;
		purchase.productType = json.productType;
		purchase.title = json.title;
		purchase.name = json.name;
		purchase.description = json.description;
		purchase.formattedPrice = json.formattedPrice;
		purchase.priceAmountMicros = json.priceAmountMicros;
		purchase.priceCurrencyCode = json.priceCurrencyCode;

		if (json.subscriptionOffers != null)
		{
			for (offerJson in json.subscriptionOffers)
				purchase.subscriptionOffers.push(IAPSubscriptionOffer.fromJson(offerJson));
		}

		return purchase;
	}
}
