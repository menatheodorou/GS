package com.gpit.android.camera.gripandshoot.youtube;

import android.os.Bundle;
import android.widget.Toast;

import com.google.android.youtube.player.YouTubeBaseActivity;
import com.google.android.youtube.player.YouTubeInitializationResult;
import com.google.android.youtube.player.YouTubePlayer;
import com.google.android.youtube.player.YouTubePlayer.PlayerStyle;
import com.google.android.youtube.player.YouTubePlayer.Provider;
import com.google.android.youtube.player.YouTubePlayerView;
import com.gpit.android.camera.gripandshoot.R;

public class YoutubePlayActivity extends YouTubeBaseActivity implements
		YouTubePlayer.OnInitializedListener {

	private static final int RECOVERY_DIALOG_REQUEST = 1;
	private String videoId = "";

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.youtube_player);

		videoId = getIntent().getStringExtra("video_id");
		YouTubePlayerView youTubeView = (YouTubePlayerView) findViewById(R.id.youtube_view);
		youTubeView.initialize(DeveloperKey.DEVELOPER_KEY, this);
	}

	@Override
	public void onInitializationFailure(Provider arg0,
			YouTubeInitializationResult errorReason) {
		// TODO Auto-generated method stub
		if (errorReason.isUserRecoverableError()) {
			errorReason.getErrorDialog(this, RECOVERY_DIALOG_REQUEST).show();
		} else {
			String errorMessage = String.format(" error = %s",
					errorReason.toString());
			Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show();
		}
	}

	@Override
	public void onInitializationSuccess(Provider arg0, YouTubePlayer player,
			boolean wasRestored) {
		// TODO Auto-generated method stub
		if (!wasRestored) {
			player.cueVideo(videoId);
			player.setPlayerStyle(PlayerStyle.DEFAULT);
			player.setPlayerStateChangeListener(new VideoListener());
			
			player.play();
		}
	}

	private final class VideoListener implements
			YouTubePlayer.PlayerStateChangeListener {

		@Override
		public void onLoaded(String videoId) {
		}

		@Override
		public void onVideoEnded() {
			YoutubePlayActivity.this.finish();
		}

		@Override
		public void onError(YouTubePlayer.ErrorReason errorReason) {
		}

		// ignored callbacks

		@Override
		public void onVideoStarted() {
		}

		@Override
		public void onAdStarted() {
		}

		@Override
		public void onLoading() {
		}

	}
}
