package com.peer1.internetmap;

import java.io.UnsupportedEncodingException;

import org.apache.http.entity.StringEntity;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.loopj.android.http.AsyncHttpClient;
import com.loopj.android.http.AsyncHttpResponseHandler;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.support.v4.app.NavUtils;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.PopupWindow;
import android.widget.ProgressBar;
import android.widget.Toast;

public class SalesPopup extends Activity{
    private static String TAG = "SalesPopup";

    @SuppressLint("NewApi")
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.contactsales);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            getActionBar().setDisplayHomeAsUpEnabled(true);
        }

        View submitButton = findViewById(R.id.submitButton);
        submitButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View arg0) {
                //validate (split so that we do not short-circuit past any check).
                boolean valid = validateName();
                valid = validateEmail() && valid;
                
                if (valid) {
                    submit();
                }
            }
        });
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
        case android.R.id.home:
            NavUtils.navigateUpFromSameTask(this);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
    
    private boolean validateName() {
        EditText nameEdit = (EditText) findViewById(R.id.nameEdit);
        if (nameEdit.getText().length() == 0) {
            //ideally we'd use setError, but it's unbelievably buggy, so we're stuck with a toast :P
            Toast.makeText(this, getString(R.string.requiredName),  Toast.LENGTH_SHORT).show();
            return false;
        }
        return true;
    }

    private boolean validateEmail() {
        EditText edit = (EditText) findViewById(R.id.emailEdit);
        if (edit.getText().length() == 0) {
            //ideally we'd use setError, but it's unbelievably buggy, so we're stuck with a toast :P
            Toast.makeText(this, getString(R.string.requiredEmail),  Toast.LENGTH_SHORT).show();
            return false;
        }
        return true;
    }
    
    private void submit() {
        if (!Helper.haveConnectivity(this)) {
            return;
        }
        //Log.d(TAG, "submit");
        
        //package up the data
        JSONObject postData = new JSONObject();
        try {
            postData.put("LeadSource", "Map of the Internet");
            postData.put("Website_Source__c", Helper.isSmallScreen(this) ? "Android Phone" : "Android Tablet");
            
            EditText nameEdit = (EditText) findViewById(R.id.nameEdit);
            postData.put("fullName", nameEdit.getText().toString());
            EditText emailEdit = (EditText) findViewById(R.id.emailEdit);
            postData.put("email", emailEdit.getText().toString());
            EditText phoneEdit = (EditText) findViewById(R.id.phoneEdit);
            postData.put("phone", phoneEdit.getText().toString());
        } catch (JSONException e) {
            //I'm not feeding it anything risky, it'll be fine.
            e.printStackTrace();
            return;
        }
        
        StringEntity entity = null;
        try{
            entity = new StringEntity(postData.toString());
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            return;
            //FIXME Do we want to notify the user if we have some kind of encoding exception?
        }
        entity.setContentType("application/json");
        
        Log.d(TAG, "starting httpclient");
        
        //prevent doubleclicking
        final Button button = (Button) findViewById(R.id.submitButton);
        button.setEnabled(false);
        //start spinning
        final ProgressBar progress = (ProgressBar) findViewById(R.id.progressBar);
        progress.setVisibility(View.VISIBLE);
        
        //send it off to the internet
        AsyncHttpClient client = new AsyncHttpClient();
        client.post(null, "http://www.peer1.com/contact-sales", entity, "application/json", new AsyncHttpResponseHandler(){
            @Override
            public void onStart(){
                Log.d(TAG, "started");
            }
            @Override
            public void onSuccess(String response) {
                Log.d(TAG, String.format("Success! response: %s", response));
                Toast.makeText(SalesPopup.this, getString(R.string.submitSuccess),  Toast.LENGTH_SHORT).show();
                NavUtils.navigateUpFromSameTask(SalesPopup.this);
            }
            @Override
            public void onFailure(Throwable error, String content) {
                Log.d(TAG, String.format("error: '%s' content: '%s'", error.getMessage(), content));
                String message = "";
                String errorType = error.getMessage(); //we have to use this instead of the http code
                if (errorType != null && errorType.equals("Unprocessable Entity")) {
                    try {
                        JSONArray jsonArray = new JSONArray(content);
                        JSONObject jsonObject = jsonArray.getJSONObject(0);
                        String field = jsonObject.getString("field");
                        if (field.equals("email")) {
                            //friendly message
                            message = getString(R.string.submitFailEmail);
                        } else {
                            //raw error text
                            message = jsonObject.getString("error");
                            if (!message.isEmpty() && !field.isEmpty()) {
                                message += " : " + field;
                            }
                        }
                    } catch (Exception e) {
                        Log.d(TAG, String.format("json error: %s", e.getMessage()));
                    }
                }
                
                if (message.isEmpty()){
                    //generic error message
                    message = getString(R.string.submitFail);
                }
                Helper.showError(SalesPopup.this, message);
                button.setEnabled(true);
                progress.setVisibility(View.INVISIBLE);
            }
            @Override
            public void onFinish() {
                Log.d(TAG, "ended");
            }
        });
        
    }

}
