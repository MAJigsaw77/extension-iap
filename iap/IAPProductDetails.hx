package iap;

import iap.IAPSubscriptionOffer;

@:nullSafety
class IAPProductDetails
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

	public static function fromJson(json:Dynamic):IAPProductDetails
	{
		final productDetails:IAPProductDetails = new IAPProductDetails();
		productDetails.productID = json.productID;
		productDetails.productType = json.productType;
		productDetails.title = json.title;
		productDetails.name = json.name;
		productDetails.description = json.description;
		productDetails.formattedPrice = json.formattedPrice;
		productDetails.priceAmountMicros = json.priceAmountMicros;
		productDetails.priceCurrencyCode = json.priceCurrencyCode;

		if (json.subscriptionOffers != null)
		{
			for (offerJson in json.subscriptionOffers)
				productDetails.subscriptionOffers.push(IAPSubscriptionOffer.fromJson(offerJson));
		}

		return productDetails;
	}
}
