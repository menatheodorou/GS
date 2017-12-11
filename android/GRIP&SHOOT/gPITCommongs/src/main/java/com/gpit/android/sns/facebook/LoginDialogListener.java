package com.gpit.android.sns.facebook;

import com.facebook.android.DialogError;
import com.facebook.android.Facebook.DialogListener;
import com.facebook.android.FacebookError;

import android.os.Bundle;
import android.widget.Toast;

public class LoginDialogListener implements DialogListener {
    @Override
    public void onComplete(Bundle values) {
        SessionEvents.onLoginSuccess();
    }

    @Override
    public void onFacebookError(FacebookError error) {
        SessionEvents.onLoginError(error.getMessage());
    }

    @Override
    public void onError(DialogError error) {
        SessionEvents.onLoginError(error.getMessage());
    }

    @Override
    public void onCancel() {
        SessionEvents.onLoginError("Action Canceled");
    }
}