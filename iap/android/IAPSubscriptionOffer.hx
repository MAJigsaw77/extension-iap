package iap.android;

import iap.android.IAPPricingPhase;

class IAPSubscriptionOffer
{
	public final offerId:Null<String>;
	public final basePlanId:String;
	public final offerTags:Array<String>;
	public final offerToken:String;

	public var pricingPhases(default, null):Array<IAPPricingPhase> = [];

	public function new(json:Dynamic):Void
	{
		offerId = json.offerId;
		basePlanId = json.basePlanId;
		offerTags = (json.offerTags : Array<String>) ?? [];
		offerToken = json.offerToken;

		if (json.pricingPhases != null)
		{
			for (phaseJson in (json.pricingPhases : Array<Dynamic>))
				pricingPhases.push(new IAPPricingPhase(phaseJson));
		}
	}
}
