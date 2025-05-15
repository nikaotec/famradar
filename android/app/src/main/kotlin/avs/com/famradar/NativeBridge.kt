// android/app/src/main/kotlin/avs/com/famradar/NativeBridge.kt
package avs.com.famradar

import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.SharedPreferences

class NativeBridge : MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var sharedPreferences: SharedPreferences

    fun onAttachedToEngine(context: Context, flutterEngine: FlutterEngine) {
        this.context = context
        sharedPreferences = context.getSharedPreferences("FamRadarPrefs", Context.MODE_PRIVATE)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/storage")
        channel.setMethodCallHandler(this)
    }

    private fun checkPermissions(): Boolean {
        val requiredPermissions = listOf(
            android.Manifest.permission.ACCESS_FINE_LOCATION,
            android.Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            android.Manifest.permission.POST_NOTIFICATIONS,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        return requiredPermissions.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveUserData" -> {
                val userData = call.arguments as? Map<String, Any>
                if (userData != null) {
                    with(sharedPreferences.edit()) {
                        putString("userId", userData["id"] as? String)
                        putString("name", userData["name"] as? String)
                        putString("email", userData["email"] as? String)
                        putString("phone", userData["phone"] as? String)
                        putString("photoUrl", userData["photoUrl"] as? String)
                        apply()
                    }
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "Invalid user data", null)
                }
            }
            "getUserData" -> {
                val userData = mapOf(
                    "id" to sharedPreferences.getString("userId", null),
                    "name" to sharedPreferences.getString("name", null),
                    "email" to sharedPreferences.getString("email", null),
                    "phone" to sharedPreferences.getString("phone", null),
                    "photoUrl" to sharedPreferences.getString("photoUrl", null)
                ).filterValues { it != null }
                result.success(userData)
            }
            "saveLocationSettings" -> {
                if (checkPermissions()) {
                    val interval = call.argument<Int>("interval")
                    if (interval != null) {
                        with(sharedPreferences.edit()) {
                            putInt("locationInterval", interval)
                            apply()
                        }
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid interval", null)
                    }
                } else {
                    result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                }
            }
            "getLocationSettings" -> {
                result.success(mapOf("interval" to sharedPreferences.getInt("locationInterval", 60000)))
            }
            "startLocationService" -> {
                if (checkPermissions()) {
                    LocationForegroundService.startService(context)
                    result.success(null)
                } else {
                    result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                }
            }
            "stopLocationService" -> {
                LocationForegroundService.stopService(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun onDetachedFromEngine() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        fun sendLocationToFlutter(channel: MethodChannel, location: Map<String, Any>) {
            channel.invokeMethod("onLocationUpdate", location)
        }

        fun sendGeofenceEventToFlutter(channel: MethodChannel, event: Map<String, Any>) {
            channel.invokeMethod("onGeofenceEvent", event)
        }

        fun sendIceCandidateToFlutter(channel: MethodChannel, candidate: Map<String, Any>) {
            channel.invokeMethod("onIceCandidate", candidate)
        }

        fun sendOfferToFlutter(channel: MethodChannel, offer: Map<String, Any>) {
            channel.invokeMethod("onOffer", offer)
        }

        fun sendInvitationEventToFlutter(channel: MethodChannel, event: Map<String, Any>) {
            channel.invokeMethod("onInvitationEvent", event)
        }

        fun sendErrorToFlutter(channel: MethodChannel, errorMessage: String) {
            channel.invokeMethod("onError", mapOf("errorMessage" to errorMessage))
        }
    }
}