package iap.ios;

import iap.ios.IAPDownload;

class IAPPurchase
{
	public final transactionId:String;
	public final productIdentifier:String;
	public final transactionDate:Int;
	public final transactionState:Int;

	public var downloads(default, null):Array<IAPDownload> = [];

	public function new(json:Dynamic):Void
	{
		transactionId = json.transactionId;
		productIdentifier = json.productIdentifier;
		transactionDate = json.transactionDate;
		transactionState = json.transactionState;

		if (json.downloads != null)
		{
			for (downloadJson in (json.downloads : Array<Dynamic>))
				downloads.push(new IAPDownload(downloadJson));
		}
	}
}
