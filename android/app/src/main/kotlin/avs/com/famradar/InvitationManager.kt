// android/app/src/main/kotlin/avs/com/famradar/InvitationManager.kt
package avs.com.famradar

import android.content.Context
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import io.flutter.plugin.common.MethodChannel

class InvitationManager(private val context: Context) {
    companion object {
        private const val CHANNEL = "avs.com.famradar/invitations"
        lateinit var channel: MethodChannel
    }

    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()

    fun sendInvitation(fromUserId: String, toEmail: String, familyId: String, result: MethodChannel.Result) {
        // First, find the user by email
        firestore.collection("users")
            .whereEqualTo("email", toEmail)
            .get()
            .addOnSuccessListener { querySnapshot ->
                if (querySnapshot.isEmpty) {
                    NativeBridge.sendErrorToFlutter(channel, "User with email $toEmail not found")
                    result.error("USER_NOT_FOUND", "User with email $toEmail not found", null)
                    return@addOnSuccessListener
                }

                val toUserId = querySnapshot.documents.first().id
                val invitation = mapOf(
                    "fromUserId" to fromUserId,
                    "toUserId" to toUserId,
                    "familyId" to familyId,
                    "status" to "pending",
                    "timestamp" to FieldValue.serverTimestamp()
                )

                firestore.collection("invitations")
                    .add(invitation)
                    .addOnSuccessListener {
                        val event = mapOf(
                            "type" to "invitation_sent",
                            "fromUserId" to fromUserId,
                            "toEmail" to toEmail,
                            "familyId" to familyId,
                            "timestamp" to System.currentTimeMillis()
                        )
                        NativeBridge.sendInvitationEventToFlutter(channel, event)
                        result.success(null)
                    }
                    .addOnFailureListener { e ->
                        NativeBridge.sendErrorToFlutter(channel, "Failed to send invitation: ${e.message}")
                        result.error("FIRESTORE_ERROR", "Failed to send invitation", e.message)
                    }
            }
            .addOnFailureListener { e ->
                NativeBridge.sendErrorToFlutter(channel, "Error finding user: ${e.message}")
                result.error("FIRESTORE_ERROR", "Error finding user", e.message)
            }
    }

    fun acceptInvitation(invitationId: String, userId: String, familyId: String, result: MethodChannel.Result) {
        val updates = mapOf(
            "status" to "accepted",
            "acceptedAt" to FieldValue.serverTimestamp()
        )

        firestore.collection("invitations")
            .document(invitationId)
            .update(updates)
            .addOnSuccessListener {
                // Add user to family
                firestore.collection("families")
                    .document(familyId)
                    .update("members", FieldValue.arrayUnion(userId))
                    .addOnSuccessListener {
                        val event = mapOf(
                            "type" to "invitation_accepted",
                            "invitationId" to invitationId,
                            "userId" to userId,
                            "familyId" to familyId,
                            "timestamp" to System.currentTimeMillis()
                        )
                        NativeBridge.sendInvitationEventToFlutter(channel, event)
                        result.success(null)
                    }
                    .addOnFailureListener { e ->
                        NativeBridge.sendErrorToFlutter(channel, "Failed to add user to family: ${e.message}")
                        result.error("FIRESTORE_ERROR", "Failed to add user to family", e.message)
                    }
            }
            .addOnFailureListener { e ->
                NativeBridge.sendErrorToFlutter(channel, "Failed to accept invitation: ${e.message}")
                result.error("FIRESTORE_ERROR", "Failed to accept invitation", e.message)
            }
    }

    fun rejectInvitation(invitationId: String, userId: String, result: MethodChannel.Result) {
        val updates = mapOf(
            "status" to "rejected",
            "rejectedAt" to FieldValue.serverTimestamp()
        )

        firestore.collection("invitations")
            .document(invitationId)
            .update(updates)
            .addOnSuccessListener {
                val event = mapOf(
                    "type" to "invitation_rejected",
                    "invitationId" to invitationId,
                    "userId" to userId,
                    "timestamp" to System.currentTimeMillis()
                )
                NativeBridge.sendInvitationEventToFlutter(channel, event)
                result.success(null)
            }
            .addOnFailureListener { e ->
                NativeBridge.sendErrorToFlutter(channel, "Failed to reject invitation: ${e.message}")
                result.error("FIRESTORE_ERROR", "Failed to reject invitation", e.message)
            }
    }
}