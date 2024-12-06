package org.haxe.extension.util;

import android.app.Activity;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.AcknowledgePurchaseResponseListener;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingClient.FeatureType;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingFlowParams.ProductDetailsParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.ConsumeResponseListener;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.ProductDetailsResponseListener;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesResponseListener;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.PurchaseHistoryRecord;
import com.android.billingclient.api.PurchaseHistoryResponseListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryProductDetailsParams.Product;
import com.android.billingclient.api.QueryPurchasesParams;
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
		mActivity = activity;
		mBillingUpdatesListener = updatesListener;
		mBillingClient = BillingClient.newBuilder(mActivity).enablePendingPurchases().setListener(this).build();
		mBillingClient.startConnection(new BillingClientStateListener()
		{
			@Override
			public void onBillingSetupFinished(BillingResult billingResponse)
			{
				mIsServiceConnected = BillingResponseCode.OK;

				mBillingUpdatesListener.onBillingClientSetupFinished(mIsServiceConnected);
			}

			@Override
			public void onBillingServiceDisconnected()
			{
				mIsServiceConnected = false;

				mBillingUpdatesListener.onBillingClientSetupFinished(mIsServiceConnected);
			}
		});
	}

	public void destroy()
	{
		if (mBillingClient != null && mBillingClient.isReady())
		{
			mBillingClient.endConnection();
			mBillingClient = null;
		}
	}

	public void initiatePurchaseFlow(final String productId)
	{
		final ProductDetails productDetail = mProductDetailsMap.get(productId);

		if (productDetail == null)
		{
			ArrayList<String> ids = new ArrayList<String>();
			ids.add(productId);
			queryProductDetailsAsync(ProductType.INAPP, ids);
		}
		else
		{
			List<ProductDetailsParams> productDetailsParamsList = new ArrayList<ProductDetailsParams>();
			productDetailsParamsList.add(ProductDetailsParams.newBuilder().setProductDetails(productDetail).build());
			mBillingClient.launchBillingFlow(mActivity, BillingFlowParams.newBuilder().setProductDetailsParamsList(productDetailsParamsList).build());
		}
	}

	public void queryProductDetailsAsync(final String itemType, final List<String> productList)
	{
		final List<Product> newProductList = new ArrayList<Product>();

		for (String productId : productList)
			newProductList.add(Product.newBuilder().setProductId(productId).setProductType(itemType).build());

		mBillingClient.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(newProductList).build(), new ProductDetailsResponseListener()
		{
			@Override
			public void onProductDetailsResponse(BillingResult billingResult, List<ProductDetails> productDetailsList)
			{
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
			}
		});
	}

	public void consumeAsync(final String purchaseToken)
	{
		if (mTokensToBeConsumed == null)
			mTokensToBeConsumed = new HashSet<String>();
		else if (mTokensToBeConsumed.contains(purchaseToken))
			return;

		mTokensToBeConsumed.add(purchaseToken);

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

	public void acknowledgePurchase(final String purchaseToken)
	{
		if (mTokensToBeAcknowledged == null)
			mTokensToBeAcknowledged = new HashSet<String>();
		else if (mTokensToBeAcknowledged.contains(purchaseToken))
			return;

		mTokensToBeAcknowledged.add(purchaseToken);

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

	private void handlePurchase(Purchase purchase)
	{
		if (!verifyValidSignature(purchase.getOriginalJson(), purchase.getSignature()))
			return;

		mPurchases.add(purchase);
	}

	public void queryPurchasesAsync()
	{
		mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build(), new PurchasesResponseListener()
		{
			@Override
			public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
			{
				onQueryPurchasesFinished(billingResult, purchases);
			}
		});

		if (mBillingClient.isFeatureSupported(FeatureType.SUBSCRIPTIONS).getResponseCode() == BillingResponseCode.OK)
		{
			mBillingClient.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(ProductType.SUBS).build(), new PurchasesResponseListener()
			{
				@Override
				public void onQueryPurchasesResponse(BillingResult billingResult, List<Purchase> purchases)
				{
					onQueryPurchasesFinished(billingResult, purchases);
				}
			});
		}
	}

	private boolean verifyValidSignature(String signedData, String signature)
	{
		try
		{
			return Security.verifyPurchase(BASE_64_ENCODED_PUBLIC_KEY, signedData, signature);
		}
		catch (Exception e)
		{
			return false;
		}
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

	private void onQueryPurchasesFinished(BillingResult result, List<Purchase> purchases)
	{
		if (mBillingClient == null || result.getResponseCode() != BillingResponseCode.OK)
			return;

		mBillingUpdatesListener.onQueryPurchasesFinished(purchases);
	}
}
