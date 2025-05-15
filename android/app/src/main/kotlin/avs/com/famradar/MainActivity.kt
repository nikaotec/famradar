// android/app/src/main/kotlin/avs/com/famradar/MainActivity.kt
package avs.com.famradar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.webrtc.PeerConnection

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize NativeBridge for storage and permissions channels
        val nativeBridge = NativeBridge()
        nativeBridge.onAttachedToEngine(applicationContext, this, flutterEngine)

        // Invitations channel
        val invitationManager = InvitationManager(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/invitations").setMethodCallHandler { call, result ->
            when (call.method) {
                "sendInvitation" -> {
                    val fromUserId = call.argument<String>("fromUserId")
                    val toEmail = call.argument<String>("toEmail")
                    val familyId = call.argument<String>("familyId")
                    if (fromUserId != null && toEmail != null && familyId != null) {
                        invitationManager.sendInvitation(fromUserId, toEmail, familyId, result)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                "acceptInvitation" -> {
                    val invitationId = call.argument<String>("invitationId")
                    val userId = call.argument<String>("userId")
                    val familyId = call.argument<String>("familyId")
                    if (invitationId != null && userId != null && familyId != null) {
                        invitationManager.acceptInvitation(invitationId, userId, familyId, result)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                "rejectInvitation" -> {
                    val invitationId = call.argument<String>("invitationId")
                    val userId = call.argument<String>("userId")
                    if (invitationId != null && userId != null) {
                        invitationManager.rejectInvitation(invitationId, userId, result)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // WebRTC channel
        val webRTCManager = WebRTCManager(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/webrtc_events").setMethodCallHandler { call, result ->
            when (call.method) {
                "createPeerConnection" -> {
                    val iceServers = call.argument<List<Map<String, Any>>>("iceServers")?.map { server ->
                        PeerConnection.IceServer.builder(server["urls"] as List<String>)
                            .setUsername(server["username"] as? String)
                            .setPassword(server["credential"] as? String)
                            .createIceServer()
                    } ?: emptyList()
                    webRTCManager.createPeerConnection(iceServers)
                    result.success(null)
                }
                "addIceCandidate" -> {
                    val userId = call.argument<String>("userId")
                    val sdpMid = call.argument<String>("sdpMid")
                    val sdpMLineIndex = call.argument<Int>("sdpMLineIndex")
                    val sdp = call.argument<String>("sdp")
                    if (userId != null && sdpMid != null && sdpMLineIndex != null && sdp != null) {
                        webRTCManager.addIceCandidate(userId, sdpMid, sdpMLineIndex, sdp)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                "createOffer" -> {
                    val userId = call.argument<String>("userId")
                    if (userId != null) {
                        webRTCManager.setUserId(userId)
                        webRTCManager.createOffer(userId, result)
                    } else {
                        result.error("INVALID_ARGS", "Missing userId", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Geofence channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/geofence_events").setMethodCallHandler { _, _ ->
            // Handled by GeofenceBroadcastReceiver
        }

        // Initialize channels for services
        GeofenceBroadcastReceiver.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/geofence_events")
        LocationForegroundService.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/geofence_events")
        WebRTCManager.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/webrtc_events")
        InvitationManager.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avs.com.famradar/invitations")
    }
}