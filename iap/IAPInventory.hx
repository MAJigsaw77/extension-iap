package iap;

class IAPInventory
{
	public var productDetailsMap(default, null):Map<String, ProductDetails> = [];
	public var purchaseMap(default, null):Map<String, Purchase> = [];

	public function new(?dynObj:Dynamic):Void
	{
		productDetailsMap = [];
		purchaseMap = [];

		if (dynObj != null)
		{
			final dynDescriptions:Array<Dynamic> = Reflect.field(dynObj, 'descriptions');

			if (dynDescriptions != null)
			{
				for (dynItm in dynDescriptions)
					productDetailsMap.set(cast Reflect.field(dynItm, 'key'), new ProductDetails(Reflect.field(dynItm, 'value')));
			}

			final dynPurchases:Array<Dynamic> = Reflect.field(dynObj, 'purchases');

			if (dynPurchases != null)
			{
				for (dynItm in dynPurchases)
				{
					purchaseMap.set(cast Reflect.field(dynItm, 'key'),
						new Purchase(Reflect.field(dynItm, 'value'), Reflect.field(dynItm, 'itemType'), Reflect.field(dynItm, 'signature')));
				}
			}
		}
	}
}
