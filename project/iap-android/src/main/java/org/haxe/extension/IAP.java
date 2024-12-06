package org.haxe.extension;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.ProductDetails;
import org.haxe.extension.util.BillingManager;
import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class IAP extends Extension
{
	private static class UpdateListener implements BillingManager.BillingUpdatesListener
	{
		public void onBillingClientSetupFinished(Boolean success)
		{
			callback.call("onStarted", new Object[] { success });
		}

		public void onConsumeFinished(String token, BillingResult result)
		{
			final Purchase purchase = consumeInProgress.get(token);

			consumeInProgress.remove(token);

			if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
				callback.call("onConsume", new Object[] { purchase.getOriginalJson(), purchase.getSignature() });
			else
				callback.call("onFailedConsume", new Object[] { createErrorJson(result, purchase) });
		}

		public void onAcknowledgePurchaseFinished(String token, BillingResult result)
		{
			final Purchase purchase = acknowledgePurchaseInProgress.get(token);

			acknowledgePurchaseInProgress.remove(token);

			if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
				callback.call("onAcknowledgePurchase", new Object[] { purchase.getOriginalJson(), purchase.getSignature() });
			else
				callback.call("onFailedAcknowledgePurchase", new Object[] { createErrorJson(result, purchase) });
		}

		public void onPurchasesUpdated(List<Purchase> purchaseList, BillingResult result)
		{
			for (Purchase purchase : purchaseList) 
			{
				if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
				{
					if (purchase.getPurchaseState() == Purchase.PurchaseState.PURCHASED)
						callback.call("onPurchase", new Object[]{ purchase.getOriginalJson(), purchase.getSignature() });
				}
				else if (result.getResponseCode() == BillingClient.BillingResponseCode.USER_CANCELED)
					callback.call("onCanceledPurchase", new Object[]{ purchase.getOriginalJson(), purchase.getSignature() });
				else
					callback.call("onFailedPurchase", new Object[] { createErrorJson(result, purchase) });
			}
		}

		public void onQueryProductDetailsFinished(List<ProductDetails> productList, BillingResult result)
		{
			try
			{
				if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
				{
					JSONArray productsArray = new JSONArray();

					for (ProductDetails product : productList)
						productsArray.put(productDetailsToJson(product));

					JSONObject jsonResp = new JSONObject();
					jsonResp.put("products", productsArray);
					callback.call("onQueryProductDetailsFinished", new Object[] { jsonResp.toString() });
				}
				else
					callback.call("onQueryProductDetailsFinished", new Object[] { "Failure" });
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}

		public void onQueryPurchasesFinished(List<Purchase> purchaseList)
		{
			try
			{
				JSONArray purchasesArray = new JSONArray();

				for (Purchase purchase : purchaseList)
				{
					if (purchase.getPurchaseState() == Purchase.PurchaseState.PURCHASED)
					{
						JSONObject purchaseJson = new JSONObject();
						purchaseJson.put("originalJson", new JSONObject(purchase.getOriginalJson()));
						purchaseJson.put("signature", purchase.getSignature());
						purchasesArray.put(purchaseJson);
					}
				}

				JSONObject jsonResp = new JSONObject();
				jsonResp.put("purchases", purchasesArray);
				callback.call("onQueryPurchasesFinished", new Object[] { jsonResp.toString() });
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}

		public void onError(String errorMessage)
		{
			callback.call("onError", new Object[] { errorMessage });
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

				List<ProductDetails.SubscriptionOfferDetails> subscriptionOfferDetailsList = productDetails.getSubscriptionOfferDetails();

				if (subscriptionOfferDetailsList != null)
				{
					JSONArray offersArray = new JSONArray();

					for (ProductDetails.SubscriptionOfferDetails offerDetails : subscriptionOfferDetailsList)
					{
						JSONObject offerJson = new JSONObject();

						if (offerDetails.getOfferId() != null)
							offerJson.put("offerId", offerDetails.getOfferId());

						offerJson.put("basePlanId", offerDetails.getBasePlanId());
						offerJson.put("offerTags", new JSONArray(offerDetails.getOfferTags()));
						offerJson.put("offerToken", offerDetails.getOfferToken());

						JSONArray pricingPhases = new JSONArray();

						for (ProductDetails.PricingPhase pricingPhase : offerDetails.getPricingPhases().getPricingPhaseList())
						{
							JSONObject phaseJson = new JSONObject();
							phaseJson.put("billingCycleCount", pricingPhase.getBillingCycleCount());
							phaseJson.put("billingPeriod", pricingPhase.getBillingPeriod());
							phaseJson.put("formattedPrice", pricingPhase.getFormattedPrice());
							phaseJson.put("priceAmountMicros", pricingPhase.getPriceAmountMicros());
							phaseJson.put("priceCurrencyCode", pricingPhase.getPriceCurrencyCode());
							phaseJson.put("recurrenceMode", pricingPhase.getRecurrenceMode());
							pricingPhases.put(phaseJson);
						}

						offerJson.put("pricingPhases", pricingPhases);

						offersArray.put(offerJson);
					}

					resultObject.put("subscriptionOffers", offersArray);
				}
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

			return resultObject;
		}
	}

	private static String TAG = "InAppPurchase";
	private static HaxeObject callback = null;
	private static BillingManager billingManager = null;
	private static String publicKey = "";
	private static UpdateListener updateListener = null;
	private static Map<String, Purchase> consumeInProgress = new HashMap<String, Purchase>();
	private static Map<String, Purchase> acknowledgePurchaseInProgress = new HashMap<String, Purchase>();

	public static void init(String publicKey, HaxeObject callback)
	{
		IAP.callback = callback;
		IAP.publicKey = publicKey;

		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;

		updateListener = new UpdateListener();
		billingManager = new BillingManager(Extension.mainActivity, updateListener);
	}

	public static void purchase(final String productID)
	{
		Extension.mainActivity.runOnUiThread(new Runnable()
		{
			@Override
			public void run()
			{
				billingManager.initiatePurchaseFlow(productID);
			}
		});
	}

	public static void consume(final String purchaseJson, final String signature) 
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);

			consumeInProgress.put(purchase.getPurchaseToken(), purchase);

			billingManager.consumeAsync(purchase.getPurchaseToken());
		}
		catch (Exception e)
		{
			callback.call("onFailedConsume", new Object[] {});
		}
	}

	public static void acknowledgePurchase(final String purchaseJson, final String signature)
	{
		try
		{
			final Purchase purchase = new Purchase(purchaseJson, signature);

			if (!purchase.isAcknowledged())
			{
				acknowledgePurchaseInProgress.put(purchase.getPurchaseToken(), purchase);

				billingManager.acknowledgePurchase(purchase.getPurchaseToken());
			}
		}
		catch (Exception e)
		{
			callback.call("onFailedAcknowledgePurchase", new Object[] {});
		}
	}

	public static void queryProductDetails(String[] ids)
	{
		billingManager.queryProductDetailsAsync(Arrays.asList(ids));
	}

	public static void queryPurchases()
	{
		billingManager.queryPurchasesAsync();
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
}
