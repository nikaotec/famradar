package avs.com.famradar

import android.util.Log
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription

public open class SdpObserverAdapter : SdpObserver {
    override fun onCreateSuccess(desc: SessionDescription) {
        Log.d("SdpObserver", "onCreateSuccess: ${desc.type}")

    }

    override fun onSetSuccess() {
        Log.d("SdpObserver", "onSetSuccess")
    }

    override fun onCreateFailure(error: String?) {
        Log.e("SdpObserver", "onCreateFailure: $error")
    }

    override fun onSetFailure(error: String?) {
        Log.e("SdpObserver", "onSetFailure: $error")
    }
}