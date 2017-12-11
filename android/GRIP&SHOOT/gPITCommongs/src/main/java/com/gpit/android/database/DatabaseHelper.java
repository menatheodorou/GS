/*
 * Translating Keyboard
 * Copyright (C) 2011 Barry Fruitman
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
 * 
 */

package com.gpit.android.database;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import android.database.sqlite.SQLiteOpenHelper;

public class DatabaseHelper extends SQLiteOpenHelper {
	protected static DatabaseHelper databaseHelper;
	
	protected Context mContext;

	// Defines database name and table names
	public static String DB_NAME = "poophappened.sqlite";// the extension may
															// be .sqlite or .db

	// Defines db error
	public enum DBError {
		DB_ERROR_NONE, DB_ERROR_FAILED, DB_ERROR_ALREADY_EXIST, DB_ERROR_NOT_EXIST,
	};

	private String DB_PATH;

	protected SQLiteDatabase mDatabase;
	
	public static DatabaseHelper getInstance(Context context) {
		if (databaseHelper == null) {
			try {
				databaseHelper = new DatabaseHelper(context);
			} catch (Exception e) {}
		}
		
		return databaseHelper;
	}
	
	protected DatabaseHelper(Context context) throws IOException {
		super(context, DB_NAME, null, 1);
		mContext = context;

		DB_PATH = "/data/data/"
				+ mContext.getApplicationContext().getPackageName()
				+ "/databases/";

		boolean dbexist = checkDatabase();
		if (dbexist) {
			openDatabase();
		} else {
			createDatabase();
			openDatabase();
		}
	}

	public void createDatabase() throws IOException {
		boolean dbexist = checkDatabase();

		if (dbexist) {
			System.out.println(" Database exists.");
		} else {
			this.getWritableDatabase();
			try {
				copyDatabase();
			} catch (IOException e) {
				// throw new Error("Error copying mDatabase");
			}
		}
	}

	public void closeDatabase() {
		mDatabase.close();
	}

	private boolean checkDatabase() {
		boolean checkdb = false;
		try {
			String myPath = DB_PATH + DB_NAME;
			File dbfile = new File(myPath);
			checkdb = dbfile.exists();
		} catch (SQLiteException e) {
			System.out.println("Database doesn't exist");
		}

		return checkdb;
	}

	public void copyDatabase(String orgPath) throws IOException {
		// Open your local db as the input stream
		FileInputStream input = new FileInputStream(orgPath);

		// Open the empty db as the output stream
		String myDBPath = DB_PATH + DB_NAME;
		(new File(myDBPath)).delete();

		OutputStream output = new FileOutputStream(myDBPath);

		// transfer byte to inputfile to outputfile
		byte[] buffer = new byte[1024];
		int length;
		while ((length = input.read(buffer)) > 0) {
			output.write(buffer, 0, length);
		}

		// Close the streams
		output.flush();
		output.close();
		input.close();
	}

	private void copyDatabase() throws IOException {
		// Open your local db as the input stream
		InputStream input = mContext.getAssets().open(DB_NAME);

		// Open the empty db as the output stream
		String myDBPath = DB_PATH + DB_NAME;

		OutputStream output = new FileOutputStream(myDBPath);

		// transfer byte to inputfile to outputfile
		byte[] buffer = new byte[1024];
		int length;
		while ((length = input.read(buffer)) > 0) {
			output.write(buffer, 0, length);
		}

		// Close the streams
		output.flush();
		output.close();
		input.close();
	}

	public void openDatabase() throws SQLException {
		// Open the mDatabase
		String mypath = DB_PATH + DB_NAME;
		mDatabase = SQLiteDatabase.openDatabase(mypath, null,
				SQLiteDatabase.OPEN_READWRITE);
	}

	@Override
	public void onCreate(SQLiteDatabase arg0) {
		// TODO Auto-generated method stub

	}

	@Override
	public void onUpgrade(SQLiteDatabase arg0, int arg1, int arg2) {
		// TODO Auto-generated method stub
	}
	
	/************************************* SAMPLE *************************************/
	/*
	// Load all user list
	public DBError loadUsers(ArrayList<User> userList) {
		// clear all user list
		Assert.assertTrue(userList != null);
		userList.clear();

		try {
			Cursor listCursor = mDatabase.query("tbl_user", null, null, null,
					null, null, null);
			if (listCursor == null)
				return DBError.DB_ERROR_FAILED;

			while (listCursor.moveToNext() == true) {
				User newUser = new User();
				newUser.name = listCursor.getString(listCursor.getColumnIndex("name"));
				newUser.email = listCursor.getString(listCursor.getColumnIndex("email"));

				userList.add(newUser);
			}

			// Close query
			listCursor.close();
		} catch (SQLiteException e) {
			Log.e(CamShareApp.LOG_TAG, e.getMessage(), e);
			return DBError.DB_ERROR_FAILED;
		}

		return DBError.DB_ERROR_NONE;
	}

	// Update user
	public DBError updateUser(User user) {
		Assert.assertTrue(user != null);
		
		DBError result = DBError.DB_ERROR_NONE;
		try {
			// Append new shortcut item to mDatabase
			ContentValues values = new ContentValues();
			values.put("name", user.name);
			values.put("email", user.email);

			long ret = mDatabase.update("tbl_user", values, "email=?" ,
					new String[] { user.email });
			if (ret == -1)
				result = DBError.DB_ERROR_FAILED;
			else if (ret == 0)
				result = DBError.DB_ERROR_NOT_EXIST;

		} catch (SQLiteException e) {
			Log.e(CamShareApp.LOG_TAG, e.getMessage(), e);
			result = DBError.DB_ERROR_FAILED;
		}
		
		return result;
	}
	
	// Add user
	public DBError addUser(User newUser) {
		ContentValues values = new ContentValues();
		long result;
		
		Assert.assertTrue(newUser != null);
		
		// Append new phonebook item to mDatabase
		values.put("name",  newUser.name);
		values.put("email",  newUser.email);
		
		result = mDatabase.insert("tbl_user", null, values);
		if (result == -1)
			return DBError.DB_ERROR_FAILED;
		
		return DBError.DB_ERROR_NONE;
	}
	
	// Get user
	public User getUser(String email) {
		Assert.assertTrue(email != null);

		User newUser = null;
		
		try {
			Cursor listCursor = mDatabase.query("tbl_user", null, "email=?", new String[] {email}, 
					null, null, null);
			if (listCursor == null)
				return null;

			while (listCursor.moveToNext() == true) {
				newUser.name = listCursor.getString(listCursor.getColumnIndex("name"));
				newUser.email = listCursor.getString(listCursor.getColumnIndex("email"));
				break;
			}

			// Close query
			listCursor.close();
		} catch (SQLiteException e) {
			Log.e(CamShareApp.LOG_TAG, e.getMessage(), e);
		}
		
		return newUser;
	}
	
	// Remove user
	public DBError removeUser(User user) {
		int result;

		result = mDatabase.delete("tbl_user", "email=?", new String[] {user.email});

		if (result == -1)
			return DBError.DB_ERROR_FAILED;
		else if (result == 0)
			return DBError.DB_ERROR_NOT_EXIST;
		else
			return DBError.DB_ERROR_NONE;
	}
	*/
}