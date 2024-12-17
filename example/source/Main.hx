package;

class Main extends lime.app.Application
{
	private static final PUBLIC_KEY:String = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv2pAdZ0dPy0sr/75E7U4oSYzDLZ7/Vn8YcfR6SN7R60Ew6chHTzRDWxr2XKjgjs3DixwFgcd5YAEv4zWcQfZSSwrOdjycF/5TUAbbfESWAZgB9UDz0NLl5KXaf+HitTlyshAG";

	public function new():Void
	{
		super();

		#if android
		iap.IAP.onSetup.add(function(success:Bool):Void
		{
			if (success)
			{
				iap.IAP.queryInAppProductDetailsAsync(['gold_x_1k', 'gold_x_5k', 'gold_x_10k']);
				iap.IAP.querySubsProductDetailsAsync(['testsubs']);
			}

			#if android
			android.widget.Toast.makeText(success ? 'IAP Successfully initialized!' : 'IAP Initialization Failure!', android.widget.Toast.LENGTH_SHORT);
			#else
			lime.utils.Log.info(success ? 'IAP Successfully initialized!' : 'IAP Initialization Failure!');
			#end
		});
		iap.IAP.onDebugLog.add(function(message:String):Void
		{
			#if android
			android.widget.Toast.makeText(message, android.widget.Toast.LENGTH_SHORT);
			#else
			lime.utils.Log.info(message);
			#end
		});
		iap.IAP.onQueryInAppPurchases.add(function(purchases:Array<iap.android.IAPPurchase>):Void
		{
			if (purchases != null && purchases.length > 0)
			{
				for (purchase in purchases)
				{
					#if android
					android.widget.Toast.makeText('Purchase found: ${purchase.productId}', android.widget.Toast.LENGTH_SHORT);
					#else
					lime.utils.Log.info("Purchase found: " + purchase.productId);
					#end
				}
			}
			else
			{
				#if android
				android.widget.Toast.makeText("No inapp purchases found.", android.widget.Toast.LENGTH_SHORT);
				#else
				lime.utils.Log.info("No inapp purchases found.");
				#end
			}
		});
		iap.IAP.onQuerySubsPurchases.add(function(purchases:Array<iap.android.IAPPurchase>):Void
		{
			if (purchases != null && purchases.length > 0)
			{
				for (purchase in purchases)
				{
					#if android
					android.widget.Toast.makeText('Purchase found: ${purchase.productId}', android.widget.Toast.LENGTH_SHORT);
					#else
					lime.utils.Log.info("Purchase found: " + purchase.productId);
					#end
				}
			}
			else
			{
				#if android
				android.widget.Toast.makeText("No subs purchases found.", android.widget.Toast.LENGTH_SHORT);
				#else
				lime.utils.Log.info("No subs purchases found.");
				#end
			}
		});
		iap.IAP.onQueryInAppProductDetails.add(function(products:Array<iap.android.IAPProductDetails>):Void
		{
			if (products != null && products.length > 0)
			{
				for (product in products)
				{
					#if android
					android.widget.Toast.makeText('Product Details found: ${product.title}', android.widget.Toast.LENGTH_SHORT);
					#else
					lime.utils.Log.info("Product Details found: " + product.title);
					#end
				}
			}
			else
			{
				#if android
				android.widget.Toast.makeText("No inapp products found.", android.widget.Toast.LENGTH_SHORT);
				#else
				lime.utils.Log.info("No inapp products found.");
				#end
			}
		});
		iap.IAP.onQuerySubsProductDetails.add(function(products:Array<iap.android.IAPProductDetails>):Void
		{
			if (products != null && products.length > 0)
			{
				for (product in products)
				{
					#if android
					android.widget.Toast.makeText('Product Details found: ${product.title}', android.widget.Toast.LENGTH_SHORT);
					#else
					lime.utils.Log.info("Product Details found: " + product.title);
					#end
				}
			}
			else
			{
				#if android
				android.widget.Toast.makeText("No subs products found.", android.widget.Toast.LENGTH_SHORT);
				#else
				lime.utils.Log.info("No subs products found.");
				#end
			}
		});
		#end
	}

	public override function onWindowCreate():Void
	{
		#if android
		iap.IAP.init(PUBLIC_KEY);

		// iap.IAP.queryInAppPurchasesAsync();
		// iap.IAP.querySubsPurchasesAsync();

		// iap.IAP.queryInAppProductDetailsAsync(['gold_x_1k', 'gold_x_5k', 'gold_x_10k']);
		// iap.IAP.querySubsProductDetailsAsync(['testsubs']);
		#elseif ios
		iap.IAP.init();
		#end
	}

	public override function render(context:lime.graphics.RenderContext):Void
	{
		switch (context.type)
		{
			case CAIRO:
				context.cairo.setSourceRGB(0.75, 1, 0);
				context.cairo.paint();
			case CANVAS:
				context.canvas2D.fillStyle = '#BFFF00';
				context.canvas2D.fillRect(0, 0, window.width, window.height);
			case DOM:
				context.dom.style.backgroundColor = '#BFFF00';
			case FLASH:
				context.flash.graphics.beginFill(0xBFFF00);
				context.flash.graphics.drawRect(0, 0, window.width, window.height);
			case OPENGL | OPENGLES | WEBGL:
				context.webgl.clearColor(0.75, 1, 0, 1);
				context.webgl.clear(context.webgl.COLOR_BUFFER_BIT);
			default:
		}
	}
}
