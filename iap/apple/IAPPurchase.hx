package iap.apple;

class IAPPurchase
{
	public final transactionIdentifier:String;
	public final productIdentifier:String;
	public final transactionDate:Int;
	public final transactionState:Int;

	public function new(json:Dynamic):Void
	{
		transactionIdentifier = json.transactionIdentifier;
		productIdentifier = json.productIdentifier;
		transactionDate = json.transactionDate;
		transactionState = json.transactionState;
	}
}
