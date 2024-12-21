package iap.apple;

class IAPProductDetails
{
	public final productIdentifier:String;
	public final localizedTitle:String;
	public final localizedDescription:String;
	public final price:Float;
	public final priceLocale:String;

	public function new(json:Dynamic):Void
	{
		productIdentifier = json.productIdentifier;
		localizedTitle = json.localizedTitle;
		localizedDescription = json.localizedDescription;
		price = Std.parseFloat(json.price);
		priceLocale = json.priceLocale;
	}
}
