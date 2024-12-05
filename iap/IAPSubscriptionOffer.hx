package iap;

import iap.IAPPricingPhase;

@:nullSafety
class IAPSubscriptionOffer
{
	public var offerId:Null<String>;
	public var basePlanId:String;
	public var offerTags:Array<String>;
	public var offerToken:String;
	public var pricingPhases:Array<IAPPricingPhase>;

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
		else
			pricingPhases = [];
	}
}
