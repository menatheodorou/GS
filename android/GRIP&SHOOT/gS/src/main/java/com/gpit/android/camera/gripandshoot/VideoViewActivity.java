package com.gpit.android.camera.gripandshoot;

import junit.framework.Assert;
import android.app.Activity;
import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.net.Uri;
import android.os.Bundle;
import android.widget.MediaController;
import android.widget.VideoView;

public class VideoViewActivity extends Activity {
	public final static String INTENT_PARM_KEY_VIDEO_ID = "video_id";
	public final static int VIDEO_HOW_DO_I_PAIR = 0;
	public final static int VIDEO_HOW_DO_I_CHANGE = 1;
	public final static int VIDEO_WHAT_IS_THE_GS = 2;
	
	private int mVideoID = VIDEO_HOW_DO_I_PAIR;
	private VideoView mVideoView;
	
	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_video);
        
        Bundle extra = getIntent().getExtras();
        if (extra != null) {
        	mVideoID = extra.getInt(INTENT_PARM_KEY_VIDEO_ID);
        }
        
        mVideoView = (VideoView) findViewById(R.id.videoView);
        
        playVideo();
    }
    
    public void playVideo() {
    	//if you want the controls to appear
    	mVideoView.setMediaController(new MediaController(this));
    	String url = "";
    	
    	switch (mVideoID) {
    	case VIDEO_HOW_DO_I_CHANGE:
    		url = "https://dl.dropboxusercontent.com/u/48372563/battery.avi";
    		break;
    	case VIDEO_HOW_DO_I_PAIR:
    		url = "https://dl.dropboxusercontent.com/u/48372563/pairing.avi";
    		break;
    	case VIDEO_WHAT_IS_THE_GS:
    		url = "https://dl.dropboxusercontent.com/u/48372563/master_movie.avi";
    		break;
    	default:
    		Assert.assertTrue(false);
    	}
    	Uri video = Uri.parse(url); //do not add any extension
    	//if your file is named sherif.mp4 and placed in /raw
    	//use R.raw.sherif
    	mVideoView.setVideoURI(video);
    	mVideoView.setOnCompletionListener(new OnCompletionListener() {
			@Override
			public void onCompletion(MediaPlayer mp) {
				VideoViewActivity.this.finish();
			}
		});
    	mVideoView.start();
    }
}
