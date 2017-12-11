package com.gpit.android.sns.twitter;

import com.gpit.android.util.Utils;

import winterwell.jtwitter.OAuthSignpostClient;
import winterwell.jtwitter.Twitter;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;

public class TwitterConnector {
	private String mConsumerKey;
	private String mConsumerSecret;
	private String mAccessKey;
	private String mAccessSecret;
	private String mCallback;
	
	private Context mContext;
	public TwitterDetail mTWDialog;
	private TwitterInfo mTWInfo = new TwitterInfo();
	
	public TwitterConnector(Context context, String consumerKey, String consumerSecret, 
			String accessKey, String accessSecret, String callback) {
		mContext = context;
		
		mConsumerKey = consumerKey;
		mConsumerSecret = consumerSecret;
		mAccessKey = accessKey;
		mAccessSecret = accessSecret;
		mCallback = callback;
		
		setLoginInfo(mAccessKey, mAccessSecret, mTWInfo.userEmail, mTWInfo.userName);
	}
	
	public void setActivity(Activity activity) {
		mContext = activity;
		loadTwSetting();
	}

	public boolean isLogin() {
		return mTWInfo.useState;
	}
	
	public TwitterInfo getUserInfo() {
		return mTWInfo;
	}
	
	void setLoginInfo(String accessToken, String accessSecret, String ownEmail, String userName) {
		mTWInfo.accessToken = accessToken;
		mTWInfo.accessSecret = accessSecret;
		mTWInfo.userEmail = ownEmail;
		mTWInfo.userName = userName;
		
		saveTwSetting();
	}
	
	public void login(final AuthListener authListener) {
		if(!isLogin()) {
			mTWDialog = new TwitterDetail(this, (Activity)mContext, mConsumerKey, mConsumerSecret, mCallback, 
				new AuthListener() {
					@Override
					public void authFinished() {
						saveTwSetting();
						
						if (authListener != null)
							authListener.authFinished();
					}

					@Override
					public void authFailed() {
						mTWInfo.useState = false;
						saveTwSetting();
						
						if (authListener != null)
							authListener.authFailed();
					}
				}, 
				new AsyncListener() {
					@Override
					public void showWaitingDlg() {
						Utils.showWaitingDlg(mContext);
					}
					
					@Override
					public void hideWaitingDlg() {
						Utils.hideWaitingDialog();
					}
				}
			);

			mTWDialog.onCreate();		
		} else {
			if (authListener != null)
				authListener.authFinished();
		}
	}
	
	public void logout() {
		mTWInfo.useState = false;
		saveTwSetting();
	}
	
	public String getAccessToken() {
		String accessToken = mTWInfo.accessToken;
		
		return accessToken;
	}

	// Post twitter message to twitter
	public void postArticleToTwitter(final String message, final AuthListener listener) {
		login(new AuthListener() {
			@Override
			public void authFinished() {
				Utils.showWaitingDlg(mContext);
				
				OAuthSignpostClient client = null;
				try {
					client = new OAuthSignpostClient(mConsumerKey, mConsumerSecret, 
							mTWInfo.accessToken, mTWInfo.accessSecret);
				} catch (Exception e) {
					e.printStackTrace();
					((AsyncListener)mContext).hideWaitingDlg();
					return;
				}
				
				final Twitter mTwitter = new Twitter(null, client);
				Thread thread = new Thread(new Runnable() {
					@Override
					public void run() {
						String postMessage;
						postMessage = message; 
						if(message != null && message.length() > 140)
							postMessage = message.substring(0, 140);
				
						try {
							mTwitter.setStatus(postMessage);
							if (listener != null)
								listener.authFinished();
						} catch (Exception e) {
							if (listener != null)
								listener.authFailed();
						}
					}
				});
				thread.start();
			}
			
			@Override
			public void authFailed() {
				if (listener != null)
					listener.authFailed();
			}
		});
	}
	
	/**
	 * Load setting from preference value or database
	 */
	public void loadTwSetting() {
		SharedPreferences sharedPrefs = mContext.getSharedPreferences("twitter", 
				Context.MODE_PRIVATE);
		mTWInfo.userName = sharedPrefs.getString("username", "");
		mTWInfo.userEmail = sharedPrefs.getString("userEmail", "");
		mTWInfo.accessToken = sharedPrefs.getString("accessToken", "");
		mTWInfo.accessSecret = sharedPrefs.getString("accessSecret", "");
		mTWInfo.useState = sharedPrefs.getBoolean("useState", false);
	}
	
	public void saveTwSetting() {
		SharedPreferences sharedPrefs = mContext.getSharedPreferences("mygallery", 
				Context.MODE_PRIVATE);
		SharedPreferences.Editor editor = sharedPrefs.edit();
		
		editor.putString("username", mTWInfo.userName);
		editor.putString("userEmail", mTWInfo.userEmail);
		editor.putString("accessToken", mTWInfo.accessToken);
		editor.putString("accessSecret", mTWInfo.accessSecret);
		editor.putBoolean("useState", mTWInfo.useState);
		
		editor.commit();
	}
}
