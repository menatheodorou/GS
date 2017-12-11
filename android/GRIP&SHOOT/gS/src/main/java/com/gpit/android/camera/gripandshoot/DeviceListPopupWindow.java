package com.gpit.android.camera.gripandshoot;

import java.util.ArrayList;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.PopupWindow;
import android.widget.TextView;

import com.gpit.android.camera.gripandshoot.WaitingForDeviceActivity.ViewHolder;
import com.gpit.android.camera.gripandshoot.device.SampleGattAttributes;
import com.gpit.android.util.ExtendedRunnable;

public class DeviceListPopupWindow extends PopupWindow {
	private Activity mActivity;
	private LeDeviceListAdapter mLeDeviceListAdapter;
	private ListView mListView;
	private OnItemClickListener mItemClickListener;
	
	public static DeviceListPopupWindow newInstance(Activity acitivity) {
		LayoutInflater inflator = acitivity.getLayoutInflater();
        ViewGroup rootView = (ViewGroup) inflator.inflate(R.layout.popup_device_list, null);
        
		DeviceListPopupWindow popupWindow = new DeviceListPopupWindow(acitivity, rootView, 
				LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, true);
		
		return popupWindow;
	}
	
	private DeviceListPopupWindow(Activity activity, View contentView, int width, int height, boolean focusable) {
		super(contentView, width, height, focusable);
		
		mActivity = activity;
		
		mLeDeviceListAdapter = new LeDeviceListAdapter();
		mListView = (ListView) contentView.findViewById(R.id.lvDeviceList);
        mListView.setAdapter(mLeDeviceListAdapter);
	}
	
	public boolean addDevice(BluetoothDevice device) {
		boolean result;
		
		result = mLeDeviceListAdapter.addDevice(device);
		if (result)
			mLeDeviceListAdapter.notifyDataSetChanged();
		
		return result;
	}
	
	public void clearDevice() {
		mLeDeviceListAdapter.clear();
		mLeDeviceListAdapter.notifyDataSetChanged();
	}
	
	public void setDeviceList(ArrayList<BluetoothDevice> deviceList) {
		mLeDeviceListAdapter.clear();
		for(BluetoothDevice device : deviceList) {
			mLeDeviceListAdapter.addDevice(device);
		}
	}
	
	public BluetoothDevice getDevice(int position) {
		BluetoothDevice device = mLeDeviceListAdapter.getDevice(position);
		
		return device;
	}
	
	public void notifyDataSetChanged() {
		mLeDeviceListAdapter.notifyDataSetChanged();
	}
	
	public void setOnItemClickListener(OnItemClickListener listener) {
		mItemClickListener = listener;
		mListView.setOnItemClickListener(mItemClickListener);
	}
	
	public void clearChecks() {
		mLeDeviceListAdapter.clearChecks();
	}
	
	/************************* LIST ADAPTER ***************************/
    // Adapter for holding devices found through scanning.
    private class LeDeviceListAdapter extends BaseAdapter {
        private ArrayList<BluetoothDevice> mLeDevices;
        private LayoutInflater mInflator;

        public LeDeviceListAdapter() {
            super();
            
            mLeDevices = new ArrayList<BluetoothDevice>();
            mInflator = mActivity.getLayoutInflater();
        }

        public boolean addDevice(BluetoothDevice device) {
            if(!mLeDevices.contains(device)) {
            	if (device != null && device.getName() != null && device.getName().startsWith("Grip-")) {
            		mLeDevices.add(device);
            		return true;
            	}
            }
            
            return false;
        }

        public BluetoothDevice getDevice(int position) {
        	if (mLeDevices.size() <= position)
        		return null;
        	
            return mLeDevices.get(position);
        }

        public void clear() {
            mLeDevices.clear();
        }
        
        public void clearChecks() {
        	for (int i = 0 ; i < mLeDevices.size() ; i++) {
        		View childView = getView(i, null, null);
        		ViewHolder holder = (ViewHolder) childView.getTag();
        		holder.isChecked = false;
        	}
        }

        @Override
        public int getCount() {
            return mLeDevices.size();
        }

        @Override
        public Object getItem(int i) {
            return mLeDevices.get(i);
        }

        @Override
        public long getItemId(int i) {
            return i;
        }

        @Override
        public View getView(final int i, View view, ViewGroup viewGroup) {
            ViewHolder viewHolder;
            // General ListView optimisation code.
            if (view == null) {
                view = mInflator.inflate(R.layout.listitem_device, null);
                viewHolder = new ViewHolder();
                viewHolder.deviceName = (TextView) view.findViewById(R.id.device_name);
                viewHolder.check = (ImageView) view.findViewById(R.id.ivCheck);
                view.setTag(viewHolder);
            } else {
                viewHolder = (ViewHolder) view.getTag();
            }

            BluetoothDevice device = mLeDevices.get(i);
            final String deviceName = device.getName();
            if (deviceName != null && deviceName.length() > 0) {
                viewHolder.deviceName.setText(deviceName);
            } else if (device.getAddress().equals(SampleGattAttributes.GS_DEVICE_NAME)) {
            	viewHolder.deviceName.setText(R.string.grip_device_name);
            } else {
            	viewHolder.deviceName.setText(R.string.unknown_device);
            }
            
            // check device
	        if (viewHolder.isChecked) {
	        	viewHolder.check.setVisibility(View.VISIBLE);
	        } else {
	        	viewHolder.check.setVisibility(View.INVISIBLE);
	        }
	        
	        // Compare device item with latest device address
	        String latestDeviceName, latestDeviceAddress;
	        
	        latestDeviceName = GSApp.getInstance().getLatestActiveDeviceName();
	        latestDeviceAddress = GSApp.getInstance().getLatestActiveDeviceAddress();
	        if (device.getName().equals(latestDeviceName) &&
	        		device.getAddress().equals(latestDeviceAddress)) {
	        	viewHolder.isChecked = true;
	        	viewHolder.check.setVisibility(View.VISIBLE);
        		if (mItemClickListener != null) {
        			Handler handler = new Handler();
        			handler.postDelayed(new ExtendedRunnable(view) {
						@Override
						public void run() {
							View view = (View) item;
							mItemClickListener.onItemClick(null, view, i, 0);
						}
        			}, 500);
        			
        		}
	        } else {
	        	viewHolder.isChecked = false;
	        	viewHolder.check.setVisibility(View.INVISIBLE);
	        }

            return view;
        }
    }
}
