package com.gpit.android.sns.twitter;

import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.util.Log;
import android.view.Display;
import android.view.ViewGroup;
import android.view.Window;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.gpit.android.library.R;

public class WebDialog extends Dialog {

    static final int FB_BLUE = 0xFF6D84B4;
    static final float[] DIMENSIONS_LANDSCAPE = {460, 260};
    static final float[] DIMENSIONS_PORTRAIT = {280, 420};
    static final FrameLayout.LayoutParams FILL = 
        new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 
                         ViewGroup.LayoutParams.MATCH_PARENT);
    static final int MARGIN = 4;
    static final int PADDING = 2;
    static final String DISPLAY_STRING = "touch";
    static final String FB_ICON = "icon.png";
    
    private String mUrl;
    private WebListener mListener;
    private ProgressDialog mSpinner;
    private WebView mWebView;
    private LinearLayout mContent;
    private TextView mTitle;
    private String mCallbackUrl;
    private String mSNSName;
    
    public WebDialog(Context context, String url, WebListener listener, String callbackUrl, String snsName) {
        super(context);
        mUrl = url;
        mListener = listener;
        mCallbackUrl = callbackUrl;
        mSNSName = snsName;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mSpinner = new ProgressDialog(getContext());
        mSpinner.requestWindowFeature(Window.FEATURE_NO_TITLE);
        mSpinner.setCancelable(false);
        mSpinner.setMessage("Loading...");
        
        mContent = new LinearLayout(getContext());
        mContent.setOrientation(LinearLayout.VERTICAL);
        setUpTitle();
        setUpWebView();
        Display display = getWindow().getWindowManager().getDefaultDisplay();
        final float scale = getContext().getResources().getDisplayMetrics().density;
        float[] dimensions = display.getWidth() < display.getHeight() ?
        		DIMENSIONS_PORTRAIT : DIMENSIONS_LANDSCAPE;
        addContentView(mContent, new FrameLayout.LayoutParams(
        		(int) (dimensions[0] * scale + 0.5f),
        		(int) (dimensions[1] * scale + 0.5f)));
    }

    private void setUpTitle() {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        Drawable icon = getContext().getResources().getDrawable(R.drawable.twitter);
        mTitle = new TextView(getContext());
        mTitle.setText(mSNSName);
        mTitle.setTextColor(Color.WHITE);
        mTitle.setTypeface(Typeface.DEFAULT_BOLD);
        mTitle.setBackgroundColor(FB_BLUE);
        mTitle.setPadding(MARGIN + PADDING, MARGIN, MARGIN, MARGIN);
        mTitle.setCompoundDrawablePadding(MARGIN + PADDING);
        mTitle.setCompoundDrawablesWithIntrinsicBounds(
                icon, null, null, null);
        mContent.addView(mTitle);
    }
	
    private void setUpWebView() {
        mWebView = new WebView(getContext());
        mWebView.setVerticalScrollBarEnabled(false);
//        mWebView.setHorizontalScrollBarEnabled(false);
        mWebView.getSettings().setJavaScriptEnabled(true);
        mWebView.setWebViewClient(new WebDialog.FbWebViewClient());
        mWebView.loadUrl(mUrl);
        mWebView.setLayoutParams(FILL);
        mContent.addView(mWebView);
    }

    private class FbWebViewClient extends WebViewClient {

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            if (url.startsWith(mCallbackUrl)) {
                Bundle values = Util.parseUrl(url);

                //http://api.lmk.com/succ_twitt?denied=QJqoKGxYbjMqKjElKTuPvKFEwSrJZSaDYmWEcucI30
                String error = values.getString("error");
                if (error == null) {
                    error = values.getString("error_type");
                }

                if (error == null) {
                    error = values.getString("denied");
                }

                if (error == null) {
                    mListener.onComplete(url);
                } else if (error.equals("access_denied") ||
                           error.equals("OAuthAccessDeniedException")) {
                    mListener.onCancel();
                } else {
                    mListener.onError(error);
                }

                WebDialog.this.dismiss();
                return true;
            }/* else if (url.startsWith(Facebook.CANCEL_URI)) {
                mListener.onCancel();
                WebDialog.this.dismiss();
                return true;
            }*/ else if (url.contains(DISPLAY_STRING)) {
                return false;
            } else 
            	return false;
        }

        @Override
        public void onReceivedError(WebView view, int errorCode,
                String description, String failingUrl) {
            super.onReceivedError(view, errorCode, description, failingUrl);
            mListener.onDialogError(
                    new DialogError(description, errorCode, failingUrl));
            WebDialog.this.dismiss();
        }

        @Override
        public void onPageStarted(WebView view, String url, Bitmap favicon) {
            Log.d("Facebook-WebView", "Webview loading URL: " + url);
            if(url.startsWith(mCallbackUrl))
            {
            	mListener.onComplete(url);
            	mListener = null;
        		WebDialog.this.dismiss();
        		return;
            }
            
            super.onPageStarted(view, url, favicon);
            mSpinner.show();
        }

        @Override
        public void onPageFinished(WebView view, String url) {
            super.onPageFinished(view, url);
            String title = mWebView.getTitle();
            if (title != null && title.length() > 0) {
                mTitle.setText(title);
            }
            mSpinner.dismiss();
        }
    }
}
