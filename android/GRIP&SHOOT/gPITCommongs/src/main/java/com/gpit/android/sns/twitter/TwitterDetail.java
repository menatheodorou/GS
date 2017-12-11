package com.gpit.android.sns.twitter;

import oauth.signpost.OAuthProvider;
import oauth.signpost.basic.DefaultOAuthProvider;
import oauth.signpost.commonshttp.CommonsHttpOAuthConsumer;
import oauth.signpost.exception.OAuthCommunicationException;
import oauth.signpost.exception.OAuthExpectationFailedException;
import oauth.signpost.exception.OAuthMessageSignerException;
import oauth.signpost.exception.OAuthNotAuthorizedException;
import winterwell.jtwitter.OAuthSignpostClient;
import winterwell.jtwitter.Twitter;
import winterwell.jtwitter.Twitter.User;
import winterwell.jtwitter.TwitterAccount;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;

import com.gpit.android.library.R;
import com.gpit.android.util.Utils;

public class TwitterDetail implements WebListener {
	private String authUrl;
	private static OAuthProvider provider;
	private static CommonsHttpOAuthConsumer consumer;
	
	private String OAUTH_VERIFIER = "oauth_verifier";
	
	private Thread mythread;
	
	public String mAccessToken;
	public String mAccessSecret;
	public String mOwnEmail;
	public String mUserName;
	
	private Activity parentActivity;
	private TwitterConnector mConnector;
	
	private String mConsumerKey;
	private String mConsumerSecret;
	private String CALLBACK = null;
	
	private AuthListener mAuthListener;
	// private AsyncListener mListener;
	
	public TwitterDetail(TwitterConnector connector, Activity context, String consumerKey, String consumerSecret, String callback, 
			AuthListener authListener, AsyncListener listener) {
		mConnector = connector;
		parentActivity = context;
		
		mConsumerKey = consumerKey;
		mConsumerSecret = consumerSecret;
		CALLBACK = callback;
		
		mAuthListener = authListener;
		// mListener = listener;
	}
	
	public void getTwitterAccessToken() {
		Utils.showWaitingDlg(parentActivity);

		clearCookies(parentActivity);

		consumer = new CommonsHttpOAuthConsumer(mConsumerKey, mConsumerSecret);

		provider = new DefaultOAuthProvider(
				"http://twitter.com/oauth/request_token",
				"http://twitter.com/oauth/access_token",
				"http://twitter.com/oauth/authorize");

		// It turns out this was the missing thing to making standard Activity launch mode work
		provider.setOAuth10a(true);
				
		mythread = new Thread() {
			@Override
			public void run() {
				String msg;
				try {
					authUrl = provider.retrieveRequestToken(consumer, CALLBACK);

					parentActivity.runOnUiThread(new Runnable() {
						@Override
						public void run() {
							(new WebDialog(parentActivity, authUrl,
									TwitterDetail.this, CALLBACK,
									parentActivity.getString(R.string.twitter)))
									.show();
						}
					});
					
					Utils.hideWaitingDialog();
					if (mAuthListener != null)
						mAuthListener.authFinished();
					
					return;
				} catch (OAuthMessageSignerException e) {
					msg = e.getLocalizedMessage();
					e.printStackTrace();
				} catch (OAuthNotAuthorizedException e) {
					msg = e.getLocalizedMessage();
					e.printStackTrace();
				} catch (OAuthExpectationFailedException e) {
					msg = e.getLocalizedMessage();
					e.printStackTrace();
				} catch (OAuthCommunicationException e) {
					msg = e.getLocalizedMessage();
					e.printStackTrace();
				}
				
				ShowDialog(parentActivity.getString(R.string.twitter), msg);
				Utils.hideWaitingDialog();
				if (mAuthListener != null)
					mAuthListener.authFailed();
			}
		};
		mythread.start();
	}
		
	private static void clearCookies(Context context) {
	    CookieSyncManager.createInstance(context); 
	    CookieManager cookieManager = CookieManager.getInstance();
	    cookieManager.removeAllCookie();
	}

	private void ShowDialog(final String strAlertTitle, final String strAlertMessage)
	{
		parentActivity.runOnUiThread(new Runnable() {
			
			@Override
			public void run() {
				Dialog dialog = new AlertDialog.Builder(parentActivity).setIcon(android.R.drawable.ic_dialog_alert)
				.setTitle(strAlertTitle).setMessage(strAlertMessage)
		        .setPositiveButton(R.string.close, new DialogInterface.OnClickListener() {
		            public void onClick(DialogInterface dialog, int whichButton)
		            {
		            	dialog.dismiss();
		            }
		        }).create();
				dialog.show();		
			}
		});
	}

	public void onCancel() {
		if (mAuthListener != null)
			mAuthListener.authFailed();
	}

	public void onComplete(String url) {
		final String verifier = url.substring(url.indexOf(OAUTH_VERIFIER) + OAUTH_VERIFIER.length() + 1);
		
		Thread worker = new Thread(new Runnable() {

			@Override
			public void run() {
				try {
					provider.retrieveAccessToken(consumer, verifier);
				} catch (OAuthMessageSignerException e) {
					e.printStackTrace();
				} catch (OAuthNotAuthorizedException e) {
					e.printStackTrace();
				} catch (OAuthExpectationFailedException e) {
					e.printStackTrace();
				} catch (OAuthCommunicationException e) {
					e.printStackTrace();
				}

				mAccessToken = consumer.getToken();
				mAccessSecret = consumer.getTokenSecret();

				OAuthSignpostClient client = null;

				try {
					client = new OAuthSignpostClient(mConsumerKey,
							mConsumerSecret, mAccessToken, mAccessSecret);
				} catch (Exception e) {
					e.printStackTrace();
					Utils.hideWaitingDialog();
					return;
				}

				Twitter mTwitter = new Twitter(null, client);
				TwitterAccount account = new TwitterAccount(mTwitter);
				User me = account.verifyCredentials();
				mOwnEmail = me.screenName;
				mUserName = me.name;

				Utils.hideWaitingDialog();
				
				// Update login information
				mConnector.setLoginInfo(mAccessToken, mAccessSecret, mOwnEmail, mUserName);
				
				if (mAuthListener != null)
					mAuthListener.authFinished();
			}
		});
		worker.start();
	}

	public void onDialogError(DialogError arg0) {
		Utils.hideWaitingDialog();
	}

	public void onError(String arg0) {
		Utils.hideWaitingDialog();
	}

	public void onCreate() {
		getTwitterAccessToken();
	}
}
