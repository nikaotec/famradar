package avs.com.famradar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED || intent?.action == "android.intent.action.QUICKBOOT_POWERON") {
            if (LocationPermissionHelper.hasAllLocationPermissions(context)) {
                Log.d(TAG, "Permissões concedidas, iniciando LocationForegroundService")
                LocationForegroundService.startService(context)
            } else {
                Log.w(TAG, "Permissões de localização ausentes, serviço não iniciado")
            }
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}