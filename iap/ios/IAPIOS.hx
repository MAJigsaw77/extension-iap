package iap.ios;

@:buildXml('<include name="${haxelib:extension-iap}/project/iap-ios/Build.xml" />')
@:headerInclude('IAP.hpp')
class IAPIOS
{
	@:noCompletion
	private static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;

		initIAP(new IAPCallbacks());

		initialized = true;
	}

	public static function queryProductDetails(productIdentifiers:Array<String>):Void
	{
		if (!initialized)
			return;

		final rawProductsArray:cpp.RawPointer<cpp.ConstCharStar> = untyped __cpp__('new const char *[{0}]', productIdentifiers.length);

		for (i in 0...productIdentifiers.length)
			rawProductsArray[i] = cpp.ConstCharStar.fromString(productIdentifiers[i]);

		queryProductDetailsIAP(rawProductsArray, productIdentifiers.length);

		untyped __cpp__('delete[] {0}', rawProductsArray);
	}

	@:native('initIAP')
	extern public static function initIAP(callbacks:IAPCallbacks):Void;

	@:native('queryProductDetailsIAP')
	extern public static function queryProductDetailsIAP(productIdentifiers:cpp.RawPointer<cpp.ConstCharStar>, count:cpp.SizeT):Void;

	@:native('purchaseProductIAP')
	extern public static function purchaseProductIAP(productId:cpp.ConstCharStar):Void;

	@:native('restorePurchasesIAP')
	extern public static function restorePurchasesIAP():Void;
}

@:dox(hide)
@:buildXml('<include name="${haxelib:extension-iap}/project/iap-ios/Build.xml" />')
@:include('IAP.hpp')
@:unreflective
@:structAccess
@:native('IAPCallbacks')
extern class IAPCallbacks
{
	function new():Void;

	var onBillingClientSetup:cpp.Callable<(success:Bool) -> Void>;
	var onBillingClientDebugLog:cpp.Callable<(message:cpp.ConstCharStar) -> Void>;
	var onQueryProductDetails:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
	var onPurchaseCompleted:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
	var onRestoreCompleted:cpp.Callable<(data:cpp.ConstCharStar) -> Void>;
}


