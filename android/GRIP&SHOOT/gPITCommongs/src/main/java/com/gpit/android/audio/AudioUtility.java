package com.gpit.android.audio;

import java.io.IOException;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.RingtoneManager;
import android.net.Uri;

public class AudioUtility {
	private static AudioUtility utility;
	
	public static AudioUtility getInstance(Context context) {
		if (utility == null)
			utility = new AudioUtility(context);
		
		return utility;
	}
	
	private Context mContext;
	
	private AudioUtility(Context context) {
		mContext = context;
	}
	
	public void playSound() throws IllegalArgumentException,
			SecurityException, IllegalStateException, IOException {
		Uri soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
		MediaPlayer mMediaPlayer = new MediaPlayer();
		mMediaPlayer.setDataSource(mContext, soundUri);
		final AudioManager audioManager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
		if (audioManager.getStreamVolume(AudioManager.STREAM_ALARM) != 0) {
			mMediaPlayer.setAudioStreamType(AudioManager.STREAM_ALARM);
			mMediaPlayer.setLooping(false);
			mMediaPlayer.prepare();
			mMediaPlayer.start();
		}
	}
}
