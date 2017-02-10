package com.ioan.delphi;

import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.Context;
import android.util.Log;

public class GCMReceiver extends BroadcastReceiver
{
	static final String TAG = "GCMReceiver";

	public native void gcmReceiverOnReceiveNative(Context context, Intent receivedIntent);

	@Override
    public void onReceive(Context context, Intent receivedIntent)
    {
		Log.d(TAG, "onReceive");
		gcmReceiverOnReceiveNative(context, receivedIntent);
    }
}