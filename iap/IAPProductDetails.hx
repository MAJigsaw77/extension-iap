package iap;

class IAPProductDetails
{
	public var productID(default, null):String;
	public var type(default, null):String;
	public var localizedPrice(default, null):String;
	public var localizedTitle(default, null):String;
	public var localizedDescription(default, null):String;
	public var priceAmountMicros(default, null):Float;
	public var priceCurrencyCode(default, null):String;
	public var price(default, null):Float;

	public function new(dynObj:Dynamic)
	{
		productID = Reflect.hasField(dynObj, 'productId') ? Reflect.field(dynObj, 'productId') : Reflect.field(dynObj, 'productID');

		type = cast Reflect.field(dynObj, 'type');

		#if ios
		localizedPrice = cast Reflect.field(dynObj, 'localizedPrice');
		localizedDescription = cast Reflect.field(dynObj, 'localizedDescription');
		localizedTitle = cast Reflect.field(dynObj, 'localizedTitle');
		priceAmountMicros = cast Reflect.field(dynObj, 'priceAmountMicros');
		priceCurrencyCode = cast Reflect.field(dynObj, 'priceCurrencyCode');
		#else
		localizedPrice = cast Reflect.field(dynObj, 'price');
		localizedDescription = cast Reflect.field(dynObj, 'description');
		localizedTitle = cast Reflect.field(dynObj, 'title');
		priceAmountMicros = cast Reflect.field(dynObj, 'price_amount_micros');
		priceCurrencyCode = cast Reflect.field(dynObj, 'price_currency_code');
		#end

		price = priceAmountMicros / 1e6;
	}
}
