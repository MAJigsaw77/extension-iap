package iap;

import iap.IAPSubscriptionOffer;

@:nullSafety
class IAPProductDetails
{
	public final productID:String;
	public final productType:String;
	public final title:String;
	public final name:String;
	public final description:String;
	public final formattedPrice:String;
	public final priceAmountMicros:Float;
	public final priceCurrencyCode:String;
	public final subscriptionOffers:Array<IAPSubscriptionOffer>;

	public function new(json:Dynamic):Void
	{
		productID = json.productID;
		productType = json.productType;
		title = json.title;
		name = json.name;
		description = json.description;
		formattedPrice = json.formattedPrice;
		priceAmountMicros = json.priceAmountMicros;
		priceCurrencyCode = json.priceCurrencyCode;

		if (json.subscriptionOffers != null)
		{
			for (offerJson in (json.subscriptionOffers : Array<Dynamic>))
				subscriptionOffers.push(new IAPSubscriptionOffer(offerJson));
		}
		else
			subscriptionOffers = [];
	}
}
