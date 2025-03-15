package org.haxe.extension;

import com.android.billingclient.api.*;
import org.haxe.extension.util.*;
import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;
import org.json.*;
import java.util.*;

public class IAP extends Extension
{
	private static final Map<String, Purchase> consumeInProgress = Collections.synchronizedMap(new HashMap<>());
	private static final Map<String, Purchase> acknowledgePurchaseInProgress = Collections.synchronizedMap(new HashMap<>());

	private static HaxeObject callback = null;
	private static BillingManager billingManager = null;

	public static void init(String publicKey, HaxeObject callback)
	{
		IAP.callback = callback;
		IAP.billingManager = new BillingManager(mainActivity, new IAPUpdateListener(), publicKey);
	}

	public static void purchase(final String productID)
	{
		if (billingManager != null)
			mainActivity.runOnUiThread(() -> billingManager.initiatePurchaseFlow(productID));
	}

	public static void consume(final String purchaseJson, final String signature)
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);

			if (billingManager != null && !consumeInProgress.containsKey(purchase.getPurchaseToken()))
			{
				consumeInProgress.put(purchase.getPurchaseToken(), purchase);

				billingManager.consume(purchase.getPurchaseToken());
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}

	public static void acknowledgePurchase(final String purchaseJson, final String signature)
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);

			if (!purchase.isAcknowledged() && (billingManager != null && !acknowledgePurchaseInProgress.containsKey(purchase.getPurchaseToken())))
			{
				acknowledgePurchaseInProgress.put(purchase.getPurchaseToken(), purchase);

				billingManager.acknowledgePurchase(purchase.getPurchaseToken());
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}

	public static void queryProductDetails(String[] ids)
	{
		if (billingManager != null)
			billingManager.queryProductDetails(Arrays.asList(ids));
	}

	public static void queryPurchases()
	{
		if (billingManager != null)
			billingManager.queryPurchases();
	}

	@Override
	public void onDestroy()
	{
		if (billingManager != null)
		{
			billingManager.destroy();
			billingManager = null;
		}
	}

	private static class IAPUpdateListener implements BillingManager.BillingUpdatesListener
	{
		public void onBillingClientSetup(Boolean success)
		{
			if (callback != null)
				callback.call("onSetup", new Object[] { success });
		}

		public void onBillingClientDebugLog(String message)
		{
			if (callback != null)
				callback.call("onDebugLog", new Object[] { message });
		}

		public void onQueryPurchases(List<Purchase> inAppPurchases)
		{
			if (callback != null)
			{
				try
				{
					JSONArray purchasesArray = new JSONArray();

					if (inAppPurchases != null)
					{
						for (Purchase purchase : inAppPurchases)
						{
							if (purchase.getPurchaseState() == Purchase.PurchaseState.PURCHASED)
							{
								JSONObject purchaseJson = new JSONObject();
								purchaseJson.put("originalJson", new JSONObject(purchase.getOriginalJson()));
								purchaseJson.put("signature", purchase.getSignature());
								purchasesArray.put(purchaseJson);
							}
						}
					}

					JSONObject jsonResp = new JSONObject();
					jsonResp.put("purchases", purchasesArray);
					callback.call("onQueryPurchases", new Object[] { jsonResp.toString() });
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
			}
		}

		public void onQueryProductDetails(List<ProductDetails> productDetailsList, BillingResult result)
		{
			if (callback != null)
			{
				try
				{
					JSONArray productsArray = new JSONArray();

					if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
					{
						if (productDetailsList != null)
						{
							for (ProductDetails product : productDetailsList)
								productsArray.put(productDetailsToJson(product));
						}
					}

					JSONObject jsonResp = new JSONObject();
					jsonResp.put("products", productsArray);
					callback.call("onQueryProductDetails", new Object[] { jsonResp.toString() });
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
			}
		}

		public void onConsume(String token, BillingResult result)
		{
			final Purchase purchase = consumeInProgress.get(token);

			consumeInProgress.remove(token);

			if (callback != null)
			{
				if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
					callback.call("onConsume", new Object[] { purchase.getOriginalJson(), purchase.getSignature() });
				else
					callback.call("onFailedConsume", new Object[] { createErrorJson(result, purchase) });
			}
		}

		public void onAcknowledgePurchase(String token, BillingResult result)
		{
			final Purchase purchase = acknowledgePurchaseInProgress.get(token);

			acknowledgePurchaseInProgress.remove(token);

			if (callback != null)
			{
				if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
					callback.call("onAcknowledgePurchase", new Object[] { purchase.getOriginalJson(), purchase.getSignature() });
				else
					callback.call("onFailedAcknowledgePurchase", new Object[] { createErrorJson(result, purchase) });
			}
		}

		private JSONObject createErrorJson(BillingResult result, Purchase purchase)
		{
			JSONObject errorJson = new JSONObject();

			try
			{
				errorJson.put("result", result.getResponseCode());

				JSONObject purchaseJson = new JSONObject();
				purchaseJson.put("originalJson", new JSONObject(purchase.getOriginalJson()));
				purchaseJson.put("signature", purchase.getSignature());
				errorJson.put("purchase", purchaseJson);
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

			return errorJson;
		}

		public JSONObject productDetailsToJson(ProductDetails productDetails)
		{
			JSONObject resultObject = new JSONObject();

			try
			{
				resultObject.put("productId", productDetails.getProductId());
				resultObject.put("productType", productDetails.getProductType());
				resultObject.put("title", productDetails.getTitle());
				resultObject.put("name", productDetails.getName());
				resultObject.put("description", productDetails.getDescription());

				ProductDetails.OneTimePurchaseOfferDetails purchaseOfferDetails = productDetails.getOneTimePurchaseOfferDetails();

				if (purchaseOfferDetails != null)
				{
					resultObject.put("formattedPrice", purchaseOfferDetails.getFormattedPrice());
					resultObject.put("priceAmountMicros", purchaseOfferDetails.getPriceAmountMicros());
					resultObject.put("priceCurrencyCode", purchaseOfferDetails.getPriceCurrencyCode());
				}
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

			return resultObject;
		}
	}
}
