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

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import android.app.Activity;
import android.graphics.Point;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.view.Display;
import android.view.OrientationEventListener;
import android.view.Surface;

public class CameraUtils {
  // based on ApiDemos
  private static final double ASPECT_TOLERANCE=0.1;

	// Orientation hysteresis amount used in rounding, in degrees
	public static final int ORIENTATION_HYSTERESIS = 5;
  
  public static Camera.Size getOptimalPreviewSize(int displayOrientation,
                                                  int width,
                                                  int height,
                                                  Camera.Parameters parameters) {
    double targetRatio=(double)width / height;
    List<Camera.Size> sizes=parameters.getSupportedPreviewSizes();
    Camera.Size optimalSize=null;
    double minDiff=Double.MAX_VALUE;
    int targetHeight=height;

    if (displayOrientation == 90 || displayOrientation == 270) {
      targetRatio=(double)height / width;
    }

    // Try to find an size match aspect ratio and size

    for (Size size : sizes) {
      double ratio=(double)size.width / size.height;

      if (Math.abs(ratio - targetRatio) <= ASPECT_TOLERANCE) {
        if (Math.abs(size.height - targetHeight) < minDiff) {
          optimalSize=size;
          minDiff=Math.abs(size.height - targetHeight);
        }
      }
    }

    // Cannot find the one match the aspect ratio, ignore
    // the requirement

    if (optimalSize == null) {
      minDiff=Double.MAX_VALUE;

      for (Size size : sizes) {
        if (Math.abs(size.height - targetHeight) < minDiff) {
          optimalSize=size;
          minDiff=Math.abs(size.height - targetHeight);
        }
      }
    }

    return(optimalSize);
  }

  public static Camera.Size getBestAspectPreviewSize(int displayOrientation,
                                                     int width,
                                                     int height,
                                                     Camera.Parameters parameters) {
     return(getBestAspectPreviewSize(displayOrientation, width, height,
                                    parameters, 0.0d));
  }

  public static Camera.Size getBestAspectPreviewSize(int displayOrientation,
                                                     int width,
                                                     int height,
                                                     Camera.Parameters parameters,
                                                     double closeEnough) {
    double targetRatio=(double)width / height;
    Camera.Size optimalSize=null;
    double minDiff=Double.MAX_VALUE;

    if (displayOrientation == 90 || displayOrientation == 270) {
      targetRatio=(double)height / width;
    }

    List<Size> sizes=parameters.getSupportedPreviewSizes();

    Collections.sort(sizes,
                     Collections.reverseOrder(new SizeComparator()));

    for (Size size : sizes) {
      double ratio=(double)size.width / size.height;

      if (Math.abs(ratio - targetRatio) < minDiff) {
        optimalSize=size;
        minDiff=Math.abs(ratio - targetRatio);
      }

      if (minDiff < closeEnough) {
        break;
      }
    }

    return(optimalSize);
  }

  public static Camera.Size getLargestPictureSize(Camera.Parameters parameters) {
    Camera.Size result=null;

    for (Camera.Size size : parameters.getSupportedPictureSizes()) {
      
android.util.Log.d("CWAC-Camera", String.format("%d x %d", size.width, size.height));
      
      if (size.height <= DeviceProfile.getInstance()
                                      .getMaxPictureHeight()
          && size.height >= DeviceProfile.getInstance()
                                         .getMinPictureHeight()) {
        if (result == null) {
          result=size;
        }
        else {
          int resultArea=result.width * result.height;
          int newArea=size.width * size.height;

          if (newArea > resultArea) {
            result=size;
          }
        }
      }
    }

    return(result);
  }

  public static Camera.Size getSmallestPictureSize(Camera.Parameters parameters) {
    Camera.Size result=null;

    for (Camera.Size size : parameters.getSupportedPictureSizes()) {
      if (result == null) {
        result=size;
      }
      else {
        int resultArea=result.width * result.height;
        int newArea=size.width * size.height;

        if (newArea < resultArea) {
          result=size;
        }
      }
    }

    return(result);
  }

  private static class SizeComparator implements
      Comparator<Camera.Size> {
    @Override
    public int compare(Size lhs, Size rhs) {
      int left=lhs.width * lhs.height;
      int right=rhs.width * rhs.height;

      if (left < right) {
        return(-1);
      }
      else if (left > right) {
        return(1);
      }

      return(0);
    }
  }
  
  public static int getDisplayRotation(Activity activity) {
      int rotation = activity.getWindowManager().getDefaultDisplay()
              .getRotation();
      switch (rotation) {
          case Surface.ROTATION_0: return 0;
          case Surface.ROTATION_90: return 90;
          case Surface.ROTATION_180: return 180;
          case Surface.ROTATION_270: return 270;
      }
      return 0;
  }

  /**
   * Calculate the default orientation of the device based on the width and
   * height of the display when rotation = 0 (i.e. natural width and height)
   * @param activity the activity context
   * @return whether the default orientation of the device is portrait
   */
  public static boolean isDefaultToPortrait(Activity activity) {
      Display currentDisplay = activity.getWindowManager().getDefaultDisplay();
      Point displaySize = new Point();
      currentDisplay.getSize(displaySize);
      int orientation = currentDisplay.getRotation();
      int naturalWidth, naturalHeight;
      if (orientation == Surface.ROTATION_0 || orientation == Surface.ROTATION_180) {
          naturalWidth = displaySize.x;
          naturalHeight = displaySize.y;
      } else {
          naturalWidth = displaySize.y;
          naturalHeight = displaySize.x;
      }
      return naturalWidth < naturalHeight;
  }

  public static int getDisplayOrientation(int degrees, int cameraId) {
      // See android.hardware.Camera.setDisplayOrientation for
      // documentation.
      Camera.CameraInfo info = new Camera.CameraInfo();
      Camera.getCameraInfo(cameraId, info);
      int result;
      if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          result = (info.orientation + degrees) % 360;
          result = (360 - result) % 360;  // compensate the mirror
      } else {  // back-facing
          result = (info.orientation - degrees + 360) % 360;
      }
      return result;
  }
  
  public static int roundOrientation(int orientation, int orientationHistory) {
      boolean changeOrientation = false;
      if (orientationHistory == OrientationEventListener.ORIENTATION_UNKNOWN) {
          changeOrientation = true;
      } else {
          int dist = Math.abs(orientation - orientationHistory);
          dist = Math.min( dist, 360 - dist );
          changeOrientation = ( dist >= 45 + ORIENTATION_HYSTERESIS );
      }
      if (changeOrientation) {
          return ((orientation + 45) / 90 * 90) % 360;
      }
      return orientationHistory;
  }
}
