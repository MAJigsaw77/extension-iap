package org.haxe.extension.util;

import android.app.Activity;
import com.android.billingclient.api.*;
import java.util.*;

public class BillingManager
{
	private final Activity mActivity;
	private final BillingUpdatesListener mBillingUpdatesListener;
	private final String mBase64EncodedPublicKey;
	private final List<Purchase> mInAppPurchases = Collections.synchronizedList(new ArrayList<>());
	private final Map<String, ProductDetails> mInAppProductDetailsMap = Collections.synchronizedMap(new HashMap<>());

	private BillingClient mBillingClient;
	private boolean mIsServiceConnected;
	private Set<String> mTokensToBeConsumed = Collections.synchronizedSet(new HashSet<>());
	private Set<String> mTokensToBeAcknowledged = Collections.synchronizedSet(new HashSet<>());

	public interface BillingUpdatesListener
	{
		void onBillingClientSetup(Boolean success);
		void onBillingClientDebugLog(String message);
		void onQueryPurchases(List<Purchase> inAppPurchases);
		void onQueryProductDetails(List<ProductDetails> productDetailsList, BillingResult result);
		void onConsume(String token, BillingResult result);
		void onAcknowledgePurchase(String token, BillingResult result);
	}

	public BillingManager(Activity activity, final BillingUpdatesListener updatesListener, final String publicKey)
	{
		mActivity = activity;
		mBillingUpdatesListener = updatesListener;
		mBase64EncodedPublicKey = publicKey;

		try
		{
			mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build()).setListener(new PurchasesUpdatedListener()
			{
				@Override
				public void onPurchasesUpdated(BillingResult result, List<Purchase> purchases)
				{
					if (result.getResponseCode() == BillingClient.BillingResponseCode.OK)
					{
						synchronized (mInAppPurchases)
						{
							mInAppPurchases.clear();
						}

						for (Purchase purchase : purchases)
						{
							if (verifyPurchase(purchase))
							{
								if (purchase.getProducts().contains(BillingClient.ProductType.INAPP))
								{
									synchronized (mInAppPurchases)
									{
										mInAppPurchases.add(purchase);
									}
								}
							}
						}

						synchronized (mInAppPurchases)
						{
							mBillingUpdatesListener.onQueryPurchases(new ArrayList<>(mInAppPurchases));
						}
					}
					else
						mBillingUpdatesListener.onBillingClientDebugLog(result.getDebugMessage());
				}
			}).build();

			mBillingClient.startConnection(new BillingClientStateListener()
			{
				@Override
				public void onBillingSetupFinished(BillingResult billingResult)
				{
					mIsServiceConnected = billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK;

					mBillingUpdatesListener.onBillingClientSetup(mIsServiceConnected);

					if (!mIsServiceConnected)
						mBillingUpdatesListener.onBillingClientDebugLog(billingResult.getDebugMessage());
				}

				@Override
				public void onBillingServiceDisconnected()
				{
					mIsServiceConnected = false;

					mBillingUpdatesListener.onBillingClientSetup(mIsServiceConnected);
				}
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to start billing connection: " + e.getMessage());
		}
	}

	public void destroy()
	{
		try
		{
			if (mBillingClient != null && mBillingClient.isReady())
			{
				mBillingClient.endConnection();
				mBillingClient = null;
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to destroy billing client: " + e.getMessage());
		}
	}

	public void initiatePurchaseFlow(final String productId)
	{
		try
		{
			final ProductDetails productDetail = mInAppProductDetailsMap.get(productId);

			if (productDetail == null)
				queryProductDetails(Collections.singletonList(productId));
			else
			{
				List<BillingFlowParams.ProductDetailsParams> productDetailsParamsList = new ArrayList<>();
				productDetailsParamsList.add(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(productDetail).build());
				mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to initiate purchase flow: " + e.getMessage());
		}
	}

	public void queryProductDetails(final List<String> productList)
	{
		try
		{
			List<QueryProductDetailsParams.Product> inAppProductList = new ArrayList<>();

			for (String productId : productList)
				inAppProductList.add(QueryProductDetailsParams.Product.newBuilder().setProductId(productId).setProductType(BillingClient.ProductType.INAPP).build());

			mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(inAppProductList).build(), (billingResult, productDetailsList) -> {
				mBillingUpdatesListener.onQueryProductDetails(productDetailsList, billingResult);

				if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK)
				{
					for (ProductDetails productDetails : productDetailsList)
						mInAppProductDetailsMap.put(productDetails.getProductId(), productDetails);
				}
				else
					mBillingUpdatesListener.onBillingClientDebugLog(billingResult.getDebugMessage());
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to query INAPP product details: " + e.getMessage());
		}
	}

	public void queryPurchases()
	{
		try
		{
			mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(), new PurchasesResponseListener()
			{
				public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
				{
					if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK)
					{
						synchronized (mInAppPurchases)
						{
							mInAppPurchases.clear();

							if (purchases != null)
								mInAppPurchases.addAll(purchases);

							mBillingUpdatesListener.onQueryPurchases(new ArrayList<>(mInAppPurchases));
						}
					}
					else
						mBillingUpdatesListener.onBillingClientDebugLog(billingResult.getDebugMessage());
				}
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to query INAPP purchases: " + e.getMessage());
		}
	}

	public void consume(final String purchaseToken)
	{
		synchronized (mTokensToBeConsumed)
		{
			if (mTokensToBeConsumed.contains(purchaseToken))
				return;

			mTokensToBeConsumed.add(purchaseToken);
		}

		try
		{
			mBillingClient.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(purchaseToken).build(), (billingResult, token) -> {
				synchronized (mTokensToBeConsumed)
				{
					mTokensToBeConsumed.remove(token);
				}

				mBillingUpdatesListener.onConsume(token, billingResult);
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to consume purchase: " + e.getMessage());
		}
	}

	public void acknowledgePurchase(final String purchaseToken)
	{
		synchronized (mTokensToBeAcknowledged)
		{
			if (mTokensToBeAcknowledged.contains(purchaseToken))
				return;

			mTokensToBeAcknowledged.add(purchaseToken);
		}

		try
		{
			mBillingClient.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchaseToken).build(), (billingResult) -> {
				synchronized (mTokensToBeAcknowledged)
				{
					mTokensToBeAcknowledged.remove(purchaseToken);
				}

				mBillingUpdatesListener.onAcknowledgePurchase(purchaseToken, billingResult);
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to acknowledge purchase: " + e.getMessage());
		}
	}

	private boolean verifyPurchase(Purchase purchase)
	{
		try
		{
			if (!Security.verifyPurchase(mBase64EncodedPublicKey, purchase.getOriginalJson(), purchase.getSignature()))
			{
				mBillingUpdatesListener.onBillingClientDebugLog("Invalid purchase signature.");
				return false;
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onBillingClientDebugLog("Failed to verify purchase signature: " + e.getMessage());
			return false;
		}

		return true;
	}
}
