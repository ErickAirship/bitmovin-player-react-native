package com.bitmovin.player.reactnative.ui

import android.app.Activity
import android.app.PictureInPictureParams
import android.os.Build
import android.util.Log
import android.util.Rational
import androidx.annotation.RequiresApi
import com.bitmovin.player.api.Player
import com.bitmovin.player.ui.DefaultPictureInPictureHandler

private const val TAG = "RNPiPHandler"

class RNPictureInPictureHandler(
    private val activity: Activity,
    private val player: Player,
) : DefaultPictureInPictureHandler(activity, player) {
    // Current PiP implementation on the native side requires playerView.exitPictureInPicture() to be called
    // for `PictureInPictureExit` event to be emitted.
    // Additionally, the event is only emitted if `isPictureInPicture` is true. At the point in time we call
    // playerView.exitPictureInPicture() the activity will already have exited the PiP mode,
    // and thus the event won't be emitted. To work around this we keep track of the PiP state ourselves.
    private var _isPictureInPicture = false

    override val isPictureInPicture: Boolean
        get() = _isPictureInPicture

    @RequiresApi(Build.VERSION_CODES.O)
    override fun enterPictureInPicture() {
        if (!isPictureInPictureAvailable) {
            Log.w(TAG, "Calling enterPictureInPicture without PiP support.")
            return
        }

        if (isPictureInPicture) {
            return
        }

        // The default implementation doesn't properly handle the case where source isn't loaded yet.
        // To work around it we just use a 16:9 aspect ratio if we cannot calculate it from `playbackVideoData`.
        val aspectRatio =
            player.playbackVideoData
                ?.let { Rational(it.width, it.height) }
                ?: Rational(16, 9)

        val params =
            PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)
                .build()

        activity.enterPictureInPictureMode(params)
        _isPictureInPicture = true
    }

    override fun exitPictureInPicture() {
        super.exitPictureInPicture()
        _isPictureInPicture = false
    }
}
package com.bitmovin.player.reactnative.ui

import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Icon
import android.media.session.MediaSession
import android.net.Uri
import android.os.Build
import android.util.Log
import android.util.Rational
import androidx.annotation.RequiresApi
import com.bitmovin.player.api.Player
import com.bitmovin.player.ui.DefaultPictureInPictureHandler

private const val TAG = "RNPiPHandler"
private const val CONTROL_TYPE_PLAY = 1
private const val CONTROL_TYPE_PAUSE = 2
private const val ACTION_MEDIA_CONTROL = "com.bitmovin.player.reactnative.ui.ACTION_MEDIA_CONTROL"
private const val EXTRA_CONTROL_TYPE = "control_type"

class RNPictureInPictureHandler(
    private val activity: Activity,
    private val player: Player,
) : DefaultPictureInPictureHandler(activity, player) {
    // Current PiP implementation on the native side requires playerView.exitPictureInPicture() to be called
    // for `PictureInPictureExit` event to be emitted.
    // Additionally, the event is only emitted if `isPictureInPicture` is true. At the point in time we call
    // playerView.exitPictureInPicture() the activity will already have exited the PiP mode,
    // and thus the event won't be emitted. To work around this we keep track of the PiP state ourselves.
    private var _isPictureInPicture = false

    override val isPictureInPicture: Boolean
        get() = _isPictureInPicture

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "Received media control intent")
            val controlType = intent.getIntExtra(EXTRA_CONTROL_TYPE, -1)
            when (controlType) {
                CONTROL_TYPE_PLAY -> player.play()
                CONTROL_TYPE_PAUSE -> player.pause()
                else -> Log.w(TAG, "Unknown control type: $controlType")
            }
            updatePictureInPictureActions()
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updatePictureInPictureActions() {
        if (isPictureInPicture) {
            val aspectRatio =
                player.playbackVideoData
                    ?.let { Rational(it.width, it.height) }
                    ?: Rational(16, 9)

            val params =
                PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio)
                    .setActions(createRemoteActions())
                    .build()

            activity.setPictureInPictureParams(params)
            Log.d(TAG, "Updated Picture-in-Picture actions")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun enterPictureInPicture() {
        if (!isPictureInPictureAvailable) {
            Log.w(TAG, "Calling enterPictureInPicture without PiP support.")
            return
        }

        if (isPictureInPicture) {
            return
        }

        // The default implementation doesn't properly handle the case where source isn't loaded yet.
        // To work around it we just use a 16:9 aspect ratio if we cannot calculate it from `playbackVideoData`.
        val aspectRatio =
            player.playbackVideoData
                ?.let { Rational(it.width, it.height) }
                ?: Rational(16, 9)

        val params =
            PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)
                .setActions(createRemoteActions())
                .build()

        activity.enterPictureInPictureMode(params)
        _isPictureInPicture = true

        val filter = IntentFilter(ACTION_MEDIA_CONTROL)
        activity.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
        Log.d(TAG, "Entered Picture-in-Picture mode and registered receiver")
        updatePictureInPictureActions()
    }

    override fun exitPictureInPicture() {
        super.exitPictureInPicture()
        _isPictureInPicture = false
        try {
            activity.unregisterReceiver(receiver)
            Log.d(TAG, "Exited Picture-in-Picture mode")
        } catch (e: IllegalArgumentException) {
            // Receiver was not registered, ignore
            Log.w(TAG, "Failed to unregister receiver: ${e.message}")
        }
    }

    private fun createRemoteActions(): List<RemoteAction> {
        Log.d(TAG, "Creating remote actions for PiP")
        val actions = mutableListOf<RemoteAction>()

        if (player.isPlaying) {
            val pauseIntent = PendingIntent.getBroadcast(
                activity.applicationContext,
                CONTROL_TYPE_PAUSE,
                Intent(ACTION_MEDIA_CONTROL).putExtra(EXTRA_CONTROL_TYPE, CONTROL_TYPE_PAUSE),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val pauseIcon = scaleIcon(android.R.drawable.ic_media_pause)
            actions.add(RemoteAction(pauseIcon, "Pause", "Pause", pauseIntent))
        } else {
            val playIntent = PendingIntent.getBroadcast(
                activity.applicationContext,
                CONTROL_TYPE_PLAY,
                Intent(ACTION_MEDIA_CONTROL).putExtra(EXTRA_CONTROL_TYPE, CONTROL_TYPE_PLAY),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val playIcon = scaleIcon(android.R.drawable.ic_media_play)
            actions.add(RemoteAction(playIcon, "Play", "Play", playIntent))
        }

        return actions
    }

    private fun scaleIcon(resourceId: Int): Icon {
        val drawable = activity.getDrawable(resourceId)
        val bitmap = Bitmap.createBitmap(
            drawable!!.intrinsicWidth * 3,
            drawable.intrinsicHeight * 3,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return Icon.createWithBitmap(bitmap)
    }
}
