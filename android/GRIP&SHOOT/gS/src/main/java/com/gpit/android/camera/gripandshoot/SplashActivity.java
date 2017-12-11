package com.gpit.android.camera.gripandshoot;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.widget.TextView;

import com.gpit.android.util.Utils;

public class SplashActivity extends Activity {
	private final static String APP_VERSION_TITLE = "%s v%s";
	
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        MyCount ct = new MyCount(3000, 3000);
		ct.start();
		
		// Show application version name & code
		String versionName = Utils.getAppVersionName(this);
		int versionCode = Utils.getAppVersionCode(this);
		String versionTitle = String.format(APP_VERSION_TITLE, getTitle(), versionName);
		setTitle(versionTitle);
		((TextView)findViewById(R.id.tvVersion)).setText(versionTitle);
    }
    
    final class MyCount extends CountDownTimer {
		public MyCount(long millisInFuture, long countDownInterval) {
			super(millisInFuture, countDownInterval);
		}
		
		@Override
		public void onFinish() {
			Intent myIntent;
			
			myIntent = new Intent(SplashActivity.this, WaitingForDeviceActivity.class);
			startActivity(myIntent);
			finish();
		}

		@Override
		public void onTick(long millisUntilFinished) {
		}

	}
}
