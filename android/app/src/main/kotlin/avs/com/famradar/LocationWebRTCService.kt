package avs.com.famradar


import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.IBinder
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Esse é o serviço responsável por enviar/receber localização via WebRTC
class LocationWebRTCService<PeerConnection> : Service() {

    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

//    private lateinit var peerConnection: PeerConnection
//    private lateinit var dataChannel: DataChannel
//
//    override fun onCreate() {
//        super.onCreate()
//        // Aqui você configura o PeerConnection, STUN/TURN, etc.
//        setupWebRTC()
//    }

//    private fun setupWebRTC() {
//        // Iniciar WebRTC factory e conexão
//        // Isso deve ser implementado com ICE server e dataChannel
//        // Exemplo básico:
//        // peerConnection = ...
//        // dataChannel = peerConnection.createDataChannel("location", DataChannel.Init())
//
//        dataChannel.registerObserver(object : DataChannel.Observer {
//            override fun onMessage(buffer: DataChannel.Buffer?) {
//                val message = buffer?.let {
//                    val bytes = ByteArray(it.data.remaining())
//                    it.data.get(bytes)
//                    String(bytes)
//                }
//                // Quando uma localização chega do outro dispositivo
//                eventSink?.success(message)
//            }
//
//            override fun onStateChange() {}
//            override fun onBufferedAmountChange(p0: Long) {}
//        })
//    }
//
//    fun sendLocation(location: Location) {
//        val message = "${location.latitude},${location.longitude}"
//        val buffer = DataChannel.Buffer(
//            java.nio.ByteBuffer.wrap(message.toByteArray()),
//            false
//        )
//        dataChannel.send(buffer)
//    }

    override fun onBind(intent: Intent?): IBinder? = null
}