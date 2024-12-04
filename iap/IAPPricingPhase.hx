package iap;

@:nullSafety
class IAPPricingPhase
{
	public var billingCycleCount:Int = 0;
	public var billingPeriod:String = '';
	public var formattedPrice:String = '';
	public var priceAmountMicros:String = '';
	public var priceCurrencyCode:String = '';
	public var recurrenceMode:Int = 0;

	public function new():Void {}

	public static function fromJson(json:Dynamic):IAPPricingPhase
	{
		final phase:IAPPricingPhase = new IAPPricingPhase();
		phase.billingCycleCount = json.billingCycleCount;
		phase.billingPeriod = json.billingPeriod;
		phase.formattedPrice = json.formattedPrice;
		phase.priceAmountMicros = json.priceAmountMicros;
		phase.priceCurrencyCode = json.priceCurrencyCode;
		phase.recurrenceMode = json.recurrenceMode;
		return phase;
	}
}
