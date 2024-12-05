package org.haxe.extension.util;

import android.app.Activity;
import android.util.Log;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.FeatureType;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.PurchasesResponseListener;
import com.android.billingclient.api.BillingFlowParams.ProductDetailsParams;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class BillingManager implements PurchasesUpdatedListener
{
	private static final String TAG = "BillingManager";
	private final BillingUpdatesListener mBillingUpdatesListener;
	private final Activity mActivity;
	private final List<Purchase> mPurchases = new ArrayList<Purchase>();

	private static BillingResult errorResult = BillingResult.newBuilder().setResponseCode(-1).setDebugMessage("ERROR").build();
	private BillingClient mBillingClient;
	private boolean mIsServiceConnected;
	private Set<String> mTokensToBeConsumed;
	private Set<String> mTokensToBeAcknowledged;
	private Map<String, ProductDetails> mProductDetailsMap = new HashMap<String, ProductDetails>();

	public static String BASE_64_ENCODED_PUBLIC_KEY = "";

	public interface BillingUpdatesListener
	{
		void onBillingClientSetupFinished(final Boolean success);
		void onQueryPurchasesFinished(List<Purchase> purchases);
		void onConsumeFinished(String token, BillingResult result);
		void onAcknowledgePurchaseFinished(String token, BillingResult result);
		void onPurchasesUpdated(List<Purchase> purchases, BillingResult result);
		void onQueryProductDetailsFinished(List<ProductDetails> productDetailsList, BillingResult result);
	}

	public BillingManager(Activity activity, final BillingUpdatesListener updatesListener)
	{
		Log.d(TAG, "BillingManager initialized.");

		mActivity = activity;

		mBillingUpdatesListener = updatesListener;

		mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();
		mBillingClient.startConnection(new BillingClientStateListener()
		{
			@Override
			public void onBillingSetupFinished(BillingResult billingResponse)
			{
				Log.d(TAG, "onBillingSetupFinished() responseCode: " + billingResponse.getResponseCode());

				if (billingResponse.getResponseCode() == BillingResponseCode.OK)
				{
					Log.d(TAG, "Billing client setup successful");

					mIsServiceConnected = true;

					mBillingUpdatesListener.onBillingClientSetupFinished(true);
				}
				else
				{
					Log.e(TAG, "Billing client setup failed");

					mIsServiceConnected = false;

					mBillingUpdatesListener.onBillingClientSetupFinished(false);
				}
			}

			@Override
			public void onBillingServiceDisconnected()
			{
				Log.d(TAG, "onBillingServiceDisconnected() called");

				mIsServiceConnected = false;

				mBillingUpdatesListener.onBillingClientSetupFinished(false);
			}
		});
	}

	public void destroy()
	{
		Log.d(TAG, "Destroying the billing manager.");

		if (mBillingClient != null && mBillingClient.isReady())
		{
			mBillingClient.endConnection();
			mBillingClient = null;
		}
	}

	public void initiatePurchaseFlow(final String productId)
	{
		Log.d(TAG, "Initiating purchase flow for Product: " + productId);

		final ProductDetails productDetail = mProductDetailsMap.get(productId);

		if (productDetail == null)
		{
			Log.d(TAG, "Product not cached, querying details for: " + productId);

			ArrayList<String> ids = new ArrayList<String>();
			ids.add(productId);
			queryProductDetailsAsync(ProductType.INAPP, ids);
		}
		else
		{
			Log.d(TAG, "Launching billing flow for: " + productId);

			List<ProductDetailsParams> productDetailsParamsList = new ArrayList<ProductDetailsParams>();
			productDetailsParamsList.add(ProductDetailsParams.newBuilder().setProductDetails(productDetail).build());
			mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
		}
	}

	public void queryProductDetailsAsync(final String itemType, final List<String> productList)
	{
		Log.d(TAG, "Querying Product details for itemType: " + itemType);

		final List<Product> newProductList = new ArrayList<Product>();

		for (String productId : productList)
			newProductList.add(Product.newBuilder().setProductId(productId).setProductType(itemType).build());

		Log.d(TAG, "Querying product details asynchronously.");

		mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(newProductList).build(), new ProductDetailsResponseListener()
		{
			@Override
			public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> productDetailsList)
			{
				Log.d(TAG, "Product details response received.");

				mBillingUpdatesListener.onQueryProductDetailsFinished(productDetailsList, billingResult);

				if (billingResult.getResponseCode() == BillingResponseCode.OK)
				{
					for (ProductDetails productDetails : productDetailsList)
					{
						mProductDetailsMap.put(productDetails.getProductId(), productDetails);

						initiatePurchaseFlow(productDetails.getProductId());

						break;
					}
				}
				else
				{
					Log.w(TAG, "Failed to retrieve Product details: " + billingResult.getDebugMessage());
				}
			}
		});
	}

	public void consumeAsync(final String purchaseToken)
	{
		Log.d(TAG, "consumeAsync() called with purchaseToken: " + purchaseToken);
		
		if (mTokensToBeConsumed == null)
		{
			Log.d(TAG, "mTokensToBeConsumed is null, initializing new HashSet");
			mTokensToBeConsumed = new HashSet<String>();
		}
		else if (mTokensToBeConsumed.contains(purchaseToken))
		{
			Log.d(TAG, "Purchase token already in mTokensToBeConsumed, returning");
			return;
		}

		mTokensToBeConsumed.add(purchaseToken);

		Log.d(TAG, "Consuming purchase token: " + purchaseToken);

		mBillingClient.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(purchaseToken).build(), new ConsumeResponseListener()
		{
			@Override
			public void onConsumeResponse(BillingResult billingResult, String purchaseToken)
			{
				mTokensToBeConsumed.remove(purchaseToken);

				Log.d(TAG, "Consume response received for token: " + purchaseToken + " with result: " + billingResult.getResponseCode());

				mBillingUpdatesListener.onConsumeFinished(purchaseToken, billingResult);
			}
		});
	}

	public void acknowledgePurchase(final String purchaseToken)
	{
		Log.d(TAG, "acknowledgePurchase() called with purchaseToken: " + purchaseToken);
	
		if (mTokensToBeAcknowledged == null)
		{
			Log.d(TAG, "mTokensToBeAcknowledged is null, initializing new HashSet");
			mTokensToBeAcknowledged = new HashSet<String>();
		}
		else if (mTokensToBeAcknowledged.contains(purchaseToken))
		{
			Log.d(TAG, "Purchase token already in mTokensToBeAcknowledged, returning");
			return;
		}

		mTokensToBeAcknowledged.add(purchaseToken);

		Log.d(TAG, "Acknowledging purchase token: " + purchaseToken);

		mBillingClient.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchaseToken).build(), new AcknowledgePurchaseResponseListener()
		{
			@Override
			public void onAcknowledgePurchaseResponse(BillingResult billingResult)
			{
				mTokensToBeAcknowledged.remove(purchaseToken);

				Log.d(TAG, "Acknowledge purchase response received for token: " + purchaseToken + " with result: " + billingResult.getResponseCode());

				mBillingUpdatesListener.onAcknowledgePurchaseFinished(purchaseToken, billingResult);
			}
		});
	}

	private void handlePurchase(Purchase purchase)
	{
		Log.d(TAG, "handlePurchase() called for purchase: " + purchase.getOriginalJson());

		if (!verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature()))
		{
			Log.e(TAG, "Invalid purchase signature for purchase: " + purchase.getOriginalJson());
			return;
		}

		mPurchases.add(purchase);

		Log.d(TAG, "Purchase added: " + purchase.getOriginalJson());
	}

	public void queryPurchasesAsync()
	{
		Log.d(TAG, "queryPurchasesAsync() called");

		Log.d(TAG, "Querying in-app purchases");

		mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build(), new PurchasesResponseListener()
		{
			@Override
			public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
			{
				Log.d(TAG, "In-app purchases query response received with result: " + billingResult.getResponseCode());

				onQueryPurchasesFinished(billingResult, purchases);
			}
		});

		if (mBillingClient.isFeatureSupported(FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingResponseCode.OK)
		{
			Log.d(TAG, "Querying subscription purchases");

			mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.SUBS).build(), new PurchasesResponseListener()
			{
				@Override
				public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
				{
					if (billingResult.getResponseCode() == BillingResponseCode.OK)
					{
						Log.d(TAG, "Subscription purchases query response received with result: " + billingResult.getResponseCode());

						onQueryPurchasesFinished(billingResult, purchases);
					}
					else
						Log.e(TAG, "Failed to query subscription purchases: " + billingResult.getDebugMessage());
				}
			});
		}
	}

	private boolean verifyValidSignature(String signedData, String signature)
	{
		try
		{
			Log.d(TAG, "Verifying purchase signature.");

			return Security.verifyPurchase(BASE_64_ENCODED_PUBLIC_KEY, signedData, signature);
		}
		catch (Exception e)
		{
			Log.e(TAG, "Error verifying signature: " + e.getMessage(), e);

			return false;
		}
	}

	@Override
	public void onPurchasesUpdated(BillingResult result, List<Purchase> purchases)
	{
		Log.d(TAG, "onPurchasesUpdated: ResponseCode=" + result.getResponseCode());

		if (result.getResponseCode() == BillingResponseCode.OK)
		{
			mPurchases.clear();

			for (Purchase purchase : purchases)
			{
				Log.d(TAG, "Processing purchase: " + purchase.getOrderId());
				handlePurchase(purchase);
			}

			mBillingUpdatesListener.onPurchasesUpdated(mPurchases, result);
		}
		else
		{
			Log.w(TAG, "Purchases update failed: " + result.getDebugMessage());
			mBillingUpdatesListener.onPurchasesUpdated(purchases, result);
		}
	}

	@Override
	private void onQueryPurchasesFinished(BillingResult result, List<Purchase> purchases)
	{
		Log.d(TAG, "onQueryPurchasesFinished() called with result: " + result.getResponseCode());

		if (mBillingClient == null || result.getResponseCode() != BillingResponseCode.OK)
		{
			Log.e(TAG, "Billing client setup failed or response code is not OK");
			return;
		}

		mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
	}
}
