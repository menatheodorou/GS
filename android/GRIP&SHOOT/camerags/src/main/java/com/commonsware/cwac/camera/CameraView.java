/***
  Copyright (c) 2013 CommonsWare, LLC
  Portions Copyright (C) 2007 The Android Open Source Project
  
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

package com.commonsware.cwac.camera;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.pm.ActivityInfo;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.RectF;
import android.hardware.Camera;
import android.hardware.Camera.CameraInfo;
import android.hardware.Camera.Parameters;
import android.media.AudioManager;
import android.media.MediaRecorder;
import android.os.Build;
import android.util.AttributeSet;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.MotionEvent;
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.View;
import android.widget.FrameLayout;

import com.commonsware.cwac.camera.CameraHost.FailureReason;
import com.gpit.android.util.Utils;

import junit.framework.Assert;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class CameraView extends FrameLayout implements Camera.PictureCallback {
	static final String TAG = "GS-Camera";
	private PreviewStrategy previewStrategy;
	private Camera.Size previewSize;
	private Camera camera = null;
	private boolean inPreview = false;
	private CameraHost host = null;
	private OnOrientationChange onOrientationChange = null;
	private int displayOrientation = -1;
	private int outputOrientation = -1;
	private int cameraId = -1;
	private MediaRecorder recorder = null;
	private Camera.Parameters previewParams = null;
	private boolean needBitmap = false;
	private boolean needByteArray = false;
	private boolean needFile = false;
	private boolean isDetectingFaces = false;
	private boolean mMeteringAreaSupported = false; 
	
	// Focus
	private final static int CAMERA_FOCUS_AREA_SIZE = 100;
	private final static int DEFAULT_TOUCH_MAJOR = 18;
	private final static int DEFAULT_TOUCH_MINOR = 4;
	private int mFocusAreaSize = CAMERA_FOCUS_AREA_SIZE;
	private boolean mEnableTouchOnFocus = true;

	// Status
	private boolean mIsOnTakingPicture = false;
		
	public CameraView(Context context) {
		this(context, null);
	}

	public CameraView(Context context, AttributeSet attrs) {
		this(context, attrs, 0);
	}

	public CameraView(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);

		onOrientationChange = new OnOrientationChange(context);

		if (context instanceof CameraHostProvider) {
			setHost(((CameraHostProvider) context).getCameraHost());
		}/* else {
			throw new IllegalArgumentException("To use the two- or "
					+ "three-parameter constructors on CameraView, "
					+ "your activity needs to implement the "
					+ "CameraHostProvider interface");
		} */
		
		initUI();
	}

	private void initUI() {
	}
	
	public CameraHost getHost() {
		return (host);
	}

	// must call this after constructor, before onResume()

	public void setHost(CameraHost host) {
		this.host = host;

		if (host.getDeviceProfile().useTextureView()) {
			previewStrategy = new TexturePreviewStrategy(this);
		} else {
			previewStrategy = new SurfacePreviewStrategy(this);
		}
	}

	@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
	public void onResume() {
		addView(previewStrategy.getWidget());

        resumeCamera();
	}

	public void onPause() {
        removeView(previewStrategy.getWidget());

        finalizeCamera();
	}

    private void resumeCamera() {
        if (camera == null) {
            cameraId = getHost().getCameraId();

            if (cameraId >= 0) {
                try {
                    camera = Camera.open(cameraId);
                    if (camera.getParameters() != null && camera.getParameters().getMaxNumMeteringAreas() > 0) {
                        mMeteringAreaSupported = true;
                    }

                    if (getActivity().getRequestedOrientation() != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
                        onOrientationChange.enable();
                    }

                    setCameraDisplayOrientation(cameraId, camera);

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH
                            && getHost() instanceof Camera.FaceDetectionListener) {
                        camera.setFaceDetectionListener((Camera.FaceDetectionListener) getHost());
                    }
                } catch (Exception e) {
                    getHost().onCameraFail(FailureReason.UNKNOWN);
                }
            } else {
                getHost().onCameraFail(FailureReason.NO_CAMERAS_REPORTED);
            }
        }
    }

    private void finalizeCamera() {
        if (camera != null) {
            onOrientationChange.disable();

            previewDestroyed();
        }
    }

	// based on CameraPreview.java from ApiDemos
	@Override
	protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
		final int width = resolveSize(getSuggestedMinimumWidth(),
				widthMeasureSpec);
		final int height = resolveSize(getSuggestedMinimumHeight(),
				heightMeasureSpec);
		
		setMeasuredDimension(width, height);

		if (previewSize == null && camera != null) {
			if (getHost().getRecordingHint() != CameraHost.RecordingHint.STILL_ONLY) {
				Camera.Size deviceHint = DeviceProfile.getInstance()
						.getPreferredPreviewSizeForVideo(
								getDisplayOrientation(), width, height,
								camera.getParameters());

				previewSize = CameraUtils.getBestAspectPreviewSize(getDisplayOrientation(), width, height,
						camera.getParameters());
				/*
				previewSize = getHost().getPreferredPreviewSizeForVideo(
						getDisplayOrientation(), width, height,
						camera.getParameters(), deviceHint); */
				// HaiLong
				// previewSize.height = (int)(previewSize.height * ((float)width / previewSize.width));
				// previewSize.width = width;
			}

			if (previewSize == null
					|| previewSize.width * previewSize.height < 65536) {
				previewSize = getHost().getPreviewSize(getDisplayOrientation(),
						width, height, camera.getParameters());
			}

			if (previewSize != null) {
				// android.util.Log.e("CameraView",
				// String.format("%d x %d", previewSize.width,
				// previewSize.height));
			}
		}
	}

	// based on CameraPreview.java from ApiDemos

	@Override
	protected void onLayout(boolean changed, int l, int t, int r, int b) {
		if (changed && getChildCount() > 0) {
			final View child = getChildAt(0);
			final int width = r - l;
			final int height = b - t;
			int previewWidth = width;
			int previewHeight = height;

			// handle orientation

			if (previewSize != null) {
				if (getDisplayOrientation() == 90
						|| getDisplayOrientation() == 270) {
					previewWidth = previewSize.height;
					previewHeight = previewSize.width;
				} else {
					previewWidth = previewSize.width;
					previewHeight = previewSize.height;
				}
			}

			// Center the child SurfaceView within the parent.
			if (width * previewHeight > height * previewWidth) {
				final int scaledChildWidth = previewWidth * height
						/ previewHeight;
				child.layout((width - scaledChildWidth) / 2, 0,
						(width + scaledChildWidth) / 2, height);
			} else {
				final int scaledChildHeight = previewHeight * width
						/ previewWidth;
				child.layout(0, (height - scaledChildHeight) / 2, width,
						(height + scaledChildHeight) / 2);
			}
		}
	}

	public int getDisplayOrientation() {
		return (displayOrientation);
	}

	public void lockToLandscape(boolean enable) {
		if (enable) {
			getActivity().setRequestedOrientation(
					ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
			onOrientationChange.enable();
		} else {
			getActivity().setRequestedOrientation(
					ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
			onOrientationChange.disable();
		}

		setCameraDisplayOrientation(cameraId, camera);
	}

	@Override
	public void onPictureTaken(byte[] data, Camera camera) {
		camera.setParameters(previewParams);

		if (data != null) {
			new ImageCleanupTask(data, cameraId, getHost(), getContext()
					.getCacheDir(), needBitmap, needByteArray, needFile, host.getOutputDirPath(),
					displayOrientation).start();
		}

		if (!getHost().useSingleShotMode()) {
			startPreview();
		}
		
		mIsOnTakingPicture = false;
	}

	public void restartPreview() {
		if (!inPreview) {
			startPreview();
		}
	}

	@TargetApi(17)
	public void takePicture(boolean needBitmap, boolean needByteArray, boolean needFile) {
		Assert.assertTrue(needBitmap || needByteArray || needFile);
		if (inPreview) {
			this.needBitmap = needBitmap;
			this.needByteArray = needByteArray;
			this.needFile = needFile;

			previewParams = camera.getParameters();

			Camera.Parameters pictureParams = camera.getParameters();
			Camera.Size pictureSize = getHost().getPictureSize(pictureParams);

			/*
			// Keep the ratio with preview
			int orgWidth = pictureSize.width;
			pictureSize.width = (int)(pictureSize.height * ((float)previewSize.width / previewSize.height));
			if (pictureSize.width > orgWidth) {
				pictureSize.width = orgWidth;
				pictureSize.height = (int)(pictureSize.width * ((float)previewSize.height / previewSize.width));
			}
			*/
			pictureParams.setPictureSize(pictureSize.width, pictureSize.height);
			pictureParams.setPictureFormat(ImageFormat.JPEG);
			// pictureParams.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
			camera.setParameters(getHost().adjustPictureParameters(
					pictureParams));

			mIsOnTakingPicture = true;

			AudioManager mgr = (AudioManager) getActivity().getSystemService(Context.AUDIO_SERVICE);
			if (Utils.getApiLevel() >= 17) {
				camera.enableShutterSound(false);
			}
			camera.takePicture(getHost().getShutterCallback(), null, this);
			inPreview = false;
		}
	}

	public boolean isRecording() {
		return (recorder != null);
	}

	public void record() throws Exception {
		record(0, null, null);
	}
	
	public void record(long maxSize, MediaRecorder.OnInfoListener infoListener, MediaRecorder.OnErrorListener errorListener) throws Exception {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.HONEYCOMB) {
			throw new UnsupportedOperationException(
					"Video recording supported only on API Level 11+");
		}

		stopPreview();
		camera.unlock();

		try {
			recorder = new MediaRecorder();
			recorder.setCamera(camera);
			// recorder.setMaxDuration(1000 * 60 * 20);
			getHost().configureRecorderAudio(cameraId, recorder);
			recorder.setVideoSource(MediaRecorder.VideoSource.CAMERA);
			getHost().configureRecorderProfile(cameraId, recorder);
			getHost().configureRecorderOutput(cameraId, recorder);
			recorder.setOrientationHint(outputOrientation);
			previewStrategy.attach(recorder);
			if (maxSize > 0)
				recorder.setMaxFileSize(maxSize);
			if (infoListener != null)
				recorder.setOnInfoListener(infoListener);
			if (errorListener != null)
				recorder.setOnErrorListener(errorListener);
			recorder.prepare();
			recorder.start();
		} catch (IOException e) {
			recorder.release();
			recorder = null;
			throw e;
		}
	}

	public void stopRecording() throws IOException {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.HONEYCOMB) {
			throw new UnsupportedOperationException(
					"Video recording supported only on API Level 11+");
		}

		MediaRecorder tempRecorder = recorder;

		recorder = null;
        tempRecorder.stop();
		tempRecorder.release();
        camera.reconnect();

        // startPreview();
        onPause();
        onResume();
	}

	public String getOutputPath() {
		String path = null;
		if (host != null) {
			path = host.getOutputPath();
		}
		
		return path;
	}
	
	/************************************ FOCUS ***********************************/
	public boolean setEnableTouchOnFocus(boolean enable) {
		if (mMeteringAreaSupported) {
			mEnableTouchOnFocus = enable;
		} else {
			if (mEnableTouchOnFocus) {
				mEnableTouchOnFocus = false;
				return false;
			}
		}
		
		return true;
	}
	
	public void setFocusAreaSize(int size) {
		mFocusAreaSize = size;
	}
	
	public boolean autoFocus() {
		return manualFocus(null);
	}

	public boolean manualFocus(MotionEvent event) {
		if (camera == null)
			return false;
		
		if (mIsOnTakingPicture)
			return false;
					
		// if (inPreview) {
			camera.cancelAutoFocus();
			
			Parameters parameters = camera.getParameters();
			parameters.setFocusMode(Parameters.FOCUS_MODE_AUTO);
			
			if (event != null) {
				float x = event.getX();
				float y = event.getY();
				float touchMajor = event.getTouchMajor();
				float touchMinor = event.getTouchMinor();

				if (touchMajor == 0)
					touchMajor = DEFAULT_TOUCH_MAJOR;
				if (touchMinor == 0)
					touchMinor = DEFAULT_TOUCH_MINOR;
				
				Rect touchRect = new Rect((int) (x - touchMajor / 2),
						(int) (y - touchMinor / 2), (int) (x + touchMajor / 2),
						(int) (y + touchMinor / 2));
				
				//Convert from View's width and height to +/- 1000
				final Rect targetFocusRect = new Rect(
						touchRect.left * 2000 / getMeasuredWidth() - 1000,
						touchRect.top * 2000 / getMeasuredHeight() - 1000,
						touchRect.right * 2000 / getMeasuredWidth() - 1000,
						touchRect.bottom * 2000 / getMeasuredHeight() - 1000);
				
				/*
				final Rect targetFocusRect = new Rect(
						touchRect.left * 2000 / getMeasuredHeight() - 1000,
						touchRect.top * 2000 / getMeasuredWidth() - 1000,
						touchRect.right * 2000 / getMeasuredHeight() - 1000,
						touchRect.bottom * 2000 / getMeasuredWidth() - 1000);
				*/
				
				final List<Camera.Area> focusList = new ArrayList<Camera.Area>();
				  Camera.Area focusArea = new Camera.Area(targetFocusRect, 1000);
				  focusList.add(focusArea);
				  
		        parameters.setFocusAreas(focusList);
		        if (mMeteringAreaSupported) {
		        	parameters.setMeteringAreas(focusList);
		        }
			}

			try {
				camera.setParameters(parameters);
				camera.autoFocus(getHost());
			} catch (Exception e) {
				e.printStackTrace();
			}
		// }
			
		return true;
	}

	/**
	 * Convert touch position x:y to {@link Camera.Area} position -1000:-1000 to 1000:1000.
	 */
	private Rect calculateTapArea(float x, float y, float coefficient) {
	    int areaSize = Float.valueOf(mFocusAreaSize * coefficient).intValue();

	    int left = clamp((int) x - areaSize / 2, 0, getMeasuredWidth() - areaSize);
	    int top = clamp((int) y - areaSize / 2, 0, getMeasuredHeight()- areaSize);

	    RectF rectF = new RectF(left, top, left + areaSize, top + areaSize);

	    return new Rect(Math.round(rectF.left), Math.round(rectF.top), Math.round(rectF.right), Math.round(rectF.bottom));
	}

	private int clamp(int x, int min, int max) {
	    if (x > max) {
	        return max;
	    }
	    if (x < min) {
	        return min;
	    }
	    return x;
	}

	public void cancelAutoFocus() {
		camera.cancelAutoFocus();
	}

	public boolean isAutoFocusAvailable() {
		return (inPreview);
	}

	/******************************* FLASH MODE *************************/
	public String getFlashMode() {
		if (camera == null || camera.getParameters() == null)
			return null;
		
		return (camera.getParameters().getFlashMode());
	}

	public void setFlashMode(String mode) {
		if (mode == null)
			return;
		
		if (camera == null) {
			Log.e(TAG, "Yes, we have no camera, we have no camera today");
		} else {
            if (mode == null || mode.equals(getFlashMode())) {
                return;
            }

            try {
                if (!isRecording()) {
                    camera.lock();
                }
            } catch (Exception e) {};

            Camera.Parameters params = camera.getParameters();
            params.setFlashMode(mode);
            camera.setParameters(params);
		}
	}

	public int getZoomLevel() {
		int level = -1;
		
		if (camera == null) {
			throw new IllegalStateException(
					"Yes, we have no camera, we have no camera today");
		} else {
			Camera.Parameters params = camera.getParameters();

			level = params.getZoom();
		}
		
		return level;
	}

    public int getMaxZoomLevel() {
        int level = -1;

        if (camera == null) {
            throw new IllegalStateException(
                    "Yes, we have no camera, we have no camera today");
        } else {
            Camera.Parameters params = camera.getParameters();

            level = params.getMaxZoom();
        }

        return level;
    }

	public int zoom(int level) {
		Camera.Parameters params = camera.getParameters();
		
		if (level < 0)
			level = 0;
		if (level > params.getMaxZoom())
			level = params.getMaxZoom();
		
		params.setZoom(level);
		camera.setParameters(params);
		
		return level;
	}
	
	public ZoomTransaction zoomTo(int level) {
		if (camera == null) {
			throw new IllegalStateException(
					"Yes, we have no camera, we have no camera today");
		} else {
			Camera.Parameters params = camera.getParameters();

			if (level >= 0 && level <= params.getMaxZoom()) {
				return (new ZoomTransaction(camera, level));
			} else {
				throw new IllegalArgumentException(String.format(
						"Invalid zoom level: %d", level));
			}
		}
	}

	@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
	public void startFaceDetection() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH
				&& camera != null && !isDetectingFaces
				&& camera.getParameters().getMaxNumDetectedFaces() > 0) {
			camera.startFaceDetection();
			isDetectingFaces = true;
		}
	}

	public void stopFaceDetection() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH
				&& camera != null && isDetectingFaces) {
			camera.stopFaceDetection();
			isDetectingFaces = false;
		}
	}

	public boolean doesZoomReallyWork() {
		Camera.CameraInfo info = new Camera.CameraInfo();
		Camera.getCameraInfo(getHost().getCameraId(), info);

		return (getHost().getDeviceProfile()
				.doesZoomActuallyWork(info.facing == CameraInfo.CAMERA_FACING_FRONT));
	}

	void previewCreated() {
		if (camera != null) {
			try {
				previewStrategy.attach(camera);
			} catch (IOException e) {
				getHost().handleException(e);
			}
		}
	}

	void previewDestroyed() {
		if (camera != null) {
			previewStopped();
			camera.release();
			camera = null;
		}
	}

	void previewReset(int width, int height) {
		previewStopped();
		initPreview(width, height);
	}

	private void previewStopped() {
		if (inPreview) {
			stopPreview();
		}
	}

	@TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
	public void initPreview(int w, int h) {
		if (camera != null) {
			Camera.Parameters parameters = camera.getParameters();

			// h = w * (previewSize.height / previewSize.width);
			// w = (int)(h * ((float)previewSize.width / previewSize.height));
			parameters.setPreviewSize(previewSize.width, previewSize.height);
			// parameters.setPreviewSize(w, h);

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
				// parameters.setRecordingHint(getHost().getRecordingHint() != CameraHost.RecordingHint.STILL_ONLY);
			}

			requestLayout();

			camera.setParameters(getHost().adjustPreviewParameters(parameters));
			startPreview();
		}
	}

	public void startPreview() {
        if (camera == null) return;

		camera.startPreview();
		inPreview = true;
		getHost().autoFocusAvailable();
	}

	public void stopPreview() {
		inPreview = false;
		getHost().autoFocusUnavailable();
		camera.stopPreview();
	}

	// based on
	// http://developer.android.com/reference/android/hardware/Camera.html#setDisplayOrientation(int)
	// and http://stackoverflow.com/a/10383164/115145

	private void setCameraDisplayOrientation(int cameraId,
			android.hardware.Camera camera) {
		Camera.CameraInfo info = new Camera.CameraInfo();
		int rotation = getActivity().getWindowManager().getDefaultDisplay()
				.getRotation();
		int degrees = 0;
		DisplayMetrics dm = new DisplayMetrics();

		Camera.getCameraInfo(cameraId, info);
		getActivity().getWindowManager().getDefaultDisplay().getMetrics(dm);

		switch (rotation) {
		case Surface.ROTATION_0:
			degrees = 0;
			break;
		case Surface.ROTATION_90:
			degrees = 90;
			break;
		case Surface.ROTATION_180:
			degrees = 180;
			break;
		case Surface.ROTATION_270:
			degrees = 270;
			break;
		}

		if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
			displayOrientation = (info.orientation + degrees) % 360;
			displayOrientation = (360 - displayOrientation) % 360;
		} else {
			displayOrientation = (info.orientation - degrees + 360) % 360;
		}

		boolean wasInPreview = inPreview;

		if (inPreview) {
			stopPreview();
		}

		camera.setDisplayOrientation(displayOrientation);

		if (wasInPreview) {
			startPreview();
		}

		if (getActivity().getRequestedOrientation() != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
			outputOrientation = getCameraPictureRotation(getActivity()
					.getWindowManager().getDefaultDisplay().getOrientation());
		} else if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
			outputOrientation = (360 - displayOrientation) % 360;
		} else {
			outputOrientation = displayOrientation;
		}

		Camera.Parameters params = camera.getParameters();

		params.setRotation(outputOrientation);
		camera.setParameters(params);
	}

	// based on:
	// http://developer.android.com/reference/android/hardware/Camera.Parameters.html#setRotation(int)

	private int getCameraPictureRotation(int orientation) {
		Camera.CameraInfo info = new Camera.CameraInfo();
		Camera.getCameraInfo(cameraId, info);
		int rotation = 0;

		orientation = (orientation + 45) / 90 * 90;

		if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
			rotation = (info.orientation - orientation + 360) % 360;
		} else { // back-facing camera
			rotation = (info.orientation + orientation) % 360;
		}

		return (rotation);
	}

	Activity getActivity() {
		return ((Activity) getContext());
	}

	/************************ EVENT LISTENER **************************/
	private class OnOrientationChange extends OrientationEventListener {
		public OnOrientationChange(Context context) {
			super(context);
			disable();
		}

		@Override
		public void onOrientationChanged(int orientation) {
			if (camera != null) {
				int newOutputOrientation = getCameraPictureRotation(orientation);

				if (newOutputOrientation != outputOrientation) {
					outputOrientation = newOutputOrientation;

					Camera.Parameters params = camera.getParameters();

					params.setRotation(outputOrientation);
					camera.setParameters(params);
				}
			}
		}
	}
}