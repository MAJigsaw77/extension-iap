package iap.ios;

class IAPPurchase
{
	public final transactionId:String;
	public final productIdentifier:String;
	public final transactionDate:Int;
	public final transactionState:Int;

	public function new(json:Dynamic):Void
	{
		transactionId = json.transactionId;
		productIdentifier = json.productIdentifier;
		transactionDate = json.transactionDate;
		transactionState = json.transactionState;
	}
}
