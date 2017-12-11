package com.gpit.android.sns.facebook;

import java.io.File;
import java.io.IOException;

import android.app.Activity;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.widget.Toast;

import com.facebook.android.AsyncFacebookRunner;
import com.facebook.android.AsyncFacebookRunner.RequestListener;
import com.facebook.android.DialogError;
import com.facebook.android.Facebook;
import com.facebook.android.FacebookError;
import com.gpit.android.sns.facebook.SessionEvents.AuthListener;
import com.gpit.android.sns.facebook.SessionEvents.LogoutListener;
import com.gpit.android.util.Utils;

public class FacebookConnector {
	private final static String TAG = "facebook";
	
	private Facebook mFacebook;
	private Context context;
	private String[] mPermissions;
	private Context mContext;
	
	private AsyncFacebookRunner mAsyncRunner;
	private Handler mHandler;
	private SessionListener mSessionListener = new SessionListener();
	
	public FacebookConnector(String appId, Context context,
			String[] mPermissions) {
		this.mFacebook = new Facebook(appId);
		mAsyncRunner = new AsyncFacebookRunner(mFacebook);
		
		SessionStore.restore(mFacebook, context);
		SessionEvents.addAuthListener(mSessionListener);
		SessionEvents.addLogoutListener(mSessionListener);

		this.context = context;
		this.mPermissions = mPermissions;
		this.mHandler = new Handler();
		this.mContext = context;
	}

	public void setActivity(Activity context) {
		this.mContext = context;
	}
	
	public Facebook getFacebookInstance() {
		return mFacebook;
	}
	
	public AsyncFacebookRunner getAsyncRunner() {
		return mAsyncRunner;
	}
	
	public boolean isLogin() {
		return mFacebook.isSessionValid();
	}
	

	public boolean login(final LoginDialogListener listener) {
		if (!mFacebook.isSessionValid()) {
			mFacebook.authorize((Activity)mContext, mPermissions,
					Facebook.FORCE_DIALOG_AUTH, listener);
			return false;
		} else {
			if (listener != null)
				listener.onComplete(null);
		}
		
		return true;
	}

	public void logout() {
		logout(null);
	}
	
	public void logout(final BaseRequestListener listener) {
		if (mFacebook.isSessionValid()) {
			try {
				AsyncFacebookRunner asyncRunner = new AsyncFacebookRunner(mFacebook);
	            asyncRunner.logout(mContext, listener);
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}
	
	public void resetToken() {
		SessionStore.clear(context);
		mFacebook.setAccessToken(null);
	}
	
    public class LogoutRequestListener extends BaseRequestListener {
        @Override
        public void onComplete(String response, final Object state) {
            /*
             * callback should be run in the original thread, not the background
             * thread
             */
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    SessionEvents.onLogoutFinish();
                }
            });
        }
    }

    // JSONObject json = Util.parseJson(response);
    // fbId = json.getString("id");
    // fbName = json.getString("name");
    // fbEmail = json.getString("email");
	public void getID(RequestListener listener) {
		if (mFacebook.isSessionValid()) {
			mAsyncRunner.request("me", listener);
		} else {
			// no logged in, so relogin
			Log.d("facebook", "sessionNOTValid, relogin");
			login(new LoginDialogListener());
		}
	}

	
	public void postMessageOnWall(final String title, final String msg, final String imgPath) {
		postMessageOnWall(title, msg, imgPath, null);
	}
	
	public void postMessageOnWall(final String title, final String msg, final String imgPath, BaseRequestListener listener) {
		if (mFacebook.isSessionValid()) {
			Bundle params = new Bundle();
			params.putString("app_id", mFacebook.getAppId());
			params.putString("message", msg);
			
			try {
				if (imgPath != null) {
					// params.putString("method", "photos.upload");
					File file = new File(imgPath);
					byte[] bytes = Utility.scaleImage(context, Uri.fromFile(file));
					params.putString("caption", title);
					params.putString("filename", file.getName());
					params.putByteArray("source", bytes);
					params.putString(Facebook.TOKEN, mFacebook.getAccessToken());
				}
				
				
				Utils.showWaitingDlg(mContext);
				if (listener != null) {
					mAsyncRunner.request("me/photos", params, "POST", listener, null);
				} else {
				mAsyncRunner.request("me/photos", params, "POST",
					new BaseRequestListener() {
						@Override
						public void onComplete(String response, Object state) {
							try {
					            // process the response here: (executed in background thread)
					            Log.d("Facebook-Example", "Response: " + response.toString());
					            
					            ((Activity)mContext).runOnUiThread(new Runnable() {
									@Override
									public void run() {
										Toast.makeText(mContext, "Facebook Posting Completed", Toast.LENGTH_LONG).show();
									}
					            });
					        } catch (final FacebookError e) {
					            Log.w("Facebook-Example", "Facebook Error: " + e.getMessage());
					            ((Activity)mContext).runOnUiThread(new Runnable() {
									@Override
									public void run() {
										Toast.makeText(mContext, "Facebook Error: " + e.getMessage(), Toast.LENGTH_LONG).show();
									}
					            });
					        }
							
							Utils.hideWaitingDialog();
						}

						@Override
						public void onFacebookError(FacebookError e,
								Object state) {
							// TODO Auto-generated method stub
							Utils.hideWaitingDialog();
							
						}
					}, null);
				}
			} catch (IOException e) {
				e.printStackTrace();
				Utils.hideWaitingDialog();
			}
		} else {
			if (login(new LoginDialogListener() {
				@Override
		        public void onComplete(Bundle values) {
		            super.onComplete(values);
		            postMessageOnWall(title, msg, imgPath);
		        }
				@Override
			    public void onFacebookError(FacebookError error) {
			        super.onFacebookError(error);
			    }

			    @Override
			    public void onError(DialogError error) {
			        super.onError(error);
			    }

			    @Override
			    public void onCancel() {
			        super.onCancel();
			    }
			})) {
				new LoginDialogListener().onComplete(null);
				postMessageOnWall(title, msg, imgPath);
			}
		}
	}

	public String getAccessToken() {
		String accessToken = mFacebook.getAccessToken();
		
		return accessToken;
	}

	public class SessionListener implements AuthListener, LogoutListener {

        @Override
        public void onAuthSucceed() {
            SessionStore.save(mFacebook, context);
        }

        @Override
        public void onAuthFail(String error) {
        }

        @Override
        public void onLogoutBegin() {
        }

        @Override
        public void onLogoutFinish() {
            SessionStore.clear(context);
        }
    }
}
