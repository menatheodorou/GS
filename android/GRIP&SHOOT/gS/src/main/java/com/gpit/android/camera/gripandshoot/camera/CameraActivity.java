package com.gpit.android.camera.gripandshoot.camera;

import android.app.Activity;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.drawable.AnimationDrawable;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.hardware.Camera;
import android.hardware.SensorManager;
import android.media.ExifInterface;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.StatFs;
import android.provider.MediaStore;
import android.util.Log;
import android.view.Gravity;
import android.view.OrientationEventListener;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.view.animation.LinearInterpolator;
import android.view.animation.RotateAnimation;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.RadioButton;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.commonsware.cwac.camera.CameraUtils;
import com.commonsware.cwac.camera.components.RotateImageView;
import com.commonsware.cwac.camera.components.RotateLayout;
import com.gpit.android.camera.gripandshoot.Constant;
import com.gpit.android.camera.gripandshoot.DeviceListPopupWindow;
import com.gpit.android.camera.gripandshoot.GSApp;
import com.gpit.android.camera.gripandshoot.InfoActivity;
import com.gpit.android.camera.gripandshoot.R;
import com.gpit.android.camera.gripandshoot.device.BluetoothLeService;
import com.gpit.android.camera.gripandshoot.device.SampleGattAttributes;
import com.gpit.android.camera.gripandshoot.settings.SettingActivity;
import com.gpit.android.util.PrivateAccessor;
import com.gpit.android.util.Utils;

import junit.framework.Assert;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class CameraActivity extends Activity {
	private final static String TAG = "Camera";

	private final static String BCAST_CONFIGCHANGED = "android.intent.action.CONFIGURATION_CHANGED";
	private final static int RESULT_CODE_FOR_PREVIEW = 1000;
	
	public static boolean isCameraActivityOn = false;
	
	// Bluetooth
	public final static String EXTRAS_DEVICE_NAME = "device_name";
	public final static String EXTRAS_DEVICE_ADDRESS = "device_address";
	
	private final static int INITIAL_REPEAT_DELAY = 100;
	private final static int DEFAULT_REPEAT_DELAY = 1;

    private final static int MIN_SIDEBAR_WIDTH = 100;
	
	private final static int MAX_RECORDING_FILE_SIZE = (int) (1.5 * 1024 * 1024 * 1024);
	private final static int MINIMUM_FILE_SIZE = (10 * 1024 * 1024);
	private final static int DONT_TOUCH_SIZE = (200 * 1024 * 1024);

    private final static int SHUTTER_ANIMATION_COUNT = 6;
	
	// Lets test with limited file size for the buttery life
	// private final static int MAX_RECORDING_FILE_SIZE = (int) (12 * 1024 * 1024);
	// private final static int DONT_TOUCH_SIZE = (800 * 1024 * 1024);

	private BluetoothLeService mBluetoothLeService;
	private BluetoothGattCharacteristic mButtonClickGattCharacteristic;
	private boolean mBluetoothConnected = false;
	private BluetoothGattCharacteristic mNotifyCharacteristic;
	private boolean mBtPressed = false;
	private Handler mBtPressingHandler;
	
	private String mDeviceAddress;
	private String mDeviceName;

	// Camera
	private GSCameraFragment mStdCamera = null;
	private GSCameraFragment mFfcCamera = null;
	private GSCameraFragment mCurrentCamera = null;
	private boolean mHasTwoCameras = (Camera.getNumberOfCameras() > 1);
	
	private Shutter mShutter;
	private Uri mImageCaptureUri;
	private int mImageCaptureID;
	private MediaPlayer mMediaPlayer;
	
	private boolean mIsCameraVideoMode = false;
	private boolean mCameraOnRecording = false;
	private Handler mRecordingCounter = new Handler();
	private int mRecordingTime = 0;
	
	private boolean mIsCameraFrontMode;
	private String mCameraFlashMode;
	
	// Auto-Focus
	private final static int AUTO_FOCUS_THRESHOLD = 100;
	
	private Bitmap mPreviewBitmap;
	
	private String mSelectedFolder;
	
	// Orientation
	private OrientationEventListener mOrientationListener = null;
	private int mPrevOrientation = OrientationEventListener.ORIENTATION_UNKNOWN;
	private int mCurrOrientation = 0;
	private boolean mInitialized = false;
    private float mLastX = 0;
    private float mLastY = 0;
    private float mLastZ = 0;
	
	// UI Elements
    private ViewGroup mVGRoot;
    private ViewGroup mVGMode;
    private ViewGroup mVGStatus;
    
    private DeviceListPopupWindow mDeviceListPopupWindow;
    
    private RotateLayout mFLRecordingTime;
	private TextView mTVRecordingTime;
	private RotateImageView mIBFaceMode;
	private RotateImageView mIBNextCameraMode;
	private RotateImageView mIBFlashMode;
	private RotateImageView mIBSetting;
	private RotateImageView mIBDeviceStatus;
	private RotateImageView mIBStart;
	private RotateImageView mIBInfo;
	private RotateImageView mIVPreview;
	private ImageView mIVEffect;
    private AnimationDrawable mShutterAnimationDrawble;
    private Drawable[] mShutterAnimations = new Drawable[SHUTTER_ANIMATION_COUNT];

	private boolean isPaused = false;
	
	// Bitmap table
	private HashMap<Integer, Bitmap> mBitmapTable = new HashMap<Integer, Bitmap>();
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setContentView(R.layout.activity_camera);
		
		if (Constant.ENABLE_GS_DEVICE) {
			final Intent intent = getIntent();
			mDeviceName = intent.getStringExtra(EXTRAS_DEVICE_NAME);
			mDeviceAddress = intent.getStringExtra(EXTRAS_DEVICE_ADDRESS);
		}

		// init Camera
		initCamera();
		
		initUI();
		updateUI();
		
		isCameraActivityOn = true;
		
		if (mBluetoothLeService != null) {
			final boolean result = mBluetoothLeService.connect(mDeviceAddress);
			Log.d(TAG, "Connect request result=" + result);
		}
	}

	@Override
	public void onBackPressed() {
		setResult(0);

		super.onBackPressed();
	}
	/************************* Initialization *****************************/
	private void initCamera() {
		mStdCamera = GSCameraFragment.newInstance(this, false);
		if (mHasTwoCameras) {
			mFfcCamera = GSCameraFragment.newInstance(this, true);
		}
		mCurrentCamera = mStdCamera;
		
		// Load preferences
		mCameraFlashMode = SettingActivity.getFlashMode(mIsCameraVideoMode);
		
		updateCameraFragment();
	}
	
	private void initPopup() {
		mDeviceListPopupWindow = DeviceListPopupWindow.newInstance(this);
    	
        mDeviceListPopupWindow.setOutsideTouchable(true);
        mDeviceListPopupWindow.setFocusable(true);
        // http://stackoverflow.com/questions/3121232/android-popup-window-dismissal
        mDeviceListPopupWindow.setBackgroundDrawable(new BitmapDrawable());
        mDeviceListPopupWindow.setInputMethodMode(PopupWindow.INPUT_METHOD_NOT_NEEDED);
        mDeviceListPopupWindow.setDeviceList(GSApp.getInstance().deviceList);
	}
	
	private void initUI() {
		initPopup();
		
		mVGRoot = (ViewGroup) findViewById(R.id.rlRoot);
		
		mVGMode = (ViewGroup) findViewById(R.id.llMode);
		mVGStatus = (ViewGroup) findViewById(R.id.llStatus);
		
		mFLRecordingTime = (RotateLayout) findViewById(R.id.flRecordingTime);
		mTVRecordingTime = (TextView) findViewById(R.id.tvRecordingTime);
		
		mIBFaceMode = (RotateImageView) findViewById(R.id.ibFaceMode);
		mIBFaceMode.setOnClickListener(mFaceModeClickListener);
		
		mIBNextCameraMode = (RotateImageView) findViewById(R.id.ibCameraMode);
		mIBNextCameraMode.setOnClickListener(mCameraModeClickListener);
		
		mIBFlashMode = (RotateImageView) findViewById(R.id.ibFlashMode);
		mIBFlashMode.setOnClickListener(mFlashModeClickListener);
		
		mIBSetting = (RotateImageView) findViewById(R.id.ibSetting);
		mIBSetting.setOnClickListener(mSettingClickListener);
		
		mIBDeviceStatus = (RotateImageView) findViewById(R.id.ibDeviceStatus);
		mIBDeviceStatus.setOnClickListener(mDeviceStatusClickListener);
		
		mIBStart = (RotateImageView) findViewById(R.id.ibStart);
		mIBStart.setOnClickListener(mStartOrStopClickListener);
		
		mIBInfo = (RotateImageView) findViewById(R.id.ibInfo);
		mIBInfo.setOnClickListener(mInfoClickListener);
		
		mIVPreview = (RotateImageView) findViewById(R.id.ivPreview);
		mIVPreview.setOnClickListener(mPreviewClickListener);
		
		mIVEffect = (ImageView) findViewById(R.id.ivEffect);
		// Pre-load shutter animation drawable
        mShutterAnimationDrawble = (AnimationDrawable) getResources().getDrawable(R.drawable.anim_camera_shutter);
        for (int i = 0 ; i < SHUTTER_ANIMATION_COUNT ; i++) {
            mShutterAnimations[i] = getResources().getDrawable((Integer) PrivateAccessor.getPrivateField(R.drawable.class, R.drawable.class, "ic_camera_shuttter" + (i + 1)));
        }

		mOrientationListener = new OrientationEventListener(this, SensorManager.SENSOR_DELAY_UI) {
            public void onOrientationChanged(int orientation) {
                // Add 90 degree because we are on the landscape mode
                orientation += 90;

                mPrevOrientation = CameraUtils.roundOrientation(orientation, mPrevOrientation);

                mFLRecordingTime.setOrientation(mPrevOrientation, true);
                mIBFaceMode.setOrientation(mPrevOrientation, true);
                mIBNextCameraMode.setOrientation(mPrevOrientation, true);
                mIBFlashMode.setOrientation(mPrevOrientation, true);
                mIBSetting.setOrientation(mPrevOrientation, true);
                mIBDeviceStatus.setOrientation(mPrevOrientation, true);
                mIBStart.setOrientation(mPrevOrientation, true);
                mIBInfo.setOrientation(mPrevOrientation, true);
                mIVPreview.setOrientation(mPrevOrientation, true);
            }
        };;
	}
	
	@Override
	protected void onResume() {
		super.onResume();

		mSelectedFolder = mCurrentCamera.getHost().getOutputDirPath();

        bindService(this);

		mOrientationListener.enable();
		
		// Load options based on current camera setting
        mIsCameraFrontMode = mCurrentCamera.useFrontFacingCamera();
        
        // Block screen-lock timeout
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        
        // Register bluetooth gatt listener
     	registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter());
     	
     	// mSensorManager.registerListener(this, mAccelerometer, SensorManager.SENSOR_DELAY_NORMAL);

        updateUI();
	}

	@Override
	protected void onPause() {
		super.onPause();
		
		isPaused = true;
		mOrientationListener.disable();
		// mSensorManager.unregisterListener(this);
		
		// Resume screen-lock timout
		getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        unbindService();

		if (Constant.ENABLE_GS_DEVICE) {
			try {
				// Unregister bluetooth gatt listener
				unregisterReceiver(mGattUpdateReceiver);
			} catch (Exception e) {}
		}
		
		if (mBluetoothLeService != null) {
			mBluetoothLeService.disconnect();
		}
	}

	@Override
	public void onWindowFocusChanged(boolean hasFocus) {
	    super.onWindowFocusChanged(hasFocus);
	}
	
	@Override
	public void onStop() {
	    super.onStop();
	}
	
	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
	    super.onActivityResult(requestCode, resultCode, data);

	    Assert.assertTrue(requestCode == RESULT_CODE_FOR_PREVIEW);

        updateUI();
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();

		destroy();
	}
	
	private void destroy() {
		if (mBluetoothLeService != null) {
			mBluetoothLeService.disconnect();
		}
		
		if (mCameraOnRecording)
			stopRecording();
		
		isCameraActivityOn = false;
		
		// Unregister orientation receiver
		// unregisterReceiver(mBroadcastReceiver);
	}

	/************************** UPDATE UI *************************/
	private void updateUI() {
		if (mCameraFlashMode == null)
			mCameraFlashMode = mCurrentCamera.getFlashMode();
		
		if (mIsCameraVideoMode) {
			updateVideoModeUI();
		} else {
			updatePictureModeUI();
		}
		
		if (mIsCameraFrontMode) {
			mIBFlashMode.setVisibility(View.INVISIBLE);
		} else {
			mIBFlashMode.setVisibility(View.VISIBLE);
			
			// Update flash mode
            String flashMode = mCameraFlashMode;
			if (flashMode == null) {
				mIBFlashMode.setImageResource(R.drawable.bt_flash_off_touchable);
			} else if (flashMode.equals(Camera.Parameters.FLASH_MODE_ON) ||
                    flashMode.equals(Camera.Parameters.FLASH_MODE_TORCH)) {
				mIBFlashMode.setImageResource(R.drawable.bt_flash_on_touchable);
                if (mCameraOnRecording) {
                    flashMode = Camera.Parameters.FLASH_MODE_TORCH;
                } else {
                    flashMode = Camera.Parameters.FLASH_MODE_ON;
                }
			} else if (flashMode.equals(Camera.Parameters.FLASH_MODE_AUTO)) {
				mIBFlashMode.setImageResource(R.drawable.bt_flash_auto_on_touchable);
			} else {
				Assert.assertTrue(mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_OFF));
				mIBFlashMode.setImageResource(R.drawable.bt_flash_off_touchable);
			}
			
			if (flashMode != null) mCurrentCamera.setFlashMode(flashMode);
		}
		
		// Update device connection status
		if (mBluetoothConnected)
			mIBDeviceStatus.setImageResource(R.drawable.device_connect_connected);
		else
			mIBDeviceStatus.setImageResource(R.drawable.device_connect_disconnected);
		
		// Show preview image
		if (mPreviewBitmap != null)
			mIVPreview.setBitmap(mPreviewBitmap);

            updateSideBar();
	}

    private void updateSideBar() {
        if (mIsCameraVideoMode) return;

        // Adjust size
        int screenWidth = Utils.getScreenWidth(this);
        int screenHeight = Utils.getScreenHeight(this);

        float bmpWidth = screenWidth;
        float bmpHeight = screenHeight;
        int width = 0, height = 0;
        int offsetX = 0, offsetY = 0;
        float ratio = SettingActivity.getImageAspectRatioAsConst(this);
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

        if (offsetX < MIN_SIDEBAR_WIDTH) {
            ViewGroup.LayoutParams params = mVGMode.getLayoutParams();
            params.width = ViewGroup.LayoutParams.WRAP_CONTENT;
            mVGMode.setLayoutParams(params);

            params = mVGStatus.getLayoutParams();
            params.width = ViewGroup.LayoutParams.WRAP_CONTENT;
            mVGStatus.setLayoutParams(params);

            mVGMode.setAlpha(0.7f);
            mVGStatus.setAlpha(0.7f);
        } else {
            ViewGroup.LayoutParams params = mVGMode.getLayoutParams();
            params.width = offsetX;
            mVGMode.setLayoutParams(params);

            params = mVGStatus.getLayoutParams();
            params.width = offsetX;
            mVGStatus.setLayoutParams(params);

            mVGMode.setAlpha(1);
            mVGStatus.setAlpha(1);
        }
    }
	
	private void setImageResource(RotateImageView imageView, int resId) {
		Bitmap bitmap = mBitmapTable.get(resId);
		if (bitmap == null) {
			bitmap = BitmapFactory.decodeResource(getResources(), resId);
			if (bitmap == null)
				return;
			
			mBitmapTable.put(resId, bitmap);
		}
		
		imageView.setBitmap(bitmap);
	}
	private void updateVideoModeUI() {
		// Recording time should be formalized
		// int mins = mRecordingTime / 60;
		// int secs = mRecordingTime % 60;
		String time = Utils.getUTCDateString(mRecordingTime * 1000, "mm:ss");
		mTVRecordingTime.setText(time);
		
		mIBNextCameraMode.setImageResource(R.drawable.bt_take_picture_touchable);
		
		// Update start button depend on camera mode
		if (mIsCameraVideoMode) {
			mTVRecordingTime.setVisibility(View.VISIBLE);
		} else {
			mTVRecordingTime.setVisibility(View.INVISIBLE);
        }

        if (mCameraOnRecording) {
            // Visible/Invisible functions
            mIBFaceMode.setVisibility(View.INVISIBLE);
            mIBNextCameraMode.setVisibility(View.INVISIBLE);
            mIBFlashMode.setVisibility(View.VISIBLE);
            mIBSetting.setVisibility(View.INVISIBLE);

            mIBStart.setImageResource(R.drawable.anim_video_recording);
            AnimationDrawable frameAnimation = (AnimationDrawable) mIBStart.getDrawable();
            frameAnimation.setCallback(mIBStart);
            frameAnimation.setVisible(true, true);
            frameAnimation.start();
        } else {
			mIBFaceMode.setVisibility(View.VISIBLE);
			mIBNextCameraMode.setVisibility(View.VISIBLE);
			mIBFlashMode.setVisibility(View.VISIBLE);
			mIBSetting.setVisibility(View.VISIBLE);
			
			mIBStart.setImageResource(R.drawable.bt_start_record_video_touchable);
            if (mIBStart.getDrawable() instanceof  AnimationDrawable) {
                AnimationDrawable frameAnimation = (AnimationDrawable) mIBStart.getDrawable();
                frameAnimation.setCallback(mIBStart);
                frameAnimation.setVisible(true, false);
                frameAnimation.stop();
            }
		}
	}
	
	private void updatePictureModeUI() {
		mIBNextCameraMode.setImageResource(R.drawable.bt_video_mode_touchable);
		
		mIBFaceMode.setVisibility(View.VISIBLE);
		mIBNextCameraMode.setVisibility(View.VISIBLE);
		mTVRecordingTime.setVisibility(View.INVISIBLE);
		mIBFlashMode.setVisibility(View.VISIBLE);
		mIBSetting.setVisibility(View.VISIBLE);
		
		if (mCurrentCamera.isSingleShotProcessing()) {
			mIBFaceMode.setEnabled(false);
			mIBNextCameraMode.setEnabled(false);
			mIBFlashMode.setEnabled(false);
			mIBStart.setEnabled(false);
			mIBSetting.setEnabled(false);
		} else {
			mIBFaceMode.setEnabled(true);
			mIBNextCameraMode.setEnabled(true);
			mIBFlashMode.setEnabled(true);
			mIBStart.setEnabled(true);
			mIBSetting.setEnabled(true);
			
			mIBStart.setImageResource(R.drawable.bt_take_picture_touchable);
		}
	}

	private void updateCameraFragment() {
		getFragmentManager().beginTransaction().replace(R.id.container, mCurrentCamera).commit();

		mShutter = new Shutter(mCurrentCamera, this);
	}
	
	/************************************ Animation ********************************/
	private void rotateControlView(ViewGroup viewGroup, int fromDegree, int toDegree, boolean recursive) {
		View subView;
		for (int i = 0 ; i < viewGroup.getChildCount() ; i++) {
			subView = viewGroup.getChildAt(i);
			
			if (!subView.isShown())
				continue;
			
			if (recursive && subView instanceof ViewGroup) {
				rotateControlView((ViewGroup)subView, fromDegree, toDegree, recursive);
				continue;
			}
			
			if ((subView instanceof ImageView) ||
				(subView instanceof TextView) ||
				(subView instanceof RadioButton) ||
				(subView instanceof ToggleButton)) {
				rotateSelf(subView, fromDegree, toDegree);
			}
		}
	}
	
	private void rotateView(ViewGroup viewGroup, int fromDegree, int toDegree) {
		View subView;
		for (int i = 0 ; i < viewGroup.getChildCount() ; i++) {
			subView = viewGroup.getChildAt(i);
			
			if (subView instanceof ViewGroup) {
				rotateView((ViewGroup) subView, fromDegree, toDegree);
				continue;
			}
			
			rotateSelf(subView, fromDegree, toDegree);
		}
	}
    
	private void rotateSelf(View view, int fromDegree, int toDegree) {
		RotateAnimation mAnimation = new RotateAnimation(fromDegree, toDegree,
				RotateAnimation.RELATIVE_TO_SELF, 0.5f,
				RotateAnimation.RELATIVE_TO_SELF, 0.5f);

		mAnimation.setInterpolator(new LinearInterpolator());
		mAnimation.setDuration(150);
		mAnimation.setFillAfter(true);

		view.startAnimation(mAnimation);
	}

    public void shutterAnimation(boolean start) {
        // mIVEffect.setBackgroundResource(R.drawable.red_border);

        if (start) {
            mIVEffect.setImageResource(R.drawable.anim_camera_shutter);
            mShutterAnimationDrawble = (AnimationDrawable) mIVEffect.getDrawable();

            mShutterAnimationDrawble.setCallback(mIVEffect);
            mShutterAnimationDrawble.setVisible(true, false);
            mShutterAnimationDrawble.start();
        } else {
            // mIVEffect.setImageResource(R.drawable.anim_camera_shutter_stop);
            mIVEffect.setImageResource(0);
            mShutterAnimationDrawble.stop();
        }
    }
	
	/**************************** CAMERA ****************************/
	private void takePicture() {
		// Update save path
		mCurrentCamera.getHost().setOutputDirPath(SettingActivity.getImageOutputPath());
				
		if (!mCurrentCamera.isSingleShotProcessing()) {
			shutterAnimation(true);
			mCurrentCamera.takePicture();
		}
	}
	
	private boolean startRecording(boolean isContinue) {
		// Update save path
		mCurrentCamera.getHost().setOutputDirPath(SettingActivity.getVideoOutputPath());
		
		try {
			long freeSize = getAvailableExternalMemorySize() - DONT_TOUCH_SIZE;
			long recordSize = Math.min(freeSize, MAX_RECORDING_FILE_SIZE);
			if (recordSize > MINIMUM_FILE_SIZE) {
				mCurrentCamera.record(recordSize, new MediaRecorder.OnInfoListener() {
				    public void onInfo(MediaRecorder mr, int what, int extra) {
					    if(what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_FILESIZE_REACHED) {
					         Toast.makeText(CameraActivity.this, "Reached maximum recording file size. Continue recording with new file.", Toast.LENGTH_LONG).show();
					         try {
								mCurrentCamera.stopRecording();
								String recordPath = mCurrentCamera.getOutputPath();
								mImageCaptureID = addToMediaGallery(recordPath, false);
								mPreviewBitmap = getThumbnailFromVideo(mImageCaptureID);
								
								startRecording(true);
								updateUI();
							} catch (Exception e) {
								e.printStackTrace();
							}
					    }
				    }
				}, new MediaRecorder.OnErrorListener() {
					@Override
					public void onError(MediaRecorder mr, int what, int extra) {
						if(what == MediaRecorder.MEDIA_RECORDER_ERROR_UNKNOWN) {
					         Toast.makeText(CameraActivity.this, "Video recording stopped. Please free up more storage on device", Toast.LENGTH_LONG).show();
					         stopRecording();
					         updateUI();
					    }
					}
				});
				
				mCameraOnRecording = true;
				if (!isContinue) {
					mRecordingTime = 0;
					recordingCount();
				}
			} else {
				mCameraOnRecording = false;
		        updateUI();
				Toast.makeText(CameraActivity.this, "Video recording stopped. Please free up more storage on device", Toast.LENGTH_LONG).show();
				return false;
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return mCameraOnRecording;
	}
	
	private void stopRecording() {
		try {
			mCurrentCamera.stopRecording();
		} catch (Exception e) {
			e.printStackTrace();
		}
		mCameraOnRecording = false;
		
		String recordPath = mCurrentCamera.getOutputPath();
		mImageCaptureID = addToMediaGallery(recordPath, false);
		mPreviewBitmap = getThumbnailFromVideo(mImageCaptureID);
		
		updateUI();
	}

	private void recordingCount() {
		mRecordingCounter.postDelayed(new Runnable() {
			@Override
			public void run() {
				mRecordingTime++;
				if (mRecordingTime >= (60 * 60))
					mRecordingTime = 0;
				
				if (mCameraOnRecording) {
					recordingCount();
				}
				
				updateUI();
			}
		}, 1000);
	}
	
	private boolean isZooming = false;
	public void zoomin(final Runnable runnable) {
		if (!isZooming) {
			int level = mCurrentCamera.getZoomLevel();
			isZooming = true;
			try {
				mCurrentCamera.zoomTo(level + 1).onComplete(new Runnable() {
					@Override
					public void run() {
						isZooming = false;
						if (runnable != null) {
							runnable.run();
						}
					}
				}).go();
			} catch (Exception e) {
				isZooming = false;
			}
		}
	}
	
	public void zoomout() {
		if (!isZooming) {
			int level = mCurrentCamera.getZoomLevel();
			isZooming = true;
			try {
				mCurrentCamera.zoomTo(level - 1).onComplete(new Runnable() {
					@Override
					public void run() {
						isZooming = false;
					}
				}).go();
			} catch (Exception e) {
				isZooming = false;
			}
		}
	}

	/**************************** Event Listener ****************************/
	private OnClickListener mFaceModeClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Assert.assertTrue(mHasTwoCameras);
			
			if (mIsCameraFrontMode) {
				mCurrentCamera = mStdCamera;
			} else {
				mCurrentCamera = mFfcCamera;
			}
			 
			updateCameraFragment();
			mIsCameraFrontMode = !mIsCameraFrontMode;
			
			updateUI();
		}
	};
	
	private OnClickListener mCameraModeClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Assert.assertTrue(!mCameraOnRecording);
			Assert.assertTrue(!mCurrentCamera.isSingleShotProcessing());
			
			mIsCameraVideoMode = !mIsCameraVideoMode;
            mRecordingTime = 0;
            
            // Update flash mode
            mCameraFlashMode = SettingActivity.getFlashMode(mIsCameraVideoMode);

			updateUI();
		}
	};
	
	private OnClickListener mFlashModeClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			if (mIsCameraVideoMode) {
				if (mCameraFlashMode == null) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_OFF;
				} else if (mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_OFF)) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_TORCH;
				} else if (mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_ON) ||
						mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_TORCH)) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_OFF;
				} else {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_OFF;
				}
			} else {
				if (mCameraFlashMode == null) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_AUTO;
				} else if (mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_OFF)) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_ON;
				} else if (mCameraFlashMode.equals(Camera.Parameters.FLASH_MODE_ON)) {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_AUTO;
				} else {
					mCameraFlashMode = Camera.Parameters.FLASH_MODE_OFF;
				}
			}

			SettingActivity.setFlashMode(mCameraFlashMode, mIsCameraVideoMode);
			
			updateUI();
		}
	};
	
	private OnClickListener mSettingClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Intent intent = new Intent(CameraActivity.this, SettingActivity.class);
			startActivity(intent);
		}
	};
	
	private OnClickListener mDeviceStatusClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			if (!mDeviceListPopupWindow.isShowing())
	    		mDeviceListPopupWindow.showAtLocation(mVGRoot, Gravity.TOP | Gravity.RIGHT, 
	    				Utils.getPixels(getResources(), 50), Utils.getPixels(getResources(), 50));
		}
	};
	
	private OnClickListener mStartOrStopClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			if (mCurrentCamera.isSingleShotProcessing())
				return;
			
			if (mIsCameraVideoMode) {
				if (!mCameraOnRecording) {
					startRecording(false);
				} else {
					// Stop recording and start preview again.
					stopRecording();
				}
			} else {
				takePicture();
			}
			
			updateUI();
		}
	};
	
	private OnClickListener mInfoClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			Intent intent = new Intent(CameraActivity.this, InfoActivity.class);
			startActivity(intent);
		}
	};
	
	private OnClickListener mPreviewClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			// replace with your own uri
			if (mCurrentCamera.getOutputPath() != null) {
				Intent intent = new Intent(Intent.ACTION_VIEW,
						Uri.parse("content://media/internal/images/media"));
				startActivityForResult(intent, RESULT_CODE_FOR_PREVIEW);
			}
		}
	};

	public BroadcastReceiver mBroadcastReceiver = new BroadcastReceiver() {
		private int mPrevOrientation = -1;
		private int mCurrOrientation = -1;
		
        @Override
        public void onReceive(Context context, Intent myIntent) {
            if ( myIntent.getAction().equals( BCAST_CONFIGCHANGED ) ) {
                Log.d(TAG, "received->" + BCAST_CONFIGCHANGED);
                if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE) {
                	mCurrOrientation = 0;
                } else {
                	mCurrOrientation = 90;
                }
                
                if (mPrevOrientation == -1) {
                	mPrevOrientation = mCurrOrientation;
                }
                
                rotateControlView(mVGMode, mPrevOrientation, mCurrOrientation, true);
				rotateControlView(mVGStatus, mPrevOrientation, mCurrOrientation, true);                
            }
        }
    };
    
	public void onPictureTaken() {
        Log.i(GSApp.TAG, "Step1: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));

		mImageCaptureID = addToMediaGallery(mCurrentCamera.getOutputPath(), true);
		mPreviewBitmap = getThumbnailFromImage(mImageCaptureID);
		
		// mCurrentCamera.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);

        Log.i(GSApp.TAG, "Step2: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));

		runOnUiThread(new Runnable() {
			@Override
			public void run() {
                Log.i(GSApp.TAG, "Step3: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));

				updateUI();
				CameraActivity.this.shutterAnimation(false);

                Log.i(GSApp.TAG, "Step4: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));

				mCurrentCamera.startPreview();

                Log.i(GSApp.TAG, "Step5: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));
			}
		});
	}
	
	/**************************** UTILS ***************************/
	public static boolean externalMemoryAvailable() {
        return android.os.Environment.getExternalStorageState().equals(
                android.os.Environment.MEDIA_MOUNTED);
    }
	
	public static long getAvailableExternalMemorySize() {
        if (externalMemoryAvailable()) {
            File path = Environment.getExternalStorageDirectory();
            StatFs stat = new StatFs(path.getPath());
            long blockSize = stat.getBlockSizeLong();
            long availableBlocks = stat.getAvailableBlocksLong();
            return (availableBlocks * blockSize);
        } else {
            return -1;
        }
    }
	
	private int addToMediaGallery(String path, boolean isImage) {
		int id = 0;
		if (isImage) {
			try {
				getContentResolver().delete(
						MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
						MediaStore.Images.Media.DATA + "='" + path + "'",
						null);
			} catch (Exception e) {
				e.printStackTrace();

			}
			
			ContentValues values = new ContentValues();
			values.put(MediaStore.Images.Media.DATA, path);
			values.put(MediaStore.Images.Media.DATE_TAKEN, new File(path).lastModified());
	
			mImageCaptureUri = getContentResolver().insert(
					MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
	
			Cursor cursor = getContentResolver().query(
		            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
		            new String[] { MediaStore.Images.Media._ID },
		            MediaStore.Images.Media.DATA + "=? ",
		            new String[] { path }, null);
		    if (cursor != null && cursor.moveToFirst()) {
		    	id = cursor.getInt(cursor
		                .getColumnIndex(MediaStore.MediaColumns._ID));
		    }
		} else {
			try {
				getContentResolver().delete(
						MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
						MediaStore.Video.Media.DATA + "='" + path + "'",
						null);
			} catch (Exception e) {
				e.printStackTrace();

			}
			
			ContentValues values = new ContentValues();
			values.put(MediaStore.Video.Media.DATA, path);
			values.put(MediaStore.Video.Media.DATE_TAKEN, new File(path).lastModified());
	
			mImageCaptureUri = getContentResolver().insert(
					MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values);
	
			Cursor cursor = getContentResolver().query(
		            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
		            new String[] { MediaStore.Video.Media._ID },
		            MediaStore.Video.Media.DATA + "=? ",
		            new String[] { path }, null);
		    if (cursor != null && cursor.moveToFirst()) {
		    	id = cursor.getInt(cursor
		                .getColumnIndex(MediaStore.MediaColumns._ID));
		    }
		}
	    
		// to notify change
		getContentResolver().notifyChange(Uri.parse("file://" + path), null);
		
		return id;
	}
	
	public Bitmap getThumbnailFromImage(int id) {
		Bitmap bitmap = MediaStore.Images.Thumbnails.getThumbnail(
                getContentResolver(), id,
                MediaStore.Images.Thumbnails.MINI_KIND,
                (BitmapFactory.Options) null );
		
		return bitmap;
	}
	
	public Bitmap getThumbnailFromVideo(int id) {
		Bitmap bitmap = MediaStore.Video.Thumbnails.getThumbnail(
                getContentResolver(), id,
                MediaStore.Images.Thumbnails.MINI_KIND,
                (BitmapFactory.Options) null );
		
		return bitmap;
	}

	/**
	 * Method which rotates a bitmap in case it needs it
	 * @param bmp - the bitmap which we try to rotate
	 * @param path - path of the file in the bitmap
	 * @return
	 */
	public static Bitmap getRotatedBitmap (Bitmap bmp, String path)
	{
		
        try {
            ExifInterface exif = new ExifInterface(path);
            int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1);

            Matrix matrix = new Matrix();
            if (orientation == 6) {
                matrix.postRotate(90);
            }
            else if (orientation == 3) {
                matrix.postRotate(180);
            }
            else if (orientation == 8) {
                matrix.postRotate(270);
            } else {
            	return bmp;
            }
            
            return Bitmap.createBitmap(bmp, 0, 0, bmp.getWidth(), bmp.getHeight(), matrix, true); // rotating bitmap
        }
        catch (Exception e) {
        	
        	return null;
        }
	}
	

	/************************** BLUETOOTH ***************************/
	public void bindService(Activity activity) {
		Intent gattServiceIntent = new Intent(activity,
				BluetoothLeService.class);
		bindService(gattServiceIntent, mServiceConnection, BIND_AUTO_CREATE);
	}
	
	public void unbindService() {
        if (!Constant.ENABLE_GS_DEVICE) return;

        try {
            unbindService(mServiceConnection);
            mBluetoothLeService = null;
        } catch (Exception e) {}
	}
	
	private void updateConnectionState(final int resourceId) {
		runOnUiThread(new Runnable() {
			@Override
			public void run() {
				// mConnectionState.setText(resourceId);
			}
		});
	}
	
	// Code to manage Service lifecycle.
	private final ServiceConnection mServiceConnection = new ServiceConnection() {
		@Override
		public void onServiceConnected(ComponentName componentName,
				IBinder service) {
			mBluetoothLeService = ((BluetoothLeService.LocalBinder) service)
					.getService();
			// Automatically connects to the device upon successful start-up
			// initialization.
			mBluetoothLeService.connect(mDeviceAddress);
		}
	
		@Override
		public void onServiceDisconnected(ComponentName componentName) {
			mBluetoothLeService = null;
			CameraActivity.this.finish();
		}
	};
	
	private void updateButtonEventData(String data) {
		data = data.substring(4).trim();
		if (data != null) {
			if (data.equals(SampleGattAttributes.GS_BUTTON_SHOOT)) {
				mStartOrStopClickListener.onClick(mIBStart);
			} else if (data.equals(SampleGattAttributes.GS_BUTTON_PLUS_UP)) {
				mBtPressed = false;
				// Toast.makeText(CameraActivity.this, "Plus Up", Toast.LENGTH_LONG).show();
			} else if (data.equals(SampleGattAttributes.GS_BUTTON_PLUS_DOWN)) {
				mBtPressed = true;
				
				// zoomin();
				handleZoomingIn(INITIAL_REPEAT_DELAY);
				// Toast.makeText(CameraActivity.this, "Plus Down", Toast.LENGTH_LONG).show();
			} else if (data.equals(SampleGattAttributes.GS_BUTTON_MINUS_UP)) {
				mBtPressed = false;
				// Toast.makeText(CameraActivity.this, "Minus Up", Toast.LENGTH_LONG).show();
			} else if (data.equals(SampleGattAttributes.GS_BUTTON_MINUS_DOWN)) {
				mBtPressed = true;
				
				// zoomout();
				handleZoomingOut(INITIAL_REPEAT_DELAY);
				// Toast.makeText(CameraActivity.this, "Minus Down", Toast.LENGTH_LONG).show();
			}
		}
	}
	
	private void handleZoomingIn(int delay) {
		mBtPressingHandler = new Handler();
		if (delay < 0) {
			delay = INITIAL_REPEAT_DELAY;
		}
		
		mBtPressingHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				if (mBtPressed) {
					zoomin(null);
					handleZoomingIn(DEFAULT_REPEAT_DELAY);
				}
			}
			
		}, delay);
	}
	
	private void handleZoomingOut(int delay) {
		mBtPressingHandler = new Handler();
		if (delay < 0) {
			delay = INITIAL_REPEAT_DELAY;
		}
		mBtPressingHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				if (mBtPressed) {
					zoomout();
					handleZoomingOut(DEFAULT_REPEAT_DELAY);
				}
			}
			
		}, delay);
	}
	
	// Handles various events fired by the Service.
	// ACTION_GATT_CONNECTED: connected to a GATT server.
	// ACTION_GATT_DISCONNECTED: disconnected from a GATT server.
	// ACTION_GATT_SERVICES_DISCOVERED: discovered GATT services.
	// ACTION_DATA_AVAILABLE: received data from the device. This can be a
	// result of read
	// or notification operations.
	private final BroadcastReceiver mGattUpdateReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			final String action = intent.getAction();
			if (BluetoothLeService.ACTION_GATT_CONNECTED.equals(action)) {
				mBluetoothConnected = true;
				updateConnectionState(R.string.connected);
				invalidateOptionsMenu();
				
				updateUI();
			} else if (BluetoothLeService.ACTION_GATT_DISCONNECTED
					.equals(action)) {
				mBluetoothConnected = false;
				updateConnectionState(R.string.disconnected);
				invalidateOptionsMenu();
				// clearUI();
	
				// Connect device
				mBluetoothLeService.connect(mDeviceAddress);
				updateUI();
			} else if (BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED
					.equals(action)) {
				// Show all the supported services and characteristics on the
				// user interface.
				addGattServices(mBluetoothLeService.getSupportedGattServices());
				addCallbackForGattButtonClickCharacteristic();
			} else if (BluetoothLeService.ACTION_DATA_AVAILABLE.equals(action)) {
				updateButtonEventData(intent
						.getStringExtra(BluetoothLeService.EXTRA_DATA));
			}
		}
	};
	
	// Demonstrates how to iterate through the supported GATT
	// Services/Characteristics.
	// In this sample, we populate the data structure that is bound to the
	// ExpandableListView
	// on the UI.
	private void addGattServices(List<BluetoothGattService> gattServices) {
		if (gattServices == null)
			return;
		String uuid = null;
	
		// Loops through available GATT Services.
		for (BluetoothGattService gattService : gattServices) {
			uuid = gattService.getUuid().toString();
	
			ArrayList<HashMap<String, String>> gattCharacteristicGroupData = new ArrayList<HashMap<String, String>>();
			List<BluetoothGattCharacteristic> gattCharacteristics = gattService
					.getCharacteristics();
			ArrayList<BluetoothGattCharacteristic> charas = new ArrayList<BluetoothGattCharacteristic>();
	
			// Loops through available Characteristics.
			for (BluetoothGattCharacteristic gattCharacteristic : gattCharacteristics) {
				uuid = gattCharacteristic.getUuid().toString();
				if (uuid.equals(SampleGattAttributes.GS_SHOOT_BUTTON))
					mButtonClickGattCharacteristic = gattCharacteristic;
			}
		}
	}
	
	// If a given GATT characteristic is selected, check for supported features.
	// This sample
	// demonstrates 'Read' and 'Notify' features. See
	// http://d.android.com/reference/android/bluetooth/BluetoothGatt.html for
	// the complete
	// list of supported characteristic features.
	private boolean addCallbackForGattButtonClickCharacteristic() {
		if (mButtonClickGattCharacteristic != null) {
			final BluetoothGattCharacteristic characteristic = mButtonClickGattCharacteristic;
			final int charaProp = characteristic.getProperties();
			if ((charaProp | BluetoothGattCharacteristic.PROPERTY_READ) > 0) {
				// If there is an active notification on a characteristic, clear
				// it first so it doesn't update the data field on the user
				// interface.
				if (mNotifyCharacteristic != null) {
					mBluetoothLeService.setCharacteristicNotification(
							mNotifyCharacteristic, false);
					mNotifyCharacteristic = null;
				}
				mBluetoothLeService.readCharacteristic(characteristic);
			}
			if ((charaProp | BluetoothGattCharacteristic.PROPERTY_NOTIFY) > 0) {
				mNotifyCharacteristic = characteristic;
				mBluetoothLeService.setCharacteristicNotification(
						characteristic, true);
			}
			return true;
		}
		return false;
	}
	
	private static IntentFilter makeGattUpdateIntentFilter() {
		final IntentFilter intentFilter = new IntentFilter();
		intentFilter.addAction(BluetoothLeService.ACTION_GATT_CONNECTED);
		intentFilter.addAction(BluetoothLeService.ACTION_GATT_DISCONNECTED);
		intentFilter
				.addAction(BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED);
		intentFilter.addAction(BluetoothLeService.ACTION_DATA_AVAILABLE);
		return intentFilter;
	}
}
