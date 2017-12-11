package com.gpit.android.camera.gripandshoot.settings;

import android.app.Activity;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Context;
import android.content.Intent;
import android.hardware.Camera;
import android.os.Bundle;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.Preference.OnPreferenceChangeListener;
import android.preference.Preference.OnPreferenceClickListener;
import android.preference.PreferenceFragment;
import android.preference.PreferenceManager;
import android.preference.PreferenceScreen;

import com.commonsware.cwac.camera.CameraProfile;
import com.commonsware.cwac.camera.SimpleCameraHost;
import com.gpit.android.camera.gripandshoot.Constant;
import com.gpit.android.camera.gripandshoot.GSApp;
import com.gpit.android.camera.gripandshoot.R;

import junit.framework.Assert;

import net.rdrei.android.dirchooser.DirectoryChooserActivity;

import java.io.File;
import java.util.ArrayList;

public class SettingActivity extends Activity {
	// Preferences
	public final static String PREFS_KEY_CAMERA_PICTURE_FLASH_MODE = "picture_flash_mode";
    public final static String PREFS_KEY_CAMERA_VIDEO_FLASH_MODE = "video_flash_mode";

	// Directory Chooser
	private final static int REQUEST_IMAGE_DIRECTORY = 1000;
	private final static int REQUEST_VIDEO_DIRECTORY = 1001;

	// Image quality
	public final static int IMAGE_QUALITY_HIGH_PERCENT = 100;
	public final static int IMAGE_QUALITY_MEDIUM_PERCENT = 75;
	public final static int IMAGE_QUALITY_LOW_PERCENT = 50;

	// Image Ratio
	public final static float IMAGE_RATIO_4_3 = (4.0f / 3);
	public final static float IMAGE_RATIO_16_9 = (16.0f / 9);
	public final static float IMAGE_RATIO_1_1 = 1;

	// Video Profile
	public final static String VIDEO_DEFAULT_PROFILE = "-1";
	private String frontVideoProfileID;
	private String backVideoProfileID;

	private PrefsFragment mPrefFragment;
	private String imageAr;

	public final static String getFlashMode(boolean video) {
		String flashMode;
        if (video) {
            flashMode = GSApp.getInstance().prefs.getString(PREFS_KEY_CAMERA_VIDEO_FLASH_MODE, Camera.Parameters.FLASH_MODE_OFF);
        } else {
            flashMode = GSApp.getInstance().prefs.getString(PREFS_KEY_CAMERA_PICTURE_FLASH_MODE, Camera.Parameters.FLASH_MODE_AUTO);
        }

		return flashMode;
	}

	public final static void setFlashMode(String flashMode, boolean video) {
        if (video) {
            GSApp.getInstance().prefsEditor.putString(PREFS_KEY_CAMERA_VIDEO_FLASH_MODE, flashMode);
        } else {
            GSApp.getInstance().prefsEditor.putString(PREFS_KEY_CAMERA_PICTURE_FLASH_MODE, flashMode);
        }
		GSApp.getInstance().prefsEditor.commit();
	}

	@Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Retrieve preference values
        updateValueFromPreference();

        mPrefFragment = new PrefsFragment();
        FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.replace(android.R.id.content, mPrefFragment);
        fragmentTransaction.commit();
    }

	@Override
	protected void onResume() {
		super.onResume();
	}

	private void updateValueFromPreference() {
        imageAr = getImageAspectRatio(this);

        frontVideoProfileID = getFrontVideoProfileID(this);
        backVideoProfileID = getBackVideoProfileID(this);
	}

	public static String getFrontVideoProfileID(Context context) {
		String quality = GSApp.getInstance().prefs.getString(Constant.PREFS_KEY_BACK_VIDEO_PROFILE, VIDEO_DEFAULT_PROFILE);
		return quality;
	}

	public static String getBackVideoProfileID(Context context) {
		String quality = GSApp.getInstance().prefs.getString(Constant.PREFS_KEY_FRONT_VIDEO_PROFILE, VIDEO_DEFAULT_PROFILE);
		return quality;
	}

	private void setBackVideoQuality(String quality) {
		backVideoProfileID = quality;
		GSApp.getInstance().prefsEditor.putString(Constant.PREFS_KEY_FRONT_VIDEO_PROFILE, backVideoProfileID);
		GSApp.getInstance().prefsEditor.commit();
	}

	private void setFrontVideoQuality(String quality) {
		frontVideoProfileID = quality;
		GSApp.getInstance().prefsEditor.putString(Constant.PREFS_KEY_FRONT_VIDEO_PROFILE, frontVideoProfileID);
		GSApp.getInstance().prefsEditor.commit();
	}


	public static int getImageQualityPercent(Context context) {
		int percent = IMAGE_QUALITY_HIGH_PERCENT;

		return percent;
	}

	public static String getVideoOutputPath() {
		String path = GSApp.getInstance().prefs.getString(Constant.PREFS_KEY_VIDEO_PATH, SimpleCameraHost.getVideoDirectory().getAbsolutePath());
		return path;
	}

	private void setVideoOutputPath(String path) {
		GSApp.getInstance().prefsEditor.putString(Constant.PREFS_KEY_VIDEO_PATH, path);
		GSApp.getInstance().prefsEditor.commit();
	}

	public static String getImageOutputPath() {
		String path = GSApp.getInstance().prefs.getString(Constant.PREFS_KEY_IMAGE_PATH, SimpleCameraHost.getPhotoDirectory().getAbsolutePath());
		return path;
	}

	private void setImageOutputPath(String path) {
		GSApp.getInstance().prefsEditor.putString(Constant.PREFS_KEY_IMAGE_PATH, path);
		GSApp.getInstance().prefsEditor.commit();
	}

	public static String getImageAspectRatio(Context context) {
		String ar = GSApp.getInstance().prefs.getString(Constant.PREFS_KEY_IMAGE_AR, context.getString(R.string.ar_4_3));
		return ar;
	}

	public static float getImageAspectRatioAsConst(Context context) {
		String ar = getImageAspectRatio(context);
		float ratio;
		if (ar.equals(context.getString(R.string.ar_1_1))) {
			ratio = IMAGE_RATIO_1_1;
		} else if (ar.equals(context.getString(R.string.ar_4_3))) {
			ratio = IMAGE_RATIO_4_3;
		} else {
			Assert.assertTrue(ar.equals(context.getString(R.string.ar_16_9)));
			ratio = IMAGE_RATIO_16_9;
		}

		return ratio;
	}

	private void setImageAspectRatio(String ar) {
		imageAr = ar;
		GSApp.getInstance().prefsEditor.putString(Constant.PREFS_KEY_IMAGE_AR, imageAr);
		GSApp.getInstance().prefsEditor.commit();
	}

	/**
     * This fragment shows the preferences for the first header.
     */
    public static class PrefsFragment extends PreferenceFragment {
    	private SettingActivity activity;

    	private ArrayList<CameraProfile> mBackCameraProfileList;
    	private ArrayList<CameraProfile> mFrontCameraProfileList;

        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);

            activity = (SettingActivity) getActivity();

            // load Camera profile
            mBackCameraProfileList = new ArrayList<CameraProfile>();
    		mBackCameraProfileList = SimpleCameraHost.getAvailableProfile(Camera.CameraInfo.CAMERA_FACING_BACK);

    		mFrontCameraProfileList = new ArrayList<CameraProfile>();
    		mFrontCameraProfileList = SimpleCameraHost.getAvailableProfile(Camera.CameraInfo.CAMERA_FACING_FRONT);

            // Make sure 	 values are applied.  In a real app, you would
            // want this in a shared function that is used to retrieve the
            // SharedPreferences wherever they are needed.
            PreferenceManager.setDefaultValues(getActivity(),
                    R.xml.preferences, false);

            // Load the preferences from an XML resource
            addPreferencesFromResource(R.xml.preferences);

			PreferenceScreen preferenceScreen = getPreferenceScreen();

            Preference p = findPreference("photo_save_path");
			p.setOnPreferenceClickListener(mPhotoSavePathClickListener);

    		p = findPreference("photo_ar");
    		p.setOnPreferenceChangeListener(mPreferenceChangeListener);

    		p = findPreference("video_save_path");
    		p.setOnPreferenceClickListener(mVideoSavePathClickListener);

			/*
    		ListPreference lp = (ListPreference) findPreference("video_back_profile");
    		addCameraProfilePreferences(Camera.CameraInfo.CAMERA_FACING_BACK, lp);

    		lp = (ListPreference) findPreference("video_front_profile");
    		addCameraProfilePreferences(Camera.CameraInfo.CAMERA_FACING_FRONT, lp);
			*/

    		updatePreferences();
        }

        private void addCameraProfilePreferences(int cameraFace, ListPreference lp) {
        	ArrayList<CameraProfile> profileList;
        	if (cameraFace == Camera.CameraInfo.CAMERA_FACING_FRONT) {
        		profileList = mFrontCameraProfileList;
        	} else {
        		profileList = mBackCameraProfileList;
        	}

    		CharSequence[] names = new CharSequence[mBackCameraProfileList.size() + 1];
    		CharSequence[] values = new CharSequence[mBackCameraProfileList.size() + 1];

    		names[0] = getString(R.string.default_setting);
    		values[0] = VIDEO_DEFAULT_PROFILE;

    		for (int i = 0 ; i < profileList.size() ; i++) {
    			CameraProfile profile = profileList.get(i);
    			names[i + 1] = profile.description;
    			values[i + 1] = String.valueOf(profile.profileID);
    		}

    		lp.setEntries(names);
    		lp.setEntryValues(values);
    		lp.setOnPreferenceChangeListener(mPreferenceChangeListener);
        }

        @Override
		public void onActivityResult(int requestCode, int resultCode, Intent data) {
    	    super.onActivityResult(requestCode, resultCode, data);

    	    switch (requestCode) {
    	    case REQUEST_IMAGE_DIRECTORY:
    	        if (resultCode == DirectoryChooserActivity.RESULT_CODE_DIR_SELECTED) {
    	        	String path = data.getStringExtra(DirectoryChooserActivity.RESULT_SELECTED_DIR);
    	        	activity.setImageOutputPath(path);
    	        } else {
    	            // Nothing selected
    	        }
    	        break;
    	    case REQUEST_VIDEO_DIRECTORY:
    	    	if (resultCode == DirectoryChooserActivity.RESULT_CODE_DIR_SELECTED) {
    	    		String path = data.getStringExtra(DirectoryChooserActivity.RESULT_SELECTED_DIR);
    	    		activity.setVideoOutputPath(path);
    	        } else {
    	            // Nothing selected
    	        }
    	        break;
    		}

    	    updatePreferences();
    	}

        private String getDescriptionFromProfileID(int cameraFace, String id) {
        	ArrayList<CameraProfile> profileList;
        	String description = "";

        	if (id.equals(VIDEO_DEFAULT_PROFILE))
        		return getString(R.string.default_setting);

        	if (cameraFace == Camera.CameraInfo.CAMERA_FACING_FRONT) {
        		profileList = mFrontCameraProfileList;
        	} else {
        		profileList = mBackCameraProfileList;
        	}

        	for (int i = 0 ; i < profileList.size() ; i++) {
    			CameraProfile profile = profileList.get(i);
    			if (profile.profileID == Integer.valueOf(id)) {
    				description = profile.description;
    				break;
    			}
    		}

        	return description;
        }

        private void updatePreferences() {
        	Preference p = findPreference("photo_save_path");
            p.setSummary(activity.getImageOutputPath());

            p = findPreference("photo_ar");
            ((ListPreference)p).setValue(activity.imageAr);
    		p.setSummary(activity.imageAr);

    		p = findPreference("video_save_path");
    		p.setSummary(activity.getVideoOutputPath());

			/*
    		p = findPreference("video_front_profile");
    		((ListPreference)p).setValue(activity.frontVideoProfileID);
    		p.setSummary(getDescriptionFromProfileID(Camera.CameraInfo.CAMERA_FACING_FRONT, activity.frontVideoProfileID));

    		p = findPreference("video_back_profile");
    		((ListPreference)p).setValue(activity.backVideoProfileID);
    		p.setSummary(getDescriptionFromProfileID(Camera.CameraInfo.CAMERA_FACING_BACK, activity.backVideoProfileID));
    		*/
        }

        private OnPreferenceClickListener mPhotoSavePathClickListener = new OnPreferenceClickListener() {
			@Override
			public boolean onPreferenceClick(Preference preference) {
				final Intent chooserIntent = new Intent(getActivity(), DirectoryChooserActivity.class);

				// Optional: Allow users to create a new directory with a fixed name.
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_NEW_DIR_NAME,
				                       "DirChooserSample");
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_INITIAL_DIRECTORY,
						new File(activity.getImageOutputPath()).getParent());
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_SELECTED_DIR_NAME,
						activity.getImageOutputPath());
				// REQUEST_DIRECTORY is a constant integer to identify the request, e.g. 0
				startActivityForResult(chooserIntent, REQUEST_IMAGE_DIRECTORY);

				return false;
			}
        };

        private OnPreferenceClickListener mVideoSavePathClickListener = new OnPreferenceClickListener() {
			@Override
			public boolean onPreferenceClick(Preference preference) {
				final Intent chooserIntent = new Intent(getActivity(), DirectoryChooserActivity.class);

				// Optional: Allow users to create a new directory with a fixed name.
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_NEW_DIR_NAME,
				                       "DirChooserSample");
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_INITIAL_DIRECTORY,
						new File(activity.getVideoOutputPath()).getParent());
				chooserIntent.putExtra(DirectoryChooserActivity.EXTRA_SELECTED_DIR_NAME,
						activity.getVideoOutputPath());
				// REQUEST_DIRECTORY is a constant integer to identify the request, e.g. 0
				startActivityForResult(chooserIntent, REQUEST_VIDEO_DIRECTORY);

				return false;
			}
        };

        private OnPreferenceChangeListener mPreferenceChangeListener = new OnPreferenceChangeListener() {
			@Override
			public boolean onPreferenceChange(Preference preference, Object newValue) {
				String key = preference.getKey();
				if (key.equals("photo_ar")) {
					activity.setImageAspectRatio((String)newValue);
				} else if (key.equals("video_back_profile")) {
					activity.setBackVideoQuality((String)newValue);
				} else if (key.equals("video_front_profile")) {
					activity.setFrontVideoQuality((String)newValue);
				}

				updatePreferences();

				return true;
			}
		};
    }

}
