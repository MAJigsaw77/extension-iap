package iap;

@:nullSafety
class IAPPricingPhase
{
	public final billingCycleCount:Int;
	public final billingPeriod:String;
	public final formattedPrice:String;
	public final priceAmountMicros:String;
	public final priceCurrencyCode:String;
	public final recurrenceMode:Int;

	public function new(json:Dynamic):Void
	{
		billingCycleCount = json.billingCycleCount;
		billingPeriod = json.billingPeriod;
		formattedPrice = json.formattedPrice;
		priceAmountMicros = json.priceAmountMicros;
		priceCurrencyCode = json.priceCurrencyCode;
		recurrenceMode = json.recurrenceMode;
	}
}
