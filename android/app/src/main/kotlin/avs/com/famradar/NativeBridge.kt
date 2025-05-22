package avs.com.famradar

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeBridge : MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var activity: MainActivity
    private lateinit var storageChannel: MethodChannel
    private lateinit var sharedPreferences: SharedPreferences

    fun onAttachedToEngine(context: Context, activity: MainActivity, flutterEngine: FlutterEngine) {
        this.context = context
        this.activity = activity
        sharedPreferences = context.getSharedPreferences("FamRadarPrefs", Context.MODE_PRIVATE)

        // Initialize storage channel
        storageChannel =
                MethodChannel(
                        flutterEngine.dartExecutor.binaryMessenger,
                        "avs.com.famradar/storage"
                )
        storageChannel.setMethodCallHandler(this)
    }

    private fun checkPermissions(): Boolean {
        return LocationPermissionHelper.hasAllLocationPermissions(context)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Storage channel methods
            "saveUserData" -> {
                if (checkPermissions()) {
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
                } else {
                    result.error("PERMISSION_DENIED", "Storage permission not granted", null)
                }
            }
            "getUserData" -> {
                val userData =
                        mapOf(
                                        "id" to sharedPreferences.getString("userId", null),
                                        "name" to sharedPreferences.getString("name", null),
                                        "email" to sharedPreferences.getString("email", null),
                                        "phone" to sharedPreferences.getString("phone", null),
                                        "photoUrl" to sharedPreferences.getString("photoUrl", null)
                                )
                                .filterValues { it != null }
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
                result.success(
                        mapOf("interval" to sharedPreferences.getInt("locationInterval", 60000))
                )
            }
            "startLocationService" -> {
                if (checkPermissions()) {
                    val userId = call.argument<String>("userId")
                    val intent =
                            Intent(context, LocationForegroundService::class.java).apply {
                                if (userId != null) putExtra("userId", userId)
                            }
                    context.startService(intent)
                    result.success(null)
                } else {
                    result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                }
            }
            "stopLocationService" -> {
                val intent = Intent(context, LocationForegroundService::class.java)
                context.stopService(intent)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun onDetachedFromEngine() {
        storageChannel.setMethodCallHandler(null)
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
