package com.gpit.android.camera.gripandshoot.camera;

import java.io.File;
import java.io.FileOutputStream;

import junit.framework.Assert;

import android.app.Activity;
import android.content.Context;
import android.hardware.Camera;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.PictureCallback;
import android.media.ExifInterface;
import android.view.Display;
import android.view.Surface;

public class Shutter implements AutoFocusCallback, PictureCallback {
    private Context context;
    private String savePath;
    private BeforeShutterListener beforeShutterListener;
    private AfterShutterListener afterShutterListener;
    private GSCameraFragment cameraFragment;
    private PictureCallback callback;
    
    public Shutter(GSCameraFragment cameraFragment, Context context) {
        this.cameraFragment = cameraFragment;
        this.context = context;
    }

    public Context getContext() {
        return this.context;
    }

    public void exec(String savePath) {
        this.savePath = savePath;

        if (cameraFragment != null) {
            cameraFragment.autoFocus();
        }
    }

    public void setPictureCallback(PictureCallback callback) {
    	this.callback = callback;
    }
    
    public void setBeforeShutterListener(BeforeShutterListener listener) {
        this.beforeShutterListener = listener;
    }

    public void setAfterShutterListener(AfterShutterListener listener) {
        this.afterShutterListener = listener;
    }

    @Override
    public void onAutoFocus(boolean success, Camera camera) {
        if (beforeShutterListener != null) {
            beforeShutterListener.beforeShutter();
        }
        
        camera.takePicture(null, null, this);
    }

    @Override
    public void onPictureTaken(byte[] data, Camera camera) {
        if (camera == null) {
            return;
        }

        camera.stopPreview();
        if (callback != null) {
        	callback.onPictureTaken(data,  camera);
        }
        camera.startPreview();
    }

    public boolean savePicture(byte[] data) {
        File pictureFile = new File(savePath);
        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            fos.write(data);
            fos.close();
            
            // Save orientation information
            ExifInterface exif = new ExifInterface(pictureFile.getAbsolutePath());
            Display display = ((Activity) getContext()).getWindowManager()
                    .getDefaultDisplay();
            int rotation = display.getRotation();
            int orientation;
            if (rotation == Surface.ROTATION_0) {
            	orientation = ExifInterface.ORIENTATION_NORMAL;
            } else if (rotation == Surface.ROTATION_90) {
            	orientation = ExifInterface.ORIENTATION_ROTATE_90;
            } else if (rotation == Surface.ROTATION_180) {
            	orientation = ExifInterface.ORIENTATION_ROTATE_180;
            } else {
            	Assert.assertTrue(rotation == Surface.ROTATION_270);
            	orientation = ExifInterface.ORIENTATION_ROTATE_270;
            }
            
            exif.setAttribute(ExifInterface.TAG_ORIENTATION, String.valueOf(3));
            exif.saveAttributes();
            
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
