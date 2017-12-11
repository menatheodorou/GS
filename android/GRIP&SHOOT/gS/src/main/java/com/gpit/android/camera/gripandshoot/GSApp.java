package com.gpit.android.camera.gripandshoot;

import android.app.Application;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.preference.PreferenceManager;

import java.util.ArrayList;

public class GSApp extends Application {
	public final static String TAG = GSApp.class.getSimpleName();

	// Global Object
	public static GSApp APP;

	// Bluetooth
	private final static String PREFS_KEY_LATEST_BL_DEVICE_ADDRESS = "latest_bluetooth_device_address";
	private final static String PREFS_KEY_LATEST_BL_DEVICE_NAME = "latest_bluetooth_device_name";
	private final static long SCAN_PERIOD = 10000;
	public BluetoothAdapter bluetoothAdapter;
	public BluetoothManager bluetoothManager;
	private Handler mHandler;
	private boolean mScanning;
	
	// Preference
	public SharedPreferences prefs;
	public SharedPreferences.Editor prefsEditor;
	
	public ArrayList<BluetoothDevice> deviceList = new ArrayList<BluetoothDevice>();
	
	public static GSApp getInstance() {
		return APP;
	}
	
	@Override
	public void onCreate() {
		super.onCreate();

		
		APP = this;
		
		initApp();
	}
	
	private void initApp() {
		// Initialize crittercism module
		/*
		CrittercismConfig config = new CrittercismConfig();
		config.setLogcatReportingEnabled(true);
		Crittercism.initialize(getApplicationContext(), Constant.CRITTERCISM_API_KEY, config);
		*/
		
		prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefsEditor = prefs.edit();
        
		initBluetooth();
	}
	
	/************** BLUETOOTH ****************/
	private void initBluetooth() {
		// Initializes a Bluetooth adapter.  For API level 18 and above, get a reference to
        // BluetoothAdapter through BluetoothManager.
        bluetoothManager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
	}
	

    public boolean scanLeDevice(final boolean enable, final LeScanCallback callback) {
    	boolean result = true;
    	
    	mHandler = new Handler();
        if (enable) {
        	/*
            // Stops scanning after a pre-defined scan period.
            mHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    mScanning = false;
                    bluetoothAdapter.stopLeScan(callback);
                }
            }, SCAN_PERIOD);
        	*/
        	
            mScanning = true;
            deviceList.clear();
            bluetoothAdapter.stopLeScan(callback);
            result = bluetoothAdapter.startLeScan(callback);
        } else {
            mScanning = false;
            bluetoothAdapter.stopLeScan(callback);
        }
        
        return result;
    }
    
    public String getLatestActiveDeviceName() {
    	String device = prefs.getString(PREFS_KEY_LATEST_BL_DEVICE_NAME, null);
    	
    	return device;
    }
    
    public String getLatestActiveDeviceAddress() {
    	String device = prefs.getString(PREFS_KEY_LATEST_BL_DEVICE_ADDRESS, null);
    	
    	return device;
    }
    
    public void saveLatestActiveDevice(String name, String address) {
    	prefsEditor.putString(PREFS_KEY_LATEST_BL_DEVICE_NAME, name);
    	prefsEditor.putString(PREFS_KEY_LATEST_BL_DEVICE_ADDRESS, address);
    	prefsEditor.commit();
    }
}
