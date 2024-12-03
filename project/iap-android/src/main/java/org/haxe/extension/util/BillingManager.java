package org.haxe.extension.iap.util;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.FeatureType;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryProductDetailsParams.Product;
import com.android.billingclient.api.QueryPurchaseHistoryParams;
import com.android.billingclient.api.QueryPurchasesParams;
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
	public static final int BILLING_MANAGER_NOT_INITIALIZED  = -1;

	private final BillingUpdatesListener mBillingUpdatesListener;
	private final Activity mActivity;
	private final List<Purchase> mPurchases = new ArrayList<Purchase>();

	public static String BASE_64_ENCODED_PUBLIC_KEY = "CONSTRUCT_YOUR_KEY_AND_PLACE_IT_HERE";

	private static BillingResult errorResult = BillingResult.newBuilder().setResponseCode(BILLING_MANAGER_NOT_INITIALIZED).setDebugMessage("ERROR").build();
	private BillingClient mBillingClient;
	private boolean mIsServiceConnected;
	private Set<String> mTokensToBeConsumed;
	private Set<String> mTokensToBeAcknowledged;
	private int mBillingClientResponseCode = BILLING_MANAGER_NOT_INITIALIZED;
	private Map<String, ProductDetails> mSkuDetailsMap = new HashMap<>();

	public interface BillingUpdatesListener
	{
		void onBillingClientSetupFinished(final Boolean success);
		void onQueryPurchasesFinished(List<Purchase> purchases);
		void onConsumeFinished(String token, BillingResult result);
		void onAcknowledgePurchaseFinished(String token, BillingResult result);
		void onPurchasesUpdated(List<Purchase> purchases, BillingResult result);
		void onQuerySkuDetailsFinished(List<ProductDetails> skuDetailsList, BillingResult result);
	}

	public interface ServiceConnectedListener
	{
		void onServiceConnected(BillingResult result);
	}

	public BillingManager(Activity activity, final BillingUpdatesListener updatesListener)
	{
		mActivity = activity;
		mBillingUpdatesListener = updatesListener;
		mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();
	}

	@Override
	public void onPurchasesUpdated(BillingResult result, List<Purchase> purchases)
	{
		if (result.getResponseCode() == BillingResponseCode.OK)
		{
			mPurchases.clear();

			for (Purchase purchase : purchases)
				handlePurchase(purchase);

			mBillingUpdatesListener.onPurchasesUpdated(mPurchases, result);
		}
		else
			mBillingUpdatesListener.onPurchasesUpdated(purchases, result);
	}

	public void initiatePurchaseFlow(final String skuId)
	{
		final ProductDetails skuDetail = mSkuDetailsMap.get(skuId);

		if (skuDetail == null)
		{
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
					if (skuDetail != null)
					{
						List<ProductDetailsParams> productDetailsParamsList = new ArrayList<>();
						productDetailsParamsList.add(ProductDetailsParams.newBuilder().setProductDetails(skuDetail).build());
						mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
					}
				}
			}, new Runnable()
			{
				@Override
				public void run()
				{
					mBillingUpdatesListener.onPurchasesUpdated(null, errorResult);
				}
			});
		}
	}

	public void destroy()
	{
		if (mBillingClient != null && mBillingClient.isReady())
		{
			mBillingClient.endConnection();
			mBillingClient = null;
		}
	}
	 
	public void querySkuDetailsAsync(final String itemType, final List<String> skuList)
	{
		final List<Product> productList = new ArrayList<>();

		for (String productId : skuList)
			productList.add(Product.newBuilder().setProductId(productId).setProductType(ProductType.INAPP).build());

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(productList).build(), new ProductDetailsResponseListener()
				{
					@Override
					public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> skuDetailsList)
					{
						mBillingUpdatesListener.onQuerySkuDetailsFinished(skuDetailsList, billingResult);

						if (billingResult.getResponseCode() == BillingResponseCode.OK)
						{
							for (ProductDetails skuDetails : skuDetailsList)
							{
								mSkuDetailsMap.put(skuDetails.getProductId(), skuDetails);
								initiatePurchaseFlow(skuDetails.getProductId());
								break;
							}
						}
					}
				});
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
				mBillingUpdatesListener.onQuerySkuDetailsFinished(null, errorResult);
			}
		});
	}

	public void consumeAsync(final String purchaseToken)
	{
		if (mTokensToBeConsumed == null)
			mTokensToBeConsumed = new HashSet<>();
		else if (mTokensToBeConsumed.contains(purchaseToken)) {
			return;

		mTokensToBeConsumed.add(purchaseToken);

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				mBillingClient.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(purchaseToken).build(), new ConsumeResponseListener()
				{
					@Override
					public void onConsumeResponse(BillingResult billingResult, String purchaseToken)
					{
						mTokensToBeConsumed.remove(purchaseToken);
						mBillingUpdatesListener.onConsumeFinished(purchaseToken, billingResult);
					}
				});
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
				mBillingUpdatesListener.onConsumeFinished(null, errorResult);
			}
		});
	}

	public void acknowledgePurchase(final String purchaseToken)
	{
		if (mTokensToBeAcknowledged == null)
			mTokensToBeAcknowledged = new HashSet<>();
		else if (mTokensToBeAcknowledged.contains(purchaseToken))
			return;

		mTokensToBeAcknowledged.add(purchaseToken);

		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				mBillingClient.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchaseToken).build(), new AcknowledgePurchaseResponseListener()
				{
					@Override
					public void onAcknowledgePurchaseResponse(BillingResult billingResult)
					{
						mTokensToBeAcknowledged.remove(purchaseToken);

						mBillingUpdatesListener.onAcknowledgePurchaseFinished(purchaseToken, billingResult);
					}
				});
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
				mBillingUpdatesListener.onAcknowledgePurchaseFinished(null, errorResult);
			}
		});
	}

	public int getBillingClientResponseCode()
	{
		return mBillingClientResponseCode;
	}

	private void handlePurchase(Purchase purchase)
	{
		if (!verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature()))
			return;

		mPurchases.add(purchase);
	}

	private void onQueryPurchasesFinished(BillingResult result, List<Purchase> purchases )
	{
		if (mBillingClient == null || result.getResponseCode() != BillingResponseCode.OK)
		{
			mBillingUpdatesListener.onBillingClientSetupFinished(false);
			return;
		}

		mBillingUpdatesListener.onQueryPurchasesFinished(purchases);

		mBillingUpdatesListener.onBillingClientSetupFinished(true);
	}

	public boolean areSubscriptionsSupported()
	{
		return mBillingClient.isFeatureSupported(FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingResponseCode.OK;
	}

	public void queryPurchases()
	{
		executeServiceRequest(new Runnable()
		{
			@Override
			public void run()
			{
				PurchasesResult purchasesResult = mBillingClient.queryPurchases(SkuType.INAPP);

				mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build(), new PurchasesResponseListener()
				{
					public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
					{
						onQueryPurchasesFinished(billingResult, purchases);
					}
				});

				if (areSubscriptionsSupported())
				{
					PurchasesResult subscriptionResult = mBillingClient.queryPurchases(SkuType.SUBS);

					if (subscriptionResult.getResponseCode() == BillingResponse.OK)
						purchasesResult.getPurchasesList().addAll(subscriptionResult.getPurchasesList());
				}
			}
		}, new Runnable()
		{
			@Override
			public void run()
			{
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

				if (billingResponse.getResponseCode() == BillingResponseCode.OK)
				{
					mIsServiceConnected = true;

					if (executeOnSuccess != null)
						executeOnSuccess.run();
				}
				else
				{
					if (executeOnError != null)
						executeOnError.run();

					mIsServiceConnected = false;
				}
			}

			@Override
			public void onBillingServiceDisconnected()
			{
				mIsServiceConnected = false;
			}
		});
	}

	private void executeServiceRequest(Runnable runnable, Runnable onError)
	{
		if (mIsServiceConnected)
			runnable.run();
		else
			startServiceConnection(runnable, onError);
	}

	private boolean verifyValidSignature(String signedData, String signature)
	{
		try
		{
			return Security.verifyPurchase(BASE_64_ENCODED_PUBLIC_KEY, signedData, signature);
		}
		catch (Exception e)
			

		return false;
	}
}
