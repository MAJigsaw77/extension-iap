package iap.android;

class IAPProductDetails
{
	public final productId:String;
	public final productType:String;
	public final title:String;
	public final name:String;
	public final description:String;
	public final formattedPrice:String;
	public final priceAmountMicros:Float;
	public final priceCurrencyCode:String;

	public function new(json:Dynamic):Void
	{
		productId = json.productId;
		productType = json.productType;
		title = json.title;
		name = json.name;
		description = json.description;
		formattedPrice = json.formattedPrice;
		priceAmountMicros = json.priceAmountMicros;
		priceCurrencyCode = json.priceCurrencyCode;
	}
}
