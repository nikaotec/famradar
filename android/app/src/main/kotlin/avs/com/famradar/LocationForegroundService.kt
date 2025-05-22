package avs.com.famradar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*

class LocationForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "FamRadarLocationChannel"
        private const val NOTIFICATION_ID = 1
        private const val TAG = "LocationService"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private var userId: String? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "LocationForegroundService created")
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        startLocationUpdates()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        userId = intent?.getStringExtra("userId") ?: "unknown"
        Log.d(TAG, "LocationForegroundService started for user: $userId")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FamRadar Location Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for location tracking in FamRadar"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("FamRadar Location Tracking")
            .setContentText("Tracking your location to keep your family safe.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startLocationUpdates() {
        val locationRequest = LocationRequest.create().apply {
            interval = 10000 // 10 segundos
            fastestInterval = 5000 // 5 segundos
            priority = Priority.PRIORITY_HIGH_ACCURACY
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                Log.d(TAG, "Location result received, locations: ${locationResult.locations.size}")
                for (location in locationResult.locations) {
                    val event = mapOf(
                        "userId" to userId,
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "timestamp" to (System.currentTimeMillis() / 1000).toInt()
                    )
                    Log.d(TAG, "Sending location update: $event, eventSink: ${MainActivity.locationEventSink != null}")
                    MainActivity.locationEventSink?.success(event) ?: Log.w(TAG, "EventSink is null, event not sent")
                }
            }
        }

        try {
            if (LocationPermissionHelper.hasForegroundLocationPermissions(this)) {
                Log.d(TAG, "Location permissions granted, requesting updates")
                fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, mainLooper)
            } else {
                Log.e(TAG, "Location permission missing")
                MainActivity.locationEventSink?.error("PERMISSION_DENIED", "Location permission missing", null)
                stopSelf()
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: ${e.message}")
            MainActivity.locationEventSink?.error("PERMISSION_DENIED", "Location permission missing: ${e.message}", null)
            stopSelf()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        Log.d(TAG, "LocationForegroundService destroyed")
    }
}