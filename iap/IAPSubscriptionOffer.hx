package iap;

import iap.IAPPricingPhase;

@:nullSafety
class IAPSubscriptionOffer
{
	public var offerId:Null<String> = null;
	public var basePlanId:String = '';
	public var offerTags:Array<String> = [];
	public var offerToken:String = '';
	public var pricingPhases:Array<IAPPricingPhase> = [];

	public function new():Void {}

	public static function fromJson(json:Dynamic):IAPSubscriptionOffer
	{
		final offer:IAPSubscriptionOffer = new IAPSubscriptionOffer();
		offer.offerId = json.offerId;
		offer.basePlanId = json.basePlanId;
		offer.offerTags = json.offerTags ?? [];
		offer.offerToken = json.offerToken;

		if (json.pricingPhases != null)
		{
			for (phaseJson in json.pricingPhases)
				offer.pricingPhases.push(IAPPricingPhase.fromJson(phaseJson));
		}

		return offer;
	}
}
