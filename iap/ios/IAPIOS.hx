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

		initIAP();

		initialized = true;
	}

	public static function fetchProducts(productIdentifiers:Array<String>):Void
	{
		if (!initialized)
			return;

		final rawProductsArray:cpp.RawPointer<cpp.ConstCharStar> = untyped __cpp__('new const char *[{0}]', productIdentifiers.length);

		for (i in 0...productIdentifiers.length)
			rawProductsArray[i] = cpp.ConstCharStar.fromString(productIdentifiers[i]);

		fetchProductsIAP(rawProductsArray, productIdentifiers.length);

		untyped __cpp__('delete[] {0}', rawProductsArray);
	}

	@:native('initIAP')
	extern public static function initIAP():Void;

	@:native('fetchProductsIAP')
	extern public static function fetchProductsIAP(productIdentifiers:cpp.RawPointer<cpp.ConstCharStar>, count:cpp.SizeT):Void;
}
