package com.peer1.internetmap;

import android.content.Context;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.PopupWindow;
import android.widget.Toast;

public class SalesPopup extends PopupWindow{
    private static String TAG = "SalesPopup";
    private Context mContext;

    public SalesPopup(final InternetMap context, View view) {
        super(view, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        setOutsideTouchable(true);
        setFocusable(true);
        mContext = context;

        View closeButton = getContentView().findViewById(R.id.closeBtn);
        closeButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                SalesPopup.this.dismiss();
            }
        });

        View submitButton = getContentView().findViewById(R.id.submitButton);
        submitButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                //validate (split so that we do not short-circuit past any check).
                boolean valid = validateName();
                valid = validateEmail() && valid;
                if (valid) {
                    Log.d(TAG, "TODO: submit");
                    SalesPopup.this.dismiss();
                }
            }
        });
    }
    
    private boolean validateName() {
        EditText nameEdit = (EditText) getContentView().findViewById(R.id.nameEdit);
        if (nameEdit.getText().length() == 0) {
            //ideally we'd use setError, but it's unbelievably buggy, so we're stuck with a toast :P
            Toast.makeText(mContext, mContext.getString(R.string.requiredName),  Toast.LENGTH_SHORT).show();
            return false;
        }
        return true;
    }

    private boolean validateEmail() {
        EditText edit = (EditText) getContentView().findViewById(R.id.emailEdit);
        if (edit.getText().length() == 0) {
            //ideally we'd use setError, but it's unbelievably buggy, so we're stuck with a toast :P
            Toast.makeText(mContext, mContext.getString(R.string.requiredEmail),  Toast.LENGTH_SHORT).show();
            return false;
        }
        return true;
    }


}
