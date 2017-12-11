package com.gpit.android.sns.twitter;

public interface WebListener {

	void onComplete(String url);

	void onCancel();

	void onError(String error);

	void onDialogError(DialogError dialogError);

}
