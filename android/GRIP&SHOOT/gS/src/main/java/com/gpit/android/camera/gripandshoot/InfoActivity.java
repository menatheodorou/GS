package com.gpit.android.camera.gripandshoot;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.gpit.android.camera.gripandshoot.youtube.YoutubePlayActivity;
import com.gpit.android.util.Utils;

public class InfoActivity extends Activity {
	private final static String APP_VERSION_TITLE = "%s (v%s - No.%d)";
	
	private TextView mTVHowDoIPair;
	private TextView mTVHowDoIChange;
	private TextView mTVWhatIsTheGS;
	private RelativeLayout mRLWeb;
	private TextView mTVWeb;
	private TextView mTVVersionNumber;
	
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_info);
        
        initUI();
    }
    
    private void initUI() {
    	mTVHowDoIPair = (TextView) findViewById(R.id.tvHowDoIPair);
    	mTVHowDoIPair.setOnClickListener(mHowDoIPairClickListener);
    	
    	mTVHowDoIChange = (TextView) findViewById(R.id.tvHowDoIChange);
    	mTVHowDoIChange.setOnClickListener(mHowDoIChangeClickListener);
    	
    	mTVWhatIsTheGS = (TextView) findViewById(R.id.tvWhatIsTheGS);
    	mTVWhatIsTheGS.setOnClickListener(mWhatIsTheGSClickListener);
    	
    	mRLWeb = (RelativeLayout) findViewById(R.id.rlWeb);
    	mRLWeb.setOnClickListener(mWebClickListener);
    	mTVWeb = (TextView) findViewById(R.id.tvWeb);
    	
    	mTVVersionNumber = (TextView) findViewById(R.id.tvVersionNumber);
    	mTVVersionNumber.setText(Utils.getAppVersionName(this));
    	
    }
    
    private OnClickListener mHowDoIPairClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			// TODO Auto-generated method stub
			Intent intent = new Intent(InfoActivity.this, YoutubePlayActivity.class);
			intent.putExtra("video_id", "PwEiNk2JOP0");
			startActivity(intent);
			
			/*
			Intent intent = new Intent(InfoActivity.this, VideoViewActivity.class);
			intent.putExtra(VideoViewActivity.INTENT_PARM_KEY_VIDEO_ID, VideoViewActivity.VIDEO_HOW_DO_I_PAIR);
			startActivity(intent);
			*/
		}
	};
	
	private OnClickListener mHowDoIChangeClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Intent intent = new Intent(InfoActivity.this, YoutubePlayActivity.class);
			intent.putExtra("video_id", "t3yxWmKzQdw");
			startActivity(intent);
			
			/*
			Intent intent = new Intent(InfoActivity.this, VideoViewActivity.class);
			intent.putExtra(VideoViewActivity.INTENT_PARM_KEY_VIDEO_ID, VideoViewActivity.VIDEO_HOW_DO_I_CHANGE);
			startActivity(intent);
			*/
		}
	};
	
	private OnClickListener mWhatIsTheGSClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Intent intent = new Intent(InfoActivity.this, YoutubePlayActivity.class);
			intent.putExtra("video_id", "WnhbiZ8bHjw");
			startActivity(intent);
			
			/*
			Intent intent = new Intent(InfoActivity.this, VideoViewActivity.class);
			intent.putExtra(VideoViewActivity.INTENT_PARM_KEY_VIDEO_ID, VideoViewActivity.VIDEO_WHAT_IS_THE_GS);
			startActivity(intent);
			*/
		}
	};
	
	private OnClickListener mWebClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(mTVWeb.getText().toString()));
			startActivity(browserIntent);
		}
	};
}
