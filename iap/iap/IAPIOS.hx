package iap.ios;

@:buildXml('<include name="${haxelib:extension-admob}/project/admob-ios/Build.xml" />')
@:headerInclude('IAP.hpp')
class IAPIOS
{
	@:noCompletion
	private static var initialized:Bool = false;

	/**
	 * Initializes the IAP extension.
	 */
	public static function init():Void
	{
		if (initialized)
			return;

		initIAP();

		initialized = true;
	}

	@:native('initIAP')
	extern public static function initIAP():Void;
}
