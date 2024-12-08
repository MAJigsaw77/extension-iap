package org.haxe.extension.util;

import android.app.Activity;
import com.android.billingclient.api.*;
import java.util.*;

public class BillingManager
{
	private final Activity mActivity;
	private final BillingUpdatesListener mBillingUpdatesListener;
	private final String mBase64EncodedPublicKey;
	private final List<Purchase> mPurchases = Collections.synchronizedList(new ArrayList<>());
	private final Map<String, ProductDetails> mProductDetailsMap = Collections.synchronizedMap(new HashMap<>());

	private BillingClient mBillingClient;
	private boolean mIsServiceConnected;
	private Set<String> mTokensToBeConsumed = Collections.synchronizedSet(new HashSet<>());
	private Set<String> mTokensToBeAcknowledged = Collections.synchronizedSet(new HashSet<>());

	public interface BillingUpdatesListener
	{
		void onBillingClientSetupFinished(Boolean success);
		void onQueryPurchasesFinished(List<Purchase> purchases);
		void onConsumeFinished(String token, BillingResult result);
		void onAcknowledgePurchaseFinished(String token, BillingResult result);
		void onPurchasesUpdated(List<Purchase> purchases, BillingResult result);
		void onQueryProductDetailsFinished(List<ProductDetails> productDetailsList, BillingResult result);
		void onError(String errorMessage);
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
						synchronized (mPurchases)
						{
							mPurchases.clear();
							mPurchases.addAll(purchases);
						}

						for (Purchase purchase : purchases)
							handlePurchase(purchase);
					}
					
					mBillingUpdatesListener.onPurchasesUpdated(purchases, result);
				}
			}).build();

			mBillingClient.startConnection(new BillingClientStateListener()
			{
				@Override
				public void onBillingSetupFinished(BillingResult billingResult)
				{
					mIsServiceConnected = billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK;

					mBillingUpdatesListener.onBillingClientSetupFinished(mIsServiceConnected);

					if (!mIsServiceConnected)
						mBillingUpdatesListener.onError(billingResult.getDebugMessage());
				}

				@Override
				public void onBillingServiceDisconnected()
				{
					mIsServiceConnected = false;
					mBillingUpdatesListener.onBillingClientSetupFinished(false);
				}
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to start billing connection: " + e.getMessage());
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
			mBillingUpdatesListener.onError("Failed to destroy billing client: " + e.getMessage());
		}
	}

	public void initiatePurchaseFlow(final String productId)
	{
		try
		{
			final ProductDetails productDetail = mProductDetailsMap.get(productId);

			if (productDetail == null)
				queryInAppProductDetailsAsync(Collections.singletonList(productId));
			else
			{
				List<BillingFlowParams.ProductDetailsParams> productDetailsParamsList = new ArrayList<>();
				productDetailsParamsList.add(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(productDetail).build());
				mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to initiate purchase flow: " + e.getMessage());
		}
	}

	public void initiateSubscriptionFlow(final String productId)
	{
		try
		{
			final ProductDetails productDetail = mProductDetailsMap.get(productId);

			if (productDetail == null)
				querySubsProductDetailsAsync(Collections.singletonList(productId));
			else
			{
				List<BillingFlowParams.ProductDetailsParams> productDetailsParamsList = new ArrayList<>();
				productDetailsParamsList.add(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(productDetail).build());
				mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to initiate subscription flow: " + e.getMessage());
		}
	}

	public void queryInAppProductDetailsAsync(final List<String> productList)
	{
		try
		{
			List<QueryProductDetailsParams.Product> inAppProductList = new ArrayList<>();

			for (String productId : productList)
				inAppProductList.add(QueryProductDetailsParams.Product.newBuilder().setProductId(productId).setProductType(BillingClient.ProductType.INAPP).build());

			mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(inAppProductList).build(), (billingResult, productDetailsList) -> {
				mBillingUpdatesListener.onQueryProductDetailsFinished(productDetailsList, billingResult);

				if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK)
				{
					for (ProductDetails productDetails : productDetailsList)
						mProductDetailsMap.put(productDetails.getProductId(), productDetails);
				}
				else
				{
					mBillingUpdatesListener.onError(billingResult.getDebugMessage());
				}
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to query INAPP product details: " + e.getMessage());
		}
	}

	public void querySubsProductDetailsAsync(final List<String> productList)
	{
		try
		{
			if (mBillingClient.isFeatureSupported(BillingClient.FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingClient.BillingResponseCode.OK)
			{
				List<QueryProductDetailsParams.Product> subsProductList = new ArrayList<>();

				for (String productId : productList)
				{
					subsProductList.add(QueryProductDetailsParams.Product.newBuilder()
						.setProductId(productId)
						.setProductType(BillingClient.ProductType.SUBS)
						.build());
				}

				mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(subsProductList).build(), (billingResult, productDetailsList) -> {
					mBillingUpdatesListener.onQueryProductDetailsFinished(productDetailsList, billingResult);

					if (billingResult.getResponseCode() == BillingClient.BillingResponseCode.OK)
					{
						for (ProductDetails productDetails : productDetailsList)
							mProductDetailsMap.put(productDetails.getProductId(), productDetails);
					}
					else
					{
						mBillingUpdatesListener.onError(billingResult.getDebugMessage());
					}
				});
			}
			else
			{
				mBillingUpdatesListener.onError("Subscriptions feature is not supported.");
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to query SUBS product details: " + e.getMessage());
		}
	}

	public void queryInAppPurchasesAsync()
	{
		try
		{
			mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(), new PurchasesResponseListener()
			{
				public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
				{
					if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK)
						return;

					synchronized (mPurchases)
					{
						mPurchases.clear();

						if (purchases != null)
							mPurchases.addAll(purchases);
					}

					mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
				}
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to query INAPP purchases: " + e.getMessage());
		}
	}

	public void querySubsPurchasesAsync()
	{
		try
		{
			if (mBillingClient.isFeatureSupported(BillingClient.FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingClient.BillingResponseCode.OK)
			{
				mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build(), new PurchasesResponseListener()
				{
					public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
					{
						if (billingResult.getResponseCode() != BillingClient.BillingResponseCode.OK)
							return;

						synchronized (mPurchases)
						{
							mPurchases.clear();

							if (purchases != null)
								mPurchases.addAll(purchases);
						}

						mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
					}
				});
			}
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to query SUBS purchases: " + e.getMessage());
		}
	}

	public void consumeAsync(final String purchaseToken)
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

				mBillingUpdatesListener.onConsumeFinished(token, billingResult);
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to consume purchase: " + e.getMessage());
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

				mBillingUpdatesListener.onAcknowledgePurchaseFinished(purchaseToken, billingResult);
			});
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to acknowledge purchase: " + e.getMessage());
		}
	}

	private void handlePurchase(Purchase purchase)
	{
		if (!verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature()))
		{
			mBillingUpdatesListener.onError("Invalid purchase signature.");
			return;
		}

		synchronized (mPurchases)
		{
			mPurchases.add(purchase);
		}
	}

	private boolean verifyValidSignature(String signedData, String signature)
	{
		try
		{
			return Security.verifyPurchase(mBase64EncodedPublicKey, signedData, signature);
		}
		catch (Exception e)
		{
			mBillingUpdatesListener.onError("Failed to verify purchase signature: " + e.getMessage());
			return false;
		}
	}
}
