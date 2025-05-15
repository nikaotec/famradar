package avs.com.famradar

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object LocationPermissionHelper {
    const val LOCATION_PERMISSION_REQUEST_CODE = 1001
    const val BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE = 1002
    const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1003

    fun hasForegroundLocationPermissions(context: Context): Boolean {
        return listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ).all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun hasBackgroundLocationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun hasNotificationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun hasAllLocationPermissions(context: Context): Boolean {
        return hasForegroundLocationPermissions(context) &&
                hasBackgroundLocationPermission(context) &&
                hasNotificationPermission(context)
    }

    fun shouldShowPermissionRationale(activity: Activity): Boolean {
        return ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) || ActivityCompat.shouldShowRequestPermissionRationale(
            activity,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
    }

    fun requestForegroundLocationPermissions(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            LOCATION_PERMISSION_REQUEST_CODE
        )
    }

    fun requestBackgroundLocationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            AlertDialog.Builder(activity)
                .setTitle("Permissão em segundo plano necessária")
                .setMessage("Para monitorar localização mesmo com o app em segundo plano, conceda a permissão nas configurações.")
                .setPositiveButton("Abrir Configurações") { _, _ ->
                    openAppSettings(activity)
                }
                .setNegativeButton("Cancelar") { _, _ ->
                    Toast.makeText(activity, "Permissão de segundo plano não concedida", Toast.LENGTH_LONG).show()
                }
                .show()
        } else {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                BACKGROUND_LOCATION_PERMISSION_REQUEST_CODE
            )
        }
    }

    fun requestNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST_CODE
            )
        }
    }

    fun showPermissionRationaleDialog(activity: Activity, onConfirm: () -> Unit) {
        AlertDialog.Builder(activity)
            .setTitle("Permissão Necessária")
            .setMessage("Para fornecer monitoramento contínuo, precisamos acessar sua localização.")
            .setPositiveButton("Entendi") { _, _ ->
                onConfirm()
            }
            .setNegativeButton("Recusar") { _, _ ->
                Toast.makeText(
                    activity,
                    "Monitoramento de localização desativado",
                    Toast.LENGTH_LONG
                ).show()
            }
            .setCancelable(false)
            .show()
    }

    fun showPermissionDeniedDialog(activity: Activity) {
        AlertDialog.Builder(activity)
            .setTitle("Permissão Negada")
            .setMessage("Você negou as permissões necessárias. Para ativar o monitoramento, por favor, conceda as permissões nas configurações.")
            .setPositiveButton("Abrir Configurações") { _, _ ->
                openAppSettings(activity)
            }
            .setNegativeButton("Cancelar") { _, _ ->
                Toast.makeText(
                    activity,
                    "Serviço de localização não ativado",
                    Toast.LENGTH_LONG
                ).show()
            }
            .show()
    }

    fun openAppSettings(activity: Activity) {
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", activity.packageName, null)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            activity.startActivity(this)
        }
    }
}