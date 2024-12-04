package org.haxe.extension;

import android.util.Log;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.Purchase.PurchaseState;
import com.android.billingclient.api.ProductDetails;
import org.haxe.extension.util.BillingManager;
import org.haxe.extension.util.BillingManager.BillingUpdatesListener;
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
	private static class UpdateListener implements BillingUpdatesListener
	{
		@Override
		public void onBillingClientSetupFinished(final Boolean success)
		{
			callback.call("onStarted", new Object[] { success });
		}

		@Override
		public void onConsumeFinished(String token, final BillingResult result)
		{
			final Purchase purchase = consumeInProgress.get(token);

			consumeInProgress.remove(token);

			if (result.getResponseCode() == BillingResponseCode.OK)
				callback.call("onConsume", new Object[] { purchase.getOriginalJson() });
			else
				callback.call("onFailedConsume", new Object[] { createErrorJson(result, purchase) });
		}

		@Override
		public void onAcknowledgePurchaseFinished(String token, final BillingResult result)
		{
			final Purchase purchase = acknowledgePurchaseInProgress.get(token);

			acknowledgePurchaseInProgress.remove(token);

			if (result.getResponseCode() == BillingResponseCode.OK)
				callback.call("onAcknowledgePurchase", new Object[] { purchase.getOriginalJson() });
			else
				callback.call("onFailedAcknowledgePurchase", new Object[] { createErrorJson(result, purchase) });
		}

		@Override
		public void onPurchasesUpdated(List<Purchase> purchaseList, final BillingResult result)
		{
			if (result.getResponseCode() == BillingResponseCode.OK)
			{
				for (Purchase purchase : purchaseList) 
				{
					if (purchase.getPurchaseState() == PurchaseState.PURCHASED)
						callback.call("onPurchase", new Object[]{ purchase.getOriginalJson(), purchase.getSignature() });
				}
			}
			else
			{
				if (result.getResponseCode() ==  BillingResponseCode.USER_CANCELED)
					callback.call("onCanceledPurchase", new Object[] { "Canceled" });
				else
					callback.call("onFailedPurchase", new Object[] { createFailureJson(result) });
			}
		}

		@Override
		public void onQuerySkuDetailsFinished(List<ProductDetails> skuList, final BillingResult result)
		{
			if (result.getResponseCode() == BillingResponseCode.OK)
			{
				JSONArray productsArray = new JSONArray();

				for (ProductDetails sku : skuList)
					productsArray.put(productDetailsToJson(sku));

				JSONObject jsonResp = new JSONObject();

				try
				{
					jsonResp.put("products", productsArray);
				}
				catch (JSONException e)
				{
					e.printStackTrace();
				}

				callback.call("onRequestProductDataComplete", new Object[] { jsonResp.toString() });
			}
			else
				callback.call("onRequestProductDataComplete", new Object[] { "Failure" });
		}

		@Override
		public void onQueryPurchasesFinished(List<Purchase> purchaseList)
		{
			JSONArray purchasesArray = new JSONArray();

			for (Purchase purchase : purchaseList)
			{
				if (purchase.getPurchaseState() == PurchaseState.PURCHASED)
				{
					for(String sku : purchase.getSkus())
					{
						JSONObject purchaseJson = new JSONObject();

						try {
							purchaseJson.put("key", sku);
							purchaseJson.put("value", new JSONObject(purchase.getOriginalJson()));
							purchaseJson.put("itemType", "");
							purchaseJson.put("signature", purchase.getSignature());
						} catch (JSONException e) {
							e.printStackTrace();
						}

						purchasesArray.put(purchaseJson);
					}
				}
			}

			JSONObject jsonResp = new JSONObject();

			try {
				jsonResp.put("purchases", purchasesArray);
			} catch (JSONException e) {
				e.printStackTrace();
			}

			callback.call("onQueryInventoryComplete", new Object[] { jsonResp.toString() });
		}

		private JSONObject createErrorJson(BillingResult result, Purchase purchase)
		{
			JSONObject errorJson = new JSONObject();

			try {
				errorJson.put("result", result.getResponseCode());
				errorJson.put("product", new JSONObject(purchase.getOriginalJson()));
			} catch (JSONException e) {
				e.printStackTrace();
			}

			return errorJson;
		}

		private JSONObject createFailureJson(BillingResult result)
		{
			JSONObject failureJson = new JSONObject();

			try {
				failureJson.put("result", new JSONObject().put("message", result.getResponseCode()));
			} catch (JSONException e) {
				e.printStackTrace();
			}

			return failureJson;
		}

		public JSONObject productDetailsToJson(ProductDetails productDetails)
		{
			JSONObject resultObject = new JSONObject();

			try
			{
				resultObject.put("productId", productDetails.getProductId());
				resultObject.put("type", productDetails.getProductType());
				resultObject.put("title", productDetails.getTitle());
				resultObject.put("name", productDetails.getName());
				resultObject.put("description", productDetails.getDescription());

				ProductDetails.OneTimePurchaseOfferDetails purchaseOfferDetails = productDetails.getOneTimePurchaseOfferDetails();

				if (purchaseOfferDetails != null)
				{
					resultObject.put("price", purchaseOfferDetails.getFormattedPrice());
					resultObject.put("price_amount_micros", purchaseOfferDetails.getPriceAmountMicros());
					resultObject.put("price_currency_code", purchaseOfferDetails.getPriceCurrencyCode());
				}

				List<ProductDetails.SubscriptionOfferDetails> subscriptionOfferDetailsList = productDetails.getSubscriptionOfferDetails();

				if (subscriptionOfferDetailsList != null)
				{
					JSONArray offersArray = new JSONArray();

					for (ProductDetails.SubscriptionOfferDetails offerDetails : subscriptionOfferDetailsList)
					{
						JSONObject offerJson = new JSONObject();

						if(offerDetails.getOfferId() != null)
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
			catch (JSONException e)
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
		setPublicKey(publicKey);

		IAP.callback = callback;

		updateListener = new UpdateListener();
		billingManager = new BillingManager(Extension.mainActivity, updateListener);
	}

	public static void purchase(final String productID, final String devPayload)
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

	public static void acknowledgePurchase (final String purchaseJson, final String signature)
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

	public static void querySkuDetails(String[] ids)
	{
		billingManager.querySkuDetailsAsync(ProductType.INAPP, Arrays.asList(ids));
	}

	public static void queryInventory()
	{
		billingManager.queryPurchases();
	}

	public static void setPublicKey(String s)
	{
		publicKey = s;

		BillingManager.BASE_64_ENCODED_PUBLIC_KEY = publicKey;
	}

	public static String getPublicKey()
	{
		return publicKey;
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
