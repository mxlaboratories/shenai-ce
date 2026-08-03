package ai.mxlabs.shenai.ce.androidkotlin.minimal

import ai.mxlabs.shenai_sdk.ShenAIAndroidSDK
import ai.mxlabs.shenai_sdk.ShenAIView
import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView

class MainActivity : Activity() {
  private val shenaiSdk = ShenAIAndroidSDK()
  private var initialized = false
  private var shenaiView: ShenAIView? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

    if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
      initializeSdk()
    } else {
      requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST_CODE)
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == CAMERA_PERMISSION_REQUEST_CODE &&
      grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
    ) {
      initializeSdk()
    } else {
      setContentView(statusView("Camera permission is required"))
    }
  }

  override fun onPause() {
    shenaiView?.activityPaused()
    super.onPause()
  }

  override fun onResume() {
    super.onResume()
    shenaiView?.activityResumed()
  }

  override fun onDestroy() {
    if (initialized) {
      shenaiSdk.deinitialize()
      initialized = false
    }
    super.onDestroy()
  }

  private fun initializeSdk() {
    if (CeConfig.API_KEY.isBlank()) {
      setContentView(statusView("Missing SHENAI_API_KEY"))
      return
    }

    setContentView(statusView("Initializing SDK"))

    val settings = shenaiSdk.defaultInitializationSettings
    settings.initializationMode = ShenAIAndroidSDK.InitializationMode.MEASUREMENT

    val result = shenaiSdk.initialize(this, CeConfig.API_KEY, CeConfig.USER_ID, settings)
    if (result != ShenAIAndroidSDK.InitializationResult.OK) {
      setContentView(statusView("Initialization failed: $result"))
      return
    }

    initialized = true
    shenaiSdk.setLanguage(CeConfig.LANGUAGE)
    shenaiView = ShenAIView(this)
    setContentView(shenaiView)
  }

  private fun statusView(message: String): TextView {
    return TextView(this).apply {
      gravity = Gravity.CENTER
      text = message
      textSize = 16f
    }
  }
  private companion object {
    const val CAMERA_PERMISSION_REQUEST_CODE = 1001
  }
}
