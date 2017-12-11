/*
 * Copyright (C) 2013 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.gpit.android.camera.gripandshoot.device;

import java.util.HashMap;

/**
 * This class includes a small subset of standard GATT attributes for demonstration purposes.
 */
public class SampleGattAttributes {
    private static HashMap<String, String> attributes = new HashMap();
    public static String GS_DEVICE_NAME = "5F:39:B3:0C:5F:CA";
    public static String GS_SHOOT = "0000ffa0-0000-1000-8000-00805f9b34fb";
    public static String GS_SHOOT_BUTTON = "0000ffa1-0000-1000-8000-00805f9b34fb";
    public static String GS_UNKNOWN1 = "00001800-0000-1000-8000-00805f9b34fb";
    public static String GS_UNKNOWN2 = "00001801-0000-1000-8000-00805f9b34fb";
    
    public final static String GS_BUTTON_SHOOT = "01 00 01";
    public final static String GS_BUTTON_PLUS_UP = "03 00 00";
    public final static String GS_BUTTON_PLUS_DOWN = "03 00 01";
    public final static String GS_BUTTON_MINUS_UP = "04 00 00";
    public final static String GS_BUTTON_MINUS_DOWN = "04 00 01";
    
    public static String CLIENT_CHARACTERISTIC_CONFIG = "00002902-0000-1000-8000-00805f9b34fb";

    static {
        // Sample Services.
        attributes.put("0000180d-0000-1000-8000-00805f9b34fb", "Heart Rate Service");
        attributes.put("0000180a-0000-1000-8000-00805f9b34fb", "Device Information Service");
        // Sample Characteristics.
        attributes.put(GS_UNKNOWN1, "GS Unknown1");
        attributes.put(GS_UNKNOWN2, "GS Unknown2");
        attributes.put(GS_SHOOT, "GS Shoot");
        attributes.put(GS_SHOOT_BUTTON, "GS Shoot Button");
        attributes.put("00002a29-0000-1000-8000-00805f9b34fb", "Manufacturer Name String");
    }

    public static String lookup(String uuid, String defaultName) {
        String name = attributes.get(uuid);
        return name == null ? defaultName : name;
    }
}
