package com.commonsware.cwac.camera;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.hardware.Camera;
import android.media.ExifInterface;
import android.os.Environment;
import android.util.Log;

import com.gpit.android.util.Utils;

import junit.framework.Assert;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class ImageCleanupTask extends Thread {
  public final static String TAG = ImageCleanupTask.class.getSimpleName();

  private byte[] data;
  private Bitmap workingCopy=null;
  private String photoFilePath;
  
  private int cameraId;
  private CameraHost host;
  private File cacheDir=null;
  private boolean needBitmap=false;
  private boolean needByteArray=false;
  private boolean needFile = false;
  private String photoDirPath;
  private int displayOrientation;

  ImageCleanupTask(byte[] data, int cameraId, CameraHost host,
                   File cacheDir, boolean needBitmap,
                   boolean needByteArray, boolean needFile, String photoDirPath, int displayOrientation) {
    this.data=data;
    this.cameraId=cameraId;
    this.host=host;
    this.cacheDir=cacheDir;
    this.needBitmap=needBitmap;
    this.needByteArray=needByteArray;
    this.needFile=needFile;
    this.photoDirPath = photoDirPath;
    this.displayOrientation=displayOrientation;
  }

  @Override
  public void run() {
    Log.i(TAG, "Step0.1: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));

    Camera.CameraInfo info=new Camera.CameraInfo();

    Camera.getCameraInfo(cameraId, info);

    if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
      if (host.getDeviceProfile().portraitFFCFlipped()
          && (displayOrientation == 90 || displayOrientation == 270)) {
        applyFlip();
      }
      else if (host.mirrorFFC()) {
        applyMirror();
      }
    }

    if (host.rotateBasedOnExif()
        && host.getDeviceProfile().encodesRotationToExif()) {
    	rotateForRealz();
    }

    synchronizeModels(needBitmap, needByteArray, needFile);
    clearResources();
    
	if (needBitmap) {
		host.saveImage(workingCopy, 100);
	} else if (needByteArray) {
		host.saveImage(data);
		
	} else {
		Assert.assertTrue(needFile);
		host.saveImage(photoFilePath);
	}

    Log.i(TAG, "Step0.2: " + Utils.getDateString(Utils.getTimeMilis(), "mm:ss.SSS"));
  }
  
  private void clearResources() {
	  if (!needByteArray)
		  data = null;
	  
	  if (!needBitmap) {
		  if (workingCopy != null) {
			  workingCopy.recycle();
		  }  
	  }
	  
	  if (!needFile) {
		  try {
			  File file = new File(getPhotoOutPath());
			  if (file.exists())
				  file.delete();
		  } catch (Exception e) {
			  e.printStackTrace();
		  }
	  }
	  
  }

  private String getPhotoOutPath() {
	  File dcim=new File(photoDirPath, Environment.DIRECTORY_DCIM);

      dcim.mkdirs();
      File photo=new File(dcim, "__photo__.jpg");

      return photo.getAbsolutePath();
  }
  
  void applyMirror() {
    synchronizeModels(true, false, false);

    // from http://stackoverflow.com/a/8347956/115145

    float[] mirrorY= { -1, 0, 0, 0, 1, 0, 0, 0, 1 };
    Matrix matrix=new Matrix();
    Matrix matrixMirrorY=new Matrix();

    matrixMirrorY.setValues(mirrorY);
    matrix.postConcat(matrixMirrorY);

    Bitmap mirrored=
        Bitmap.createBitmap(workingCopy, 0, 0, workingCopy.getWidth(),
                            workingCopy.getHeight(), matrix, true);

    workingCopy.recycle();
    workingCopy = mirrored;
    data = null;
    photoFilePath = null;
  }

  void applyFlip() {
    synchronizeModels(true, false, false);

    float[] mirrorY= { -1, 0, 0, 0, 1, 0, 0, 0, 1 };
    Matrix matrix=new Matrix();
    Matrix matrixMirrorY=new Matrix();

    matrixMirrorY.setValues(mirrorY);
    matrix.preScale(1.0f, -1.0f);
    matrix.postConcat(matrixMirrorY);

    Bitmap flipped=
        Bitmap.createBitmap(workingCopy, 0, 0, workingCopy.getWidth(),
                            workingCopy.getHeight(), matrix, true);

    workingCopy.recycle();
    workingCopy = flipped;
    data = null;
    photoFilePath = null;
  }

  void rotateForRealz() {
    try {
      String photoPath = getPhotoOutPath();

      synchronizeModels(false, false, true);
      try {
    	  ExifInterface exif=new ExifInterface(photoPath);
    	  String orientation = exif.getAttribute(ExifInterface.TAG_ORIENTATION);
    	  Bitmap rotated=null;
        
        try {
			if ("6".equals(orientation)) {
				synchronizeModels(true, false, false);
				rotated = rotate(workingCopy, 90);
			} else if ("8".equals(orientation)) {
				synchronizeModels(true, false, false);
				rotated = rotate(workingCopy, 270);
			} else if ("3".equals(orientation)) {
				synchronizeModels(true, false, false);
				rotated = rotate(workingCopy, 180);
			}

			if (rotated != null) {
				photoFilePath = null;

				workingCopy.recycle();
				workingCopy = rotated;
			} else {
				photoFilePath = photoPath;
			}
        }
        catch (OutOfMemoryError e) {
          Log.e(CameraView.TAG, "OOM in rotate() call", e);
        }
      }
      catch (java.io.IOException e) {
        Log.e(CameraView.TAG,
              "Exception in saving photo in rotateForRealz()", e);
      }
    }
    catch (OutOfMemoryError e) {
      Log.e(CameraView.TAG, "OOM in synchronizeModels() call", e);
    }
  }

  private static Bitmap rotate(Bitmap bitmap, int degree) {
    Matrix mtx=new Matrix();

    mtx.setRotate(degree);

    return(Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(),
                               bitmap.getHeight(), mtx, true));
  }

  private void synchronizeModels(boolean needBitmap,
                                 boolean needByteArray, 
                                 boolean needFile) {
    if (data == null && needByteArray) {
      ByteArrayOutputStream out=
          new ByteArrayOutputStream(workingCopy.getWidth()
              * workingCopy.getHeight());

      workingCopy.compress(Bitmap.CompressFormat.JPEG, 100, out);
      data=out.toByteArray();

      try {
        out.close();
      }
      catch (IOException e) {
        Log.e(CameraView.TAG, "Exception in closing a BAOS???", e);
      }
    }

    if (workingCopy == null && needBitmap) {
      workingCopy=BitmapFactory.decodeByteArray(data, 0, data.length);
    }

    if (photoFilePath == null && needFile) {
    	try {
    		String path = getPhotoOutPath();
	    	FileOutputStream fos = new FileOutputStream(path);
	        if (data != null) {
	        	fos.write(data);
	        } else if(workingCopy != null) {
	    		workingCopy.compress(Bitmap.CompressFormat.JPEG, 100, fos);
	    	} else {
	    		// Impossible case
	    		Assert.assertTrue(false);
	    	}
	        
	        fos.close();
	        photoFilePath = path;
    	} catch (Exception e) {
    		e.printStackTrace();
    	}
    }
    
    /*
    if (!needBitmap && workingCopy != null) {
      workingCopy.recycle();
      workingCopy=null;
    } */
  }
}