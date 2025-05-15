// android/app/src/main/kotlin/avs/com/famradar/WebRTCManager.kt
package avs.com.famradar

import android.content.Context
import io.flutter.plugin.common.MethodChannel
import org.webrtc.*

class WebRTCManager(context: Context) {
    companion object {
        private const val CHANNEL = "avs.com.famradar/webrtc_events"
        lateinit var channel: MethodChannel
    }

    private val peerConnectionFactory: PeerConnectionFactory
    private var peerConnection: PeerConnection? = null
    private var currentUserId: String? = null // Store user ID dynamically

    init {
        // Initialize WebRTC
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .createInitializationOptions()
        )
        peerConnectionFactory = PeerConnectionFactory.builder().createPeerConnectionFactory()
    }

    fun setUserId(userId: String) {
        currentUserId = userId
    }

    fun createPeerConnection(iceServers: List<PeerConnection.IceServer>) {
        val rtcConfig = PeerConnection.RTCConfiguration(iceServers)
        peerConnection = peerConnectionFactory.createPeerConnection(rtcConfig, object : PeerConnection.Observer {
            override fun onIceCandidate(candidate: IceCandidate) {
                val candidateData = mapOf(
                    "userId" to (currentUserId ?: "unknown_user"),
                    "sdpMid" to candidate.sdpMid,
                    "sdpMLineIndex" to candidate.sdpMLineIndex,
                    "sdp" to candidate.sdp
                )
                NativeBridge.sendIceCandidateToFlutter(channel, candidateData)
            }

            override fun onSignalingChange(state: PeerConnection.SignalingState) {
                // Log or handle signaling state changes if needed
            }

            override fun onIceConnectionChange(state: PeerConnection.IceConnectionState) {
                // Notify Flutter of connection state changes if needed
            }

            override fun onIceConnectionReceivingChange(receiving: Boolean) {
                // Handle receiving state change
            }

            override fun onIceGatheringChange(state: PeerConnection.IceGatheringState) {
                // Notify Flutter if gathering state changes significantly
            }

            override fun onIceCandidateError(error: IceCandidateErrorEvent) {
                NativeBridge.sendErrorToFlutter(channel, "ICE candidate error: ${error.errorText}")
            }

            override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>?) {
                // Handle candidate removal if needed
            }

            override fun onAddStream(stream: MediaStream) {
                // Handle new media streams
            }

            override fun onRemoveStream(stream: MediaStream) {
                // Handle stream removal
            }

            override fun onDataChannel(channel: DataChannel) {
                // Handle data channel creation
            }

            override fun onRenegotiationNeeded() {
                // Trigger renegotiation if needed
            }

            override fun onAddTrack(receiver: RtpReceiver, streams: Array<out MediaStream>) {
                // Handle new tracks
            }
        })
    }

    fun addIceCandidate(userId: String, sdpMid: String, sdpMLineIndex: Int, sdp: String) {
        val candidate = IceCandidate(sdpMid, sdpMLineIndex, sdp)
        peerConnection?.addIceCandidate(candidate)
    }

    fun createOffer(userId: String, result: MethodChannel.Result) {
        peerConnection?.createOffer(object : SdpObserverAdapter() {
            override fun onCreateSuccess(sessionDescription: SessionDescription) {
                peerConnection?.setLocalDescription(object : SdpObserverAdapter() {
                    override fun onSetSuccess() {
                        val offer = mapOf(
                            "userId" to userId,
                            "sdp" to sessionDescription.description,
                            "type" to sessionDescription.type.canonicalForm()
                        )
                        NativeBridge.sendOfferToFlutter(channel, offer) // Use new method
                        result.success(offer)
                    }

                    override fun onSetFailure(error: String?) {
                        NativeBridge.sendErrorToFlutter(channel, "Failed to set local description: ${error ?: "Unknown error"}")
                        result.error("SET_LOCAL_DESC_FAILED", "Failed to set local description", error)
                    }
                }, sessionDescription)
            }

            override fun onCreateFailure(error: String?) {
                NativeBridge.sendErrorToFlutter(channel, "Failed to create offer: ${error ?: "Unknown error"}")
                result.error("CREATE_OFFER_FAILED", "Failed to create offer", error)
            }
        }, MediaConstraints())
    }

    fun sendLocationUpdate(latitude: Double, longitude: Double) {
        val locationData = mapOf(
            "latitude" to latitude,
            "longitude" to longitude,
            "timestamp" to System.currentTimeMillis()
        )
        NativeBridge.sendLocationToFlutter(channel, locationData)
    }
}