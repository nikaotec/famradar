// android/app/src/main/kotlin/avs/com/famradar/BootReceiver.kt
package avs.com.famradar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted, starting LocationForegroundService")
            val serviceIntent = Intent(context, LocationForegroundService::class.java)
            context.startService(serviceIntent) // Line 13
        }
    }
}