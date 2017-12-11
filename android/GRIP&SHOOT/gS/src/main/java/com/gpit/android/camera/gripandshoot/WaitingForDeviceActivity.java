package com.gpit.android.camera.gripandshoot;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.graphics.drawable.AnimationDrawable;
import android.graphics.drawable.BitmapDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnTouchListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.gpit.android.camera.gripandshoot.camera.CameraActivity;
import com.gpit.android.util.Utils;

public class WaitingForDeviceActivity extends Activity {
	private static final int REQUEST_ENABLE_BT = 1;
	private final static int REQUEST_CODE_LAUNCH_CAMERA = 101;

	private ViewGroup mRootView;
	private ImageView mIVPressButton;
	private ImageView mIVConnecting;
	private ImageButton mIBDeviceList;
	
	private DeviceListPopupWindow mDeviceListPopupWindow;

	private boolean mLaunchedFromSplash = true;
	private boolean isPopupFirstShown = false;

	private Bitmap mSecurityMaskBitmap;
	private final static int SECURITY_TOUCH_POINT_COLOR = 0xff244ca4;

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        setContentView(R.layout.activity_waiting_for_device);
        
        mRootView = (ViewGroup) findViewById(R.id.flRoot);
        mRootView.setOnTouchListener(mTouchListener);
        
        mIVPressButton = (ImageView) findViewById(R.id.ivPressButtonAnimation);
        mIVConnecting = (ImageView) findViewById(R.id.ivConnecting);
        mIBDeviceList = (ImageButton) findViewById(R.id.ibDeviceList);
        mIBDeviceList.setOnClickListener(mDeviceClickListener);
        
        if (!Constant.ENABLE_GS_DEVICE) {
        	final Intent intent = new Intent(WaitingForDeviceActivity.this, CameraActivity.class);
            startActivityForResult(intent, REQUEST_CODE_LAUNCH_CAMERA);
	        finish();
	        return;
        }
        
        initPopup();
        createMaskBitmap();
        
        startGuideAnimation();
        startConnectingAnimation();
    }
    
    @Override
    protected void onResume() {
        super.onResume();

    	mDeviceListPopupWindow.clearDevice();
    	// mDeviceListPopupWindow.clearChecks();
    	hideDeviceList();
        
        // Ensures Bluetooth is enabled on the device.  If Bluetooth is not currently enabled,
        // fire an intent to display a dialog asking the user to grant permission to enable it.
        if (!GSApp.getInstance().bluetoothAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        } else {
        	GSApp.getInstance().scanLeDevice(true, mLeScanCallback);
        }
    }
    
    @Override
    protected void onPause() {
    	super.onPause();
    	
    	GSApp.getInstance().scanLeDevice(false, mLeScanCallback);
    	mDeviceListPopupWindow.dismiss();

        mLaunchedFromSplash = false;
    	isPopupFirstShown = false;
    }
    
    @Override
    protected void onDestroy() {
    	super.onDestroy();
    	
    	GSApp.getInstance().scanLeDevice(false, mLeScanCallback);
    	mDeviceListPopupWindow.dismiss();
    }
    
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        // User chose not to enable Bluetooth.
        if (requestCode == REQUEST_ENABLE_BT) {
            if (resultCode == Activity.RESULT_CANCELED) {
                finish();
                return;
            }
        } else {
            mLaunchedFromSplash = false;
        }

        super.onActivityResult(requestCode, resultCode, data);
    }
    
    public void startGuideAnimation() {
    	// Start animating the image
    	mIVPressButton.setBackgroundResource(R.drawable.device_press_anim);
	    final AnimationDrawable frameAnimation = (AnimationDrawable)mIVPressButton.getBackground();
	    frameAnimation.setOneShot(false);
	    mIVPressButton.post(new Runnable() {
			@Override
			public void run() {
			    frameAnimation.start();
			}
		});
    }
    
    
    public void startConnectingAnimation() {
    	// Start animating the image
    	mIVConnecting.setBackgroundResource(R.drawable.connecting_anim);
	    final AnimationDrawable frameAnimation = (AnimationDrawable)mIVConnecting.getBackground();
	    mIVConnecting.post(new Runnable() {
			@Override
			public void run() {
			    frameAnimation.start();
			}
		});
    }
    
    private void stopConnectingAnimation() {
    	
    }
    
    /************************* Bitmap mask for security pass *********************/
    private void createMaskBitmap() {
    	int width = Utils.getScreenWidth(this);
    	int height = Utils.getScreenHeight(this);
    	
    	mSecurityMaskBitmap = createResizedBitmap(this, R.drawable.trigger_mask, width, height);
    }
    
    private Bitmap createResizedBitmap(Context c, int id, int w, int h) {
		Bitmap bitmapOrg = BitmapFactory.decodeResource(c.getResources(),id);
		Bitmap result;
		
		int width = bitmapOrg.getWidth();
		int height = bitmapOrg.getHeight();
		int newWidth = w;
		int newHeight = h;

		float scaleWidth = ((float) newWidth) / width;
		float scaleHeight = ((float) newHeight) / height;

		Matrix matrix = new Matrix();
		matrix.postScale(scaleWidth, scaleHeight); 
		result = Bitmap.createBitmap(bitmapOrg, 0, 0,
				width, height, matrix, true);
		return result;
	}
    
    /************************* POPUP LIST ************************/
    private void initPopup() {
    	mDeviceListPopupWindow = DeviceListPopupWindow.newInstance(this);
    	
        mDeviceListPopupWindow.setOutsideTouchable(true);
        mDeviceListPopupWindow.setFocusable(true);
        // http://stackoverflow.com/questions/3121232/android-popup-window-dismissal
        mDeviceListPopupWindow.setBackgroundDrawable(new BitmapDrawable());
        mDeviceListPopupWindow.setInputMethodMode(PopupWindow.INPUT_METHOD_NOT_NEEDED);
        mDeviceListPopupWindow.setOnItemClickListener(mItemClickListener);
    }
    
    private void showDeviceList() {
    	try {
    		if (!mDeviceListPopupWindow.isShowing())
    			mDeviceListPopupWindow.showAtLocation(mRootView, Gravity.BOTTOM | Gravity.RIGHT, 0, 0);
    	} catch (Exception e) {
    		e.printStackTrace();
    	}
    }
    
    private void hideDeviceList() {
    	if (mDeviceListPopupWindow.isShowing())
    		mDeviceListPopupWindow.dismiss();
    }
    
    /************************* EVENT LISTENER ********************/
    private OnClickListener mDeviceClickListener = new OnClickListener() {
		@Override
		public void onClick(View v) {
			if (mDeviceListPopupWindow.isShowing()) {
				hideDeviceList();
			} else {
				showDeviceList();
			}
		}
	};
	
	private OnTouchListener mTouchListener = new OnTouchListener() {
		@Override
		public boolean onTouch(View v, MotionEvent event) {
			Integer color = mSecurityMaskBitmap.getPixel((int)event.getX(), (int)event.getY());
			if (color == SECURITY_TOUCH_POINT_COLOR) {
				// Lets pass to camera screen
				final Intent intent = new Intent(WaitingForDeviceActivity.this, CameraActivity.class);
		        startActivityForResult(intent, REQUEST_CODE_LAUNCH_CAMERA);
			}
			
			return false;
		}
	};
	
	/************************** BLUETOOTH LISTENER **********************/
	// Device scan callback.
    private BluetoothAdapter.LeScanCallback mLeScanCallback =
            new BluetoothAdapter.LeScanCallback() {

        @Override
        public void onLeScan(final BluetoothDevice device, int rssi, byte[] scanRecord) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                	stopConnectingAnimation();
                	
                    if (mDeviceListPopupWindow.addDevice(device)) {
                    	GSApp.getInstance().deviceList.add(device);
                    	
                    	if (!isPopupFirstShown) {
                        	showDeviceList();
                        	isPopupFirstShown = true;
                        }
                    }
                }
            });
        }
    };
    
    static class ViewHolder {
        TextView deviceName;
        ImageView check;
        boolean isChecked = false;
    }
    
    private OnItemClickListener mItemClickListener = new OnItemClickListener() {
		@Override
		public void onItemClick(AdapterView<?> adapterView, View v, int position,
				long arg3) {
			if (CameraActivity.isCameraActivityOn)
				return;

            // Its means, this activity comes from back button or setting activity, so we don't have to show next screen automatically.
			if (adapterView == null && !mLaunchedFromSplash) return;

			final BluetoothDevice device = mDeviceListPopupWindow.getDevice(position);
	        if (device == null) return;
	        
	        // check device
	        ViewHolder viewHolder = (ViewHolder) v.getTag();
	        viewHolder.isChecked = !viewHolder.isChecked;
	        
	        // stop scan.
	        GSApp.getInstance().scanLeDevice(false, mLeScanCallback);
	        
	        CameraActivity.isCameraActivityOn = true;
	        
	        final Intent intent = new Intent(WaitingForDeviceActivity.this, CameraActivity.class);
	        intent.putExtra(CameraActivity.EXTRAS_DEVICE_NAME, device.getName());
	        intent.putExtra(CameraActivity.EXTRAS_DEVICE_ADDRESS, device.getAddress());
	        GSApp.getInstance().saveLatestActiveDevice(device.getName(), device.getAddress());

            startActivityForResult(intent, REQUEST_CODE_LAUNCH_CAMERA);

	        mDeviceListPopupWindow.notifyDataSetChanged();
		}
	};
}
