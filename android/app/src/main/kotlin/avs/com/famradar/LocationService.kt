package avs.com.famradar


import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat

class LocationService(
    private val context: Context,
    private val callback: (Double, Double) -> Unit
) : LocationListener {

    private var locationManager: LocationManager? = null
    private var isListening = false

    @SuppressLint("MissingPermission")
    fun start() {
        if (isListening) return

        try {
            if (!hasLocationPermission()) {
                throw SecurityException("Location permission not granted")
            }

            locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

            val isGpsEnabled = locationManager?.isProviderEnabled(LocationManager.GPS_PROVIDER) ?: false
            val isNetworkEnabled = locationManager?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ?: false

            if (!isGpsEnabled && !isNetworkEnabled) {
                throw IllegalStateException("No location provider is enabled")
            }

            if (isGpsEnabled) {
                locationManager?.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    5000L,
                    5f,
                    this,
                    Looper.getMainLooper()
                )
            }

            if (isNetworkEnabled) {
                locationManager?.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    5000L,
                    5f,
                    this,
                    Looper.getMainLooper()
                )
            }

            isListening = true
            Log.d(TAG, "Location updates started")

            // Get last known location
            val lastLocation = locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: locationManager?.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            lastLocation?.let {
                callback(it.latitude, it.longitude)
            }

        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: ${e.message}")
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location updates: ${e.message}")
            throw IllegalStateException("Failed to start location updates", e)
        }
    }


    fun stop() {
        try {
            locationManager?.removeUpdates(this)
            isListening = false
            Log.d(TAG, "Location updates stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location updates", e)
        }
    }

    override fun onLocationChanged(location: Location) {
        callback(location.latitude, location.longitude)
    }

    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        private const val TAG = "LocationService"
    }
}