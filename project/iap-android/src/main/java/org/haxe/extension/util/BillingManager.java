package org.haxe.extension.iap.util;

import android.app.Activity;
import android.util.Log;
import com.android.billingclient.api.*;
import java.util.ArrayList;
import java.util.HashMap;
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
	private int mBillingClientResponseCode = -1;
	private Map<String, ProductDetails> mSkuDetailsMap = new HashMap<String, ProductDetails>();

	public static String BASE_64_ENCODED_PUBLIC_KEY = "";

	public interface BillingUpdatesListener
	{
		void onBillingClientSetupFinished(final Boolean success);
		void onQueryPurchasesFinished(List<Purchase> purchases);
		void onConsumeFinished(String token, BillingResult result);
		void onAcknowledgePurchaseFinished(String token, BillingResult result);
		void onPurchasesUpdated(List<Purchase> purchases, BillingResult result);
		void onQueryProductDetailsFinished(List<ProductDetails> skuDetailsList, BillingResult result);
	}

	public BillingManager(Activity activity, final BillingUpdatesListener updatesListener)
	{
		Log.d(TAG, "BillingManager initialized.");
		mActivity = activity;
		mBillingUpdatesListener = updatesListener;
		mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();
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

	public void initiatePurchaseFlow(final String skuId)
	{
		Log.d(TAG, "Initiating purchase flow for SKU: " + skuId);
		final ProductDetails skuDetail = mSkuDetailsMap.get(skuId);

		if (skuDetail == null)
		{
			Log.d(TAG, "SKU not cached, querying details for: " + skuId);
			ArrayList<String> ids = new ArrayList<String>();
			ids.add(skuId);
			querySkuDetailsAsync(ProductType.INAPP, ids);
		}
		else
		{
			executeServiceRequest(new Runnable()
			{
				@Override
				public void run()
				{
					Log.d(TAG, "Launching billing flow for: " + skuId);
					List<ProductDetailsParams> productDetailsParamsList = new ArrayList<ProductDetailsParams>();
					productDetailsParamsList.add(ProductDetailsParams.newBuilder().setProductDetails(skuDetail).build());
					mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
				}
			}, new Runnable()
			{
				@Override
				public void run()
				{
					Log.e(TAG, "Failed to launch billing flow.");
					mBillingUpdatesListener.onPurchasesUpdated(null, errorResult);
				}
			});
		}
	}

	public void querySkuDetailsAsync(final String itemType, final List<String> skuList)
	{
		Log.d(TAG, "Querying SKU details for itemType: " + itemType);

		final List<Product> productList = new ArrayList<Product>();

		for (String productId : skuList)
			productList.add(Product.newBuilder().setProductId(productId).setProductType(itemType).build());

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				Log.d(TAG, "Querying product details asynchronously.");
				mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(productList).build(), new ProductDetailsResponseListener()
				{
					@Override
					public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> skuDetailsList)
					{
						Log.d(TAG, "Product details response received.");
						mBillingUpdatesListener.onQueryProductDetailsFinished(skuDetailsList, billingResult);

						if (billingResult.getResponseCode() == BillingResponseCode.OK)
						{
							for (ProductDetails skuDetails : skuDetailsList)
							{
								mSkuDetailsMap.put(skuDetails.getProductId(), skuDetails);
								initiatePurchaseFlow(skuDetails.getProductId());
								break;
							}
						}
						else
						{
							Log.w(TAG, "Failed to retrieve SKU details: " + billingResult.getDebugMessage());
						}
					}
				});
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
				Log.e(TAG, "Failed to query SKU details.");
				mBillingUpdatesListener.onQueryProductDetailsFinished(null, errorResult);
			}
		});
	}

	public void consumeAsync(final String purchaseToken)
	{
		Log.d(TAG, "consumeAsync() called with purchaseToken: " + purchaseToken);
		
		if (mTokensToBeConsumed == null)
		{
			Log.d(TAG, "mTokensToBeConsumed is null, initializing new HashSet");
			mTokensToBeConsumed = new HashSet<>();
		}
		else if (mTokensToBeConsumed.contains(purchaseToken))
		{
			Log.d(TAG, "Purchase token already in mTokensToBeConsumed, returning");
			return;
		}

		mTokensToBeConsumed.add(purchaseToken);

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
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
		}, new Runnable()
		{
			@Override
			public void run()
			{
				Log.e(TAG, "Error while consuming purchase token: " + purchaseToken);
				mBillingUpdatesListener.onConsumeFinished(null, errorResult);
			}
		});
	}

	public void acknowledgePurchase(final String purchaseToken)
	{
		Log.d(TAG, "acknowledgePurchase() called with purchaseToken: " + purchaseToken);
	
		if (mTokensToBeAcknowledged == null)
		{
			Log.d(TAG, "mTokensToBeAcknowledged is null, initializing new HashSet");
			mTokensToBeAcknowledged = new HashSet<>();
		}
		else if (mTokensToBeAcknowledged.contains(purchaseToken))
		{
			Log.d(TAG, "Purchase token already in mTokensToBeAcknowledged, returning");
			return;
		}

		mTokensToBeAcknowledged.add(purchaseToken);

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
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
		}, new Runnable()
		{
			@Override
			public void run()
			{
				Log.e(TAG, "Error while acknowledging purchase token: " + purchaseToken);
				mBillingUpdatesListener.onAcknowledgePurchaseFinished(null, errorResult);
			}
		});
	}

	public int getBillingClientResponseCode()
	{
		Log.d(TAG, "getBillingClientResponseCode() called");
		return mBillingClientResponseCode;
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
	
	private void onQueryPurchasesFinished(BillingResult result, List<Purchase> purchases )
	{
		Log.d(TAG, "onQueryPurchasesFinished() called with result: " + result.getResponseCode());

		if (mBillingClient == null || result.getResponseCode() != BillingResponseCode.OK)
		{
			Log.e(TAG, "Billing client setup failed or response code is not OK");
			mBillingUpdatesListener.onBillingClientSetupFinished(false);
			return;
		}

		mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
		mBillingUpdatesListener.onBillingClientSetupFinished(true);
	}

	public boolean areSubscriptionsSupported()
	{
		boolean supported = mBillingClient.isFeatureSupported(FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingResponseCode.OK;
		Log.d(TAG, "areSubscriptionsSupported() called, result: " + supported);
		return supported;
	}

	public void queryPurchases()
	{
		Log.d(TAG, "queryPurchases() called");

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				Log.d(TAG, "Querying in-app purchases");

				PurchasesResult purchasesResult = mBillingClient.queryPurchases(SkuType.INAPP);

				mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build(), new PurchasesResponseListener()
				{
					public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
					{
						Log.d(TAG, "Query purchases response received with result: " + billingResult.getResponseCode());

						onQueryPurchasesFinished(billingResult, purchases);
					}
				});

				if (areSubscriptionsSupported())
				{
					Log.d(TAG, "Querying subscription purchases");

					PurchasesResult subscriptionResult = mBillingClient.queryPurchases(SkuType.SUBS);

					if (subscriptionResult.getResponseCode() == BillingResponseCode.OK)
					{
						purchasesResult.getPurchasesList().addAll(subscriptionResult.getPurchasesList());
						Log.d(TAG, "Subscription purchases added");
					}
				}
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
				Log.e(TAG, "Error while querying purchases");

				mBillingUpdatesListener.onBillingClientSetupFinished(false);
			}
		});
	}
	
	public void startServiceConnection(final Runnable executeOnSuccess, final Runnable executeOnError)
	{
		mBillingClient.startConnection(new BillingClientStateListener()
		{
			@Override
			public void onBillingSetupFinished(BillingResult billingResponse)
			{
				mBillingClientResponseCode = billingResponse.getResponseCode();

				Log.d(TAG, "onBillingSetupFinished() responseCode: " + billingResponse.getResponseCode());

				if (billingResponse.getResponseCode() == BillingResponseCode.OK)
				{
					mIsServiceConnected = true;

					if (executeOnSuccess != null)
					{
						Log.d(TAG, "Billing client setup successful, executing onSuccess");
						executeOnSuccess.run();
					}
				}
				else
				{
					if (executeOnError != null)
					{
						Log.e(TAG, "Billing client setup failed, executing onError");
						executeOnError.run();
					}

					mIsServiceConnected = false;
				}
			}

			@Override
			public void onBillingServiceDisconnected()
			{
				Log.d(TAG, "onBillingServiceDisconnected() called");

				mIsServiceConnected = false;
			}
		});
	}

	private void executeServiceRequest(Runnable runnable, Runnable onError)
	{
		if (mIsServiceConnected)
		{
			Log.d(TAG, "Service connected, executing request");

			runnable.run();
		}
		else
		{
			Log.e(TAG, "Service not connected, starting service connection");

			startServiceConnection(runnable, onError);
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
}
