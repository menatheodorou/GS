package com.gpit.android.sns.twitter;

public interface AuthListener {
	public abstract void authFinished();
	public abstract void authFailed();
}