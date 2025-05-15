// android/app/src/main/kotlin/avs/com/famradar/GeofenceBroadcastReceiver.kt
package avs.com.famradar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import io.flutter.plugin.common.MethodChannel

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val CHANNEL = "avs.com.famradar/geofence_events"
        lateinit var channel: MethodChannel
    }

    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        if (geofencingEvent == null || geofencingEvent.hasError()) {
            val errorMessage = "Geofence error: ${geofencingEvent?.errorCode ?: "Unknown"}"
            NativeBridge.sendErrorToFlutter(channel, errorMessage)
            return
        }

        val geofenceTransition = geofencingEvent.geofenceTransition
        val triggeringGeofences = geofencingEvent.triggeringGeofences

        when (geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER,
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                triggeringGeofences?.forEach { geofence ->
                    val event = mapOf(
                        "type" to if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER) "enter" else "exit",
                        "geofenceId" to geofence.requestId,
                        "timestamp" to System.currentTimeMillis()
                    )
                    NativeBridge.sendGeofenceEventToFlutter(channel, event)
                }
            }
            else -> {
                NativeBridge.sendErrorToFlutter(channel, "Invalid geofence transition: $geofenceTransition")
            }
        }

        // Send location update if available
        geofencingEvent.triggeringLocation?.let { location ->
            val locationData = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "timestamp" to location.time
            )
            NativeBridge.sendLocationToFlutter(channel, locationData)
        }
    }
}