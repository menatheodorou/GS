/***
7  Copyright (c) 2013 CommonsWare, LLC
  
  Licensed under the Apache License, Version 2.0 (the "License"); you may
  not use this file except in compliance with the License. You may obtain
  a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 */

package com.gpit.android.camera.gripandshoot.camera;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.hardware.Camera;
import android.hardware.Camera.Parameters;
import android.media.AudioManager;
import android.media.CamcorderProfile;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Handler;
import android.util.FloatMath;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.widget.FrameLayout;
import android.widget.FrameLayout.LayoutParams;
import android.widget.ImageView;
import android.widget.Toast;

import com.commonsware.cwac.camera.CameraFragment;
import com.commonsware.cwac.camera.CameraHost;
import com.commonsware.cwac.camera.SimpleCameraHost;
import com.gpit.android.animation.flipanimation.AnimationFactory;
import com.gpit.android.camera.gripandshoot.R;
import com.gpit.android.camera.gripandshoot.settings.SettingActivity;
import com.gpit.android.util.Utils;

import java.io.IOException;

public class GSCameraFragment extends CameraFragment {
	private static final String KEY_USE_FFC = "com.commonsware.cwac.camera.demo.USE_FFC";
	
	// UI Components
	private ViewGroup mVGRoot; 
	/// Auto-Focus effect
	private FrameLayout mCameraFocusLayout;
	private ImageView mIVFocus;

	// Zoom
	private float mDist;

	private CameraActivity mActivity;
	
	private boolean singleShotProcessing = false;
	private long lastFaceToast = 0L;
	private boolean mTakingPicture = false;

    private Bitmap mBitmapBuffer;

	// Shoot sound effect
	private static MediaPlayer mMediaPlayer;
	
	/*********************** INITIALIZATION **************************/
	public static GSCameraFragment newInstance(CameraActivity activity, boolean useFFC) {
		GSCameraFragment f = new GSCameraFragment();
		f.setActivity(activity);
		
		Bundle args = new Bundle();

		args.putBoolean(KEY_USE_FFC, useFFC);
		f.setArguments(args);

		return (f);
	}

	@Override
	public void onCreate(Bundle state) {
		super.onCreate(state);

		setHasOptionsMenu(true);
		setHost(new GSCameraHost(getActivity()));
	}

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container,
			Bundle savedInstanceState) {
		ViewGroup cameraView = (ViewGroup) super.onCreateView(inflater, container,
				savedInstanceState);
		mVGRoot = (ViewGroup) inflater.inflate(R.layout.fragment, container, false);

		((ViewGroup) mVGRoot.findViewById(R.id.camera)).addView(cameraView);
		initUI();
		
		return mVGRoot;
	}

	private void initUI() {
		// Add focus layout
		mCameraFocusLayout = (FrameLayout) View.inflate(getActivity(), R.layout.subview_camera_focus, null);
		mCameraFocusLayout.setVisibility(View.GONE);
		mCameraFocusLayout.setLayoutParams(new FrameLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT));
		
		AnimationSet animationSet = new AnimationSet(true);
		Animation[] animations = AnimationFactory.fadeInThenOutAnimation(500, 0);
		animationSet.addAnimation(animations[0]);
		animationSet.addAnimation(animations[1]);
		mCameraFocusLayout.setAnimation(animationSet);
		
		mIVFocus = (ImageView) mCameraFocusLayout.findViewById(R.id.ivFocus);
		
		mVGRoot.addView(mCameraFocusLayout);
		
		registerListener();
	}
	
	private void registerListener() {
		if (!useFrontFacingCamera())
			mVGRoot.setOnTouchListener(mTouchListener);
	}
	
	public void setActivity(CameraActivity activity) {
		mActivity = activity;
	}

	public void autoCenterFocus() {
		MotionEvent event = MotionEvent.obtain(0, 0, 0, mVGRoot.getMeasuredWidth() / 2, mVGRoot.getMeasuredHeight() / 2, 0);
		
		if (GSCameraFragment.this.manualFocus(event))
			showFocusLayout(event);
		
		event.recycle();
		
	}
	
	/******************** Animation ***********************/
	private void showFocusLayout(MotionEvent event) {
		FrameLayout.LayoutParams params = (FrameLayout.LayoutParams) mCameraFocusLayout.getLayoutParams();
		params.leftMargin = (int) event.getX() - mCameraFocusLayout.getMeasuredWidth() / 2;
		params.topMargin = (int) event.getY() - mCameraFocusLayout.getMeasuredHeight() / 2;
		mCameraFocusLayout.setLayoutParams(params);
		mCameraFocusLayout.requestLayout();
		
		mIVFocus.setBackgroundResource(R.drawable.white_border);
		mCameraFocusLayout.setVisibility(View.VISIBLE);
	}
	
	private void hideFocusLayout() {
		mIVFocus.setBackgroundResource(R.drawable.green_border);
		Handler handler = new Handler();
		handler.postDelayed(new Runnable() {
			@Override
			public void run() {
				mCameraFocusLayout.setVisibility(View.INVISIBLE);
			}
			
		}, 300);
	}
	
	/***************** EVENT LISTENER ********************/
	private OnTouchListener mTouchListener = new OnTouchListener() {
		@Override
		public boolean onTouch(View v, MotionEvent event) {
			// Get the pointer ID
			int action = event.getAction();

			if (event.getPointerCount() > 1) {
				// handle multi-touch events
				if (action == MotionEvent.ACTION_POINTER_DOWN) {
					mDist = getFingerSpacing(event);
				} else if (action == MotionEvent.ACTION_MOVE) {
					cancelAutoFocus();
					handleZoom(event);
				}
			} else {
				// handle single touch events
				if (getHost().isEnableTouchOnFocus() && action == MotionEvent.ACTION_UP) {
					GSCameraFragment.this.manualFocus(event);
					showFocusLayout(event);
				}
			}

			return true;
		}
	};
	
	/*********************** Camera Action **************************/
	private void handleZoom(MotionEvent event) {
		int maxZoom = getMaxZoomLevel();
		int zoom = getZoomLevel();
		float newDist = getFingerSpacing(event);
		if (newDist > mDist) {
			//zoom in
			if (zoom < maxZoom)
				zoom++;
		} else if (newDist < mDist) {
			//zoom out
			if (zoom > 0)
				zoom--;
		}
		mDist = newDist;

		zoom(zoom);
	}

	/*
	public void handleFocus(MotionEvent event, Camera.Parameters params) {
		int pointerId = event.getPointerId(0);
		int pointerIndex = event.findPointerIndex(pointerId);
		// Get the pointer's current position
		float x = event.getX(pointerIndex);
		float y = event.getY(pointerIndex);

		List<String> supportedFocusModes = params.getSupportedFocusModes();
		if (supportedFocusModes != null && supportedFocusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
			autoFocus();
		}
	}
	*/

	/** Determine the space between the first two fingers */
	private float getFingerSpacing(MotionEvent event) {
		// ...
		float x = event.getX(0) - event.getX(1);
		float y = event.getY(0) - event.getY(1);
		return FloatMath.sqrt(x * x + y * y);
	}

	private boolean isQualityFliteringRequired() {
		return false;
	}
	
	private boolean isRatioFliteringRequired() {
		float settingRatio = SettingActivity.getImageAspectRatioAsConst(getActivity());

		/*
		// if (settingRatio == SettingActivity.IMAGE_RATIO_1_1)
		//	return false;
		
		// Check image ratio
		int width = Utils.getScreenWidth(getActivity());
		int height = Utils.getScreenHeight(getActivity());
		
		float ratio = (float)width / height;
		if (ratio == settingRatio)
			return false;
		*/
		
		return true;
	}
	
	
	private boolean isFliteringRequired() {
		return isQualityFliteringRequired() || isRatioFliteringRequired();
	}
	
	public void takePicture() {
		singleShotProcessing = true;
		mTakingPicture = true;
		
		/*
		if (useFrontFacingCamera()) {
			((GSCameraHost)getHost()).onAutoFocus(true, null);
		} else {
			super.autoFocus();
		}
		*/
		((GSCameraHost)getHost()).onAutoFocus(true, null);
	}
	
	boolean isSingleShotProcessing() {
		return (singleShotProcessing);
	}

	public boolean useFrontFacingCamera() {
		return ((GSCameraHost)getHost()).useFrontFacingCamera();
	}
	
	Contract getContract() {
		return ((Contract) getActivity());
	}

	interface Contract {
		boolean isSingleShotMode();

		void setSingleShotMode(boolean mode);
	}

	class GSCameraHost extends SimpleCameraHost implements Camera.ShutterCallback {
		boolean supportsFaces = false;
		private String mOutputPath = null;
		
		public GSCameraHost(Context _ctxt) {
			super(_ctxt);
		}

		@Override
		public void onAutoFocus(boolean success, Camera camera) {
			if (mTakingPicture) {
				if (!isFliteringRequired()) {
					takePicture(false, false, true);
				} else {
					takePicture(true, false, false);
				}
				
				mTakingPicture = false;
			}
			
			hideFocusLayout();
		}
		
		@Override
		public boolean useSingleShotMode() {
			return true;
		}
		
		@Override
		public boolean useFrontFacingCamera() {
			return (getArguments().getBoolean(KEY_USE_FFC));
		}

		@Override
		public void saveImage(byte[] image) {
			super.saveImage(image);
			singleShotProcessing = false;
			mActivity.onPictureTaken();
		}
		
		@Override
		public void saveImage(Bitmap bitmap, int quality) {
			quality = SettingActivity.getImageQualityPercent(getActivity());
			if (isRatioFliteringRequired()) {
				bitmap = adjustImageRatio(bitmap);
			}
			
			super.saveImage(bitmap, quality);
			
			singleShotProcessing = false;
			mActivity.onPictureTaken();
		}
		
		@Override
		public void saveImage(String path) {
			super.saveImage(path);
			singleShotProcessing = false;
			mActivity.onPictureTaken();
		}

		private Bitmap adjustImageRatio(Bitmap bitmap) {
			float bmpWidth = bitmap.getWidth();
			float bmpHeight = bitmap.getHeight();
			int width = 0, height = 0;
			int offsetX = 0, offsetY = 0;
			float ratio = SettingActivity.getImageAspectRatioAsConst(getActivity());
			if (bmpWidth < bmpHeight)
				ratio = 1.0f / ratio;
			
			if (bmpWidth > bmpHeight * ratio) {
				height = (int)bmpHeight;
				width = (int)(height * ratio);
				offsetX = (int)((bmpWidth - width) / 2);
				offsetY = 0;
			} else {
				width = (int)bmpWidth;
				height = (int)(width / ratio);
				offsetX = 0;
				offsetY = (int)((bmpHeight - height) / 2);
			}
			
			if (bmpWidth == width && bmpHeight == height)
				return bitmap;

            if (mBitmapBuffer == null || mBitmapBuffer.getWidth() != width || mBitmapBuffer.getHeight() != height) {
                mBitmapBuffer = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            }
			Canvas canvas = new Canvas(mBitmapBuffer);
			canvas.drawBitmap(bitmap, new Rect(offsetX, offsetY, offsetX + width, offsetY + height), new Rect(0, 0, width, height), null);
			
			bitmap.recycle();
			
			return mBitmapBuffer;
		}
		
		@Override
		public void autoFocusAvailable() {
			if (supportsFaces)
				startFaceDetection();
		}

		@Override
		public void autoFocusUnavailable() {
			stopFaceDetection();
		}

		@Override
		public void onCameraFail(CameraHost.FailureReason reason) {
			super.onCameraFail(reason);

			Toast.makeText(getActivity(),
					"Sorry, but you cannot use the camera now!",
					Toast.LENGTH_LONG).show();
		}

		@Override
		public Parameters adjustPreviewParameters(Parameters parameters) {
			if (parameters.getMaxNumDetectedFaces() > 0) {
				supportsFaces = true;
			} else {
				Toast.makeText(getActivity(),
						"Face detection not available for this camera",
						Toast.LENGTH_LONG).show();
			}

			return (super.adjustPreviewParameters(parameters));
		}

		@Override
		public void configureRecorderProfile(int cameraId, MediaRecorder recorder) {
			String profileID;
			
			if (useFrontFacingCamera())
				profileID = SettingActivity.getFrontVideoProfileID(getActivity());
			else
				profileID = SettingActivity.getBackVideoProfileID(getActivity());
			
			if (!profileID.equals("-1")) {
				recorder.setProfile(CamcorderProfile.get(cameraId, Integer.valueOf(profileID)));
			} else {
				super.configureRecorderProfile(cameraId, recorder);
			}
		}
		
		public void shootSound() {
            if (Utils.getApiLevel() >= 17) {
                AudioManager meng = (AudioManager) getActivity().getSystemService(Context.AUDIO_SERVICE);
                meng.setStreamMute(AudioManager.STREAM_SYSTEM, false);
                int volume = meng.getStreamVolume(AudioManager.STREAM_MUSIC);
                volume = 1;
                if (volume != 0) {
                    try {
                        AssetFileDescriptor afd = getActivity().getAssets().openFd("camera_shutter.mp3");
                        MediaPlayer player = new MediaPlayer();

                        player.setAudioStreamType(AudioManager.STREAM_SYSTEM);
                        player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                        player.prepare();
                        player.start();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
		}
		
		@Override
		public Camera.ShutterCallback getShutterCallback() {
			return this;
		}
		
		/*
		@Override
		public void onFaceDetection(Face[] faces, Camera camera) {
			if (faces.length > 0) {
				long now = SystemClock.elapsedRealtime();

				if (now > lastFaceToast + 10000) {
					Toast.makeText(getActivity(), "I see your face!",
							Toast.LENGTH_LONG).show();
					lastFaceToast = now;
				}
			}
		}
		*/
		
		@Override
		public void onShutter () {
			shootSound();
		}
	}
}