package ai.mxlabs.shenai.ce.androidjava.minimal;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;

import androidx.activity.ComponentActivity;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts.RequestPermission;
import androidx.core.content.ContextCompat;

import ai.mxlabs.shenai_sdk.ShenAIAndroidSDK;
import ai.mxlabs.shenai_sdk.ShenAIView;

public class MainActivity extends ComponentActivity {
    private final ShenAIAndroidSDK shenaiSdk = new ShenAIAndroidSDK();
    private boolean initialized;
    private ShenAIView shenaiView;

    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(new RequestPermission(), granted -> {
                if (granted) {
                    initializeSdk();
                } else {
                    setContentView(statusView("Camera permission is required"));
                }
            });

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            initializeSdk();
        } else {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA);
        }
    }

    @Override
    protected void onPause() {
        if (shenaiView != null) {
            shenaiView.activityPaused();
        }
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (shenaiView != null) {
            shenaiView.activityResumed();
        }
    }

    @Override
    protected void onDestroy() {
        if (initialized) {
            shenaiSdk.deinitialize();
            initialized = false;
        }
        super.onDestroy();
    }

    private void initializeSdk() {
        if (CeConfig.API_KEY.isEmpty()) {
            setContentView(statusView("Missing SHENAI_API_KEY"));
            return;
        }

        setContentView(statusView("Initializing SDK"));

        ShenAIAndroidSDK.InitializationSettings settings = shenaiSdk.getDefaultInitializationSettings();
        settings.initializationMode = ShenAIAndroidSDK.InitializationMode.MEASUREMENT;

        ShenAIAndroidSDK.InitializationResult result =
                shenaiSdk.initialize(this, CeConfig.API_KEY, CeConfig.USER_ID, settings);

        if (result != ShenAIAndroidSDK.InitializationResult.OK) {
            setContentView(statusView("Initialization failed: " + result));
            return;
        }

        initialized = true;
        shenaiSdk.setLanguage(CeConfig.LANGUAGE);
        shenaiView = new ShenAIView(this);
        setContentView(shenaiView);
    }

    private TextView statusView(String message) {
        TextView view = new TextView(this);
        view.setGravity(Gravity.CENTER);
        view.setText(message);
        view.setTextSize(16);
        return view;
    }
}
