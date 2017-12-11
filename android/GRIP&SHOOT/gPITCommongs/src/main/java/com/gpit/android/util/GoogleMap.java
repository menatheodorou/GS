package com.gpit.android.util;

import java.util.ArrayList;

import android.content.Context;
import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapController;

public class GoogleMap {
	private static GoogleMap map;
	
	public static GoogleMap getInstance(Context context) {
		if (map == null)
			map = new GoogleMap(context);
		
		return map;
	}
	
	private Context mContext;
	private GoogleMap(Context context) {
		mContext = context;
	}
	
	public void setZoomByMutliLocation(MapController mapController, ArrayList<GeoPoint> locations) {
		double fitFactor = 1.5;
		int minLat = Integer.MAX_VALUE;
		int maxLat = Integer.MIN_VALUE;
		int minLon = Integer.MAX_VALUE;
		int maxLon = Integer.MIN_VALUE;

		for (GeoPoint item : locations) { 
		      int lat = item.getLatitudeE6();
		      int lon = item.getLongitudeE6();

		      maxLat = Math.max(lat, maxLat);
		      minLat = Math.min(lat, minLat);
		      maxLon = Math.max(lon, maxLon);
		      minLon = Math.min(lon, minLon);
		 }

		mapController.zoomToSpan((int)(Math.abs(maxLat - minLat) * fitFactor), (int)(Math.abs(maxLon - minLon) * fitFactor));
		mapController.animateTo(new GeoPoint((maxLat + minLat)/2, (maxLon + minLon)/2));
	}
}
