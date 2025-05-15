// android/app/src/main/kotlin/avs/com/famradar/GeofenceHelper.kt
package avs.com.famradar

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import io.flutter.plugin.common.MethodChannel
import java.util.*

class GeofenceHelper(private val context: Context, private val channel: MethodChannel) {
    private val geofencingClient: GeofencingClient = context.getSystemService(GeofencingClient::class.java)
        ?: throw IllegalStateException("GeofencingClient not available")

    fun addGeofence(geofenceId: String, latitude: Double, longitude: Double, radius: Float) {
        val geofence = Geofence.Builder()
            .setRequestId(geofenceId)
            .setCircularRegion(latitude, longitude, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
            .build()

        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofence(geofence)
            .build()

        val pendingIntent = getGeofencePendingIntent()

        try {
            geofencingClient.addGeofences(geofencingRequest, pendingIntent).addOnSuccessListener {
                val event = mapOf(
                    "type" to "geofence_added",
                    "geofenceId" to geofenceId,
                    "timestamp" to System.currentTimeMillis()
                )
                NativeBridge.sendGeofenceEventToFlutter(channel, event)
            }.addOnFailureListener { e ->
                NativeBridge.sendErrorToFlutter(channel, "Failed to add geofence: ${e.message}")
            }
        } catch (e: SecurityException) {
            NativeBridge.sendErrorToFlutter(channel, "Geofence permission error: ${e.message}")
        }
    }

    private fun getGeofencePendingIntent(): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            UUID.randomUUID().hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    fun removeGeofence(geofenceId: String) {
        try {
            geofencingClient.removeGeofences(listOf(geofenceId)).addOnSuccessListener {
                val event = mapOf(
                    "type" to "geofence_removed",
                    "geofenceId" to geofenceId,
                    "timestamp" to System.currentTimeMillis()
                )
                NativeBridge.sendGeofenceEventToFlutter(channel, event)
            }.addOnFailureListener { e ->
                NativeBridge.sendErrorToFlutter(channel, "Failed to remove geofence: ${e.message}")
            }
        } catch (e: SecurityException) {
            NativeBridge.sendErrorToFlutter(channel, "Geofence permission error: ${e.message}")
        }
    }
}