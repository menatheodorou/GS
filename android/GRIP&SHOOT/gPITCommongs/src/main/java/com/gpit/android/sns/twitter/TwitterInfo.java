package com.gpit.android.sns.twitter;

public class TwitterInfo {
	public boolean useState;
	public String userName;
	public String userEmail;
	public String accessToken;
	public String accessSecret;
	
	public TwitterInfo() {};
	
	public TwitterInfo(boolean useState, String username, String userEmail, String accessToken, String accessSecret) {
		this.useState = useState;
		this.userName = username;
		this.userEmail = userEmail;
		this.accessToken = accessToken;
		this.accessSecret = accessSecret;
	}
}
