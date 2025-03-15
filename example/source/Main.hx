package;

class Main extends lime.app.Application
{
	private static final PUBLIC_KEY:String = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv2pAdZ0dPy0sr/75E7U4oSYzDLZ7/Vn8YcfR6SN7R60Ew6chHTzRDWxr2XKjgjs3DixwFgcd5YAEv4zWcQfZSSwrOdjycF/5TUAbbfESWAZgB9UDz0NLl5KXaf+HitTlyshAG";

	public function new():Void
	{
		super();

		iap.IAP.onSetup.add(function(success:Bool):Void
		{
			if (success)
				iap.IAP.queryProductDetails(['idk']);

			lime.utils.Log.info(success ? 'IAP Successfully initialized!' : 'IAP Initialization Failure!');
		});
		iap.IAP.onDebugLog.add(function(message:String):Void
		{
			lime.utils.Log.info(message);
		});

		#if android
		iap.IAP.onQueryPurchases.add(function(purchases:Array<iap.android.IAPPurchase>):Void
		{
			if (purchases != null && purchases.length > 0)
			{
				for (purchase in purchases)
				{
					lime.utils.Log.info("Purchase found: " + purchase.productId);
				}
			}
			else
			{
				lime.utils.Log.info("No purchases found.");
			}
		});
		#end

		iap.IAP.onQueryProductDetails.add(function(products:Array<iap.android.IAPProductDetails>):Void
		{
			if (products != null && products.length > 0)
			{
				for (product in products)
				{
					lime.utils.Log.info("Product Details found: " + product.title);
				}
			}
			else
			{
				lime.utils.Log.info("No products found.");
			}
		});
	}

	public override function onWindowCreate():Void
	{
		iap.IAP.init(#if android PUBLIC_KEY #end);
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
