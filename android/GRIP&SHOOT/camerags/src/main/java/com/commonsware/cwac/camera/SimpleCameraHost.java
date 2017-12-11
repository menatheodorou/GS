/***
  Copyright (c) 2013 CommonsWare, LLC
  
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

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.hardware.Camera;
import android.media.CamcorderProfile;
import android.media.MediaActionSound;
import android.media.MediaRecorder;
import android.media.MediaScannerConnection;
import android.os.Build;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.util.Log;

public class SimpleCameraHost implements CameraHost {
	private static final String[] SCAN_TYPES = { "image/jpeg" };
	private Context ctxt = null;

	private final static String PREFS_KEY_OUTPUT_PATH = "camerahost_output_path";
	
	private String mOutputPath;
	private String mOutputDirPath;
	
	private boolean mEnableTouchOnFocus = true;

	public SimpleCameraHost(Context _ctxt) {
		this.ctxt = _ctxt.getApplicationContext();
		
		// Load output path
		SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(ctxt);
		mOutputDirPath = prefs.getString(PREFS_KEY_OUTPUT_PATH, getPhotoDirectory().getAbsolutePath());
	}

	@Override
	public Camera.Parameters adjustPictureParameters(
			Camera.Parameters parameters) {
		return (parameters);
	}

	@Override
	public Camera.Parameters adjustPreviewParameters(
			Camera.Parameters parameters) {
		return (parameters);
	}

	@Override
	public void configureRecorderAudio(int cameraId, MediaRecorder recorder) {
		recorder.setAudioSource(MediaRecorder.AudioSource.CAMCORDER);
	}

	@Override
	public void configureRecorderOutput(int cameraId, MediaRecorder recorder) {
		mOutputPath = getVideoPath().getAbsolutePath();
		recorder.setOutputFile(mOutputPath);
	}
	
	@Override
	public void setOutputDirPath(String path) {
		mOutputDirPath = path;
		
		SharedPreferences.Editor prefsEditor = PreferenceManager.getDefaultSharedPreferences(ctxt).edit();
		prefsEditor.putString(PREFS_KEY_OUTPUT_PATH, mOutputDirPath);
		prefsEditor.commit();
	}

	@Override
	public String getOutputPath() {
		return mOutputPath;
	}

	@Override
	public String getOutputDirPath() {
		return mOutputDirPath;
	}
	
	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	@Override
	public void configureRecorderProfile(int cameraId, MediaRecorder recorder) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.HONEYCOMB
				|| CamcorderProfile.hasProfile(cameraId,
						CamcorderProfile.QUALITY_HIGH)) {
			recorder.setProfile(CamcorderProfile.get(cameraId,
					CamcorderProfile.QUALITY_HIGH));
		} else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB
				&& CamcorderProfile.hasProfile(cameraId,
						CamcorderProfile.QUALITY_LOW)) {
			recorder.setProfile(CamcorderProfile.get(cameraId,
					CamcorderProfile.QUALITY_LOW));
		} else {
			throw new IllegalStateException(
					"cannot find valid CamcorderProfile");
		}
		
		/* recorder.setProfile(CamcorderProfile.get(cameraId,
				CamcorderProfile.QUALITY_480P)); */
	}

	public static ArrayList<CameraProfile> getAvailableProfile(int cameraId) {
		ArrayList<CameraProfile> profileList = new ArrayList<CameraProfile>();
		
		MediaRecorder recorder = new MediaRecorder();
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_1080P, "1920 x 1080 (16:9)");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_480P, "720 x 480 (16:9)");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_720P, "1280 x 720 (16:9)");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_CIF, "352 x 288 (4:3)");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_HIGH, "Highest");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_LOW, "Lowest");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_QCIF, "176 x 144 (4:3)");
		addAvailableProfile(profileList, cameraId, recorder, CamcorderProfile.QUALITY_QVGA, "320x240 (4:3)");
		recorder.release();
		
		return profileList;
	}
	
	private static void addAvailableProfile(ArrayList<CameraProfile> profileList, int cameraId, MediaRecorder recorder, int profile, String description) {
		if (CamcorderProfile.hasProfile(cameraId, profile)) 
			profileList.add(new CameraProfile(profile, description));
	}
	
	@Override
	public int getCameraId() {
		int count = Camera.getNumberOfCameras();
		int result = -1;

		if (count > 0) {
			result = 0; // if we have a camera, default to this one

			Camera.CameraInfo info = new Camera.CameraInfo();

			for (int i = 0; i < count; i++) {
				Camera.getCameraInfo(i, info);

				if (info.facing == Camera.CameraInfo.CAMERA_FACING_BACK
						&& !useFrontFacingCamera()) {
					result = i;
					break;
				} else if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT
						&& useFrontFacingCamera()) {
					result = i;
					break;
				}
			}
		}

		return (result);
	}

	@Override
	public DeviceProfile getDeviceProfile() {
		return (DeviceProfile.getInstance());
	}

	@Override
	public Camera.Size getPictureSize(Camera.Parameters parameters) {
		return (CameraUtils.getLargestPictureSize(parameters));
	}

	@Override
	public Camera.Size getPreviewSize(int displayOrientation, int width,
			int height, Camera.Parameters parameters) {
		return (CameraUtils.getBestAspectPreviewSize(displayOrientation, width,
				height, parameters));
	}

	@TargetApi(Build.VERSION_CODES.HONEYCOMB)
	@Override
	public Camera.Size getPreferredPreviewSizeForVideo(int displayOrientation,
			int width, int height, Camera.Parameters parameters,
			Camera.Size deviceHint) {
		if (deviceHint != null) {
			return (deviceHint);
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			return (parameters.getPreferredPreviewSizeForVideo());
		}

		return (null);
	}

	@Override
	public Camera.ShutterCallback getShutterCallback() {
		return (null);
	}

	@Override
	public void handleException(Exception e) {
		Log.e(getClass().getSimpleName(), "Exception in setPreviewDisplay()", e);
	}

	@Override
	public boolean mirrorFFC() {
		return (false);
	}

	@Override
	public void saveImage(Bitmap bitmap, int quality) {
		File photo = getPhotoPath();
		// Update output path
		mOutputPath = photo.getAbsolutePath();
		
		if (photo.exists()) {
			photo.delete();
		}

		try {
			FileOutputStream fos = new FileOutputStream(photo.getPath());
			bitmap.compress(Bitmap.CompressFormat.JPEG, quality, fos);
			fos.close();
			
			if (scanSavedImage()) {
				MediaScannerConnection.scanFile(ctxt,
						new String[] { photo.getPath() }, SCAN_TYPES, null);
			}
		} catch (java.io.IOException e) {
			handleException(e);
		}
	}


	public void saveImage(String path) {
		File photo = getPhotoPath();
		// Update output path
		mOutputPath = photo.getAbsolutePath();
		
		File orgPhoto = new File(path);
		
		copyFile(orgPhoto.getAbsolutePath(), photo.getAbsolutePath());
		
		if (scanSavedImage()) {
			MediaScannerConnection.scanFile(ctxt,
					new String[] { photo.getPath() }, SCAN_TYPES, null);
		}
	}
	
	private void copyFile(String inputPath, String outputPath) {
		File file = new File(inputPath);
		if (!file.renameTo(new File(outputPath))) {
			InputStream in = null;
			OutputStream out = null;
			try {
	
				in = new FileInputStream(inputPath);
				out = new FileOutputStream(outputPath);
	
				byte[] buffer = new byte[1024];
				int read;
				while ((read = in.read(buffer)) != -1) {
					out.write(buffer, 0, read);
				}
				in.close();
				in = null;
	
				// write the output file (You have now copied the file)
				out.flush();
				out.close();
				out = null;
	
			} catch (FileNotFoundException fnfe1) {
				Log.e("tag", fnfe1.getMessage());
			} catch (Exception e) {
				Log.e("tag", e.getMessage());
			}
		}
	}
	
	@Override
	public void saveImage() {
		
	}
	
	@Override
	public void saveImage(byte[] image) {
		File photo = getPhotoPath();
		// Update output path
		mOutputPath = photo.getAbsolutePath();
		
		if (photo.exists()) {
			photo.delete();
		}

		try {
			FileOutputStream fos = new FileOutputStream(photo.getPath());
			BufferedOutputStream bos = new BufferedOutputStream(fos);

			bos.write(image);
			bos.flush();
			fos.getFD().sync();
			bos.close();

			if (scanSavedImage()) {
				MediaScannerConnection.scanFile(ctxt,
						new String[] { photo.getPath() }, SCAN_TYPES, null);
			}
		} catch (java.io.IOException e) {
			handleException(e);
		}
	}

	@TargetApi(Build.VERSION_CODES.JELLY_BEAN)
	@Override
	public void onAutoFocus(boolean success, Camera camera) {
		if (success && Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
			new MediaActionSound().play(MediaActionSound.FOCUS_COMPLETE);
		}
	}

	@Override
	public boolean useSingleShotMode() {
		return (false);
	}

	@Override
	public void autoFocusAvailable() {
		// no-op
	}

	@Override
	public void autoFocusUnavailable() {
		// no-op
	}

	@Override
	public void setEnableTouchOnFocus(boolean enabled) {
		mEnableTouchOnFocus = enabled;
	}
	
	@Override
	public boolean isEnableTouchOnFocus() {
		return mEnableTouchOnFocus;
	}
	  
	@Override
	public boolean rotateBasedOnExif() {
		return (true);
	}

	@Override
	public RecordingHint getRecordingHint() {
		return (RecordingHint.ANY);
	}

	@Override
	public void onCameraFail(FailureReason reason) {
		Log.e("CWAC-Camera",
				String.format("Camera access failed: %d", reason.value));
	}

	protected File getPhotoPath() {
		File dir = new File(getOutputDirPath());

		dir.mkdirs();

		File file = new File(dir, getPhotoFilename());
		file.getAbsolutePath();
		
		return file;
	}

	public static File getPhotoDirectory() {
		return (Environment
				.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES));
	}

	protected String getPhotoFilename() {
		String ts = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)
				.format(new Date());

		return ("Photo_" + ts + ".jpg");
	}

	protected File getVideoPath() {
		File dir = new File(getOutputDirPath());

		dir.mkdirs();

		return (new File(dir, getVideoFilename()));
	}

	public static File getVideoDirectory() {
		return (Environment
				.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES));
	}

	protected String getVideoFilename() {
		String ts = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)
				.format(new Date());

		return ("Video_" + ts + ".mp4");
	}

	protected boolean useFrontFacingCamera() {
		return (false);
	}

	protected boolean scanSavedImage() {
		return (true);
	}
}
