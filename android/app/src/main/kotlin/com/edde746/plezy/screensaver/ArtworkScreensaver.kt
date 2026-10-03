package com.edde746.plezy.screensaver

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.service.dreams.DreamService
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Artwork the app hands the screensaver: backdrop URLs (already sized and
 * authorised by the server client) with their titles, kept in preferences so
 * the dream can run while the app process is idle.
 */
object ScreensaverArtworkStore {
  private const val PREFS = "plezzant_screensaver"
  private const val KEY_ITEMS = "items"
  const val CHANNEL = "com.plezy/screensaver"

  fun register(messenger: BinaryMessenger, context: Context) {
    val appContext = context.applicationContext
    MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "setArtwork" -> {
          val items = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
          val json = JSONArray()
          for (item in items) {
            val url = item["url"] as? String ?: continue
            json.put(JSONObject().put("url", url).put("title", item["title"] as? String ?: "").put("subtitle", item["subtitle"] as? String ?: ""))
          }
          appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY_ITEMS, json.toString()).apply()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }

  data class Item(val url: String, val title: String, val subtitle: String)

  fun read(context: Context): List<Item> {
    val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_ITEMS, null) ?: return emptyList()
    return try {
      val array = JSONArray(raw)
      (0 until array.length()).mapNotNull { i ->
        val obj = array.optJSONObject(i) ?: return@mapNotNull null
        val url = obj.optString("url")
        if (url.isNullOrEmpty()) null else Item(url, obj.optString("title"), obj.optString("subtitle"))
      }
    } catch (_: Exception) {
      emptyList()
    }
  }
}

/**
 * Android TV screensaver: library backdrops cross-fading with a slow drift,
 * the title in the lower-left safe area, like the official apps' art mode.
 */
class ArtworkScreensaver : DreamService() {
  private val handler = Handler(Looper.getMainLooper())
  private val loader = Executors.newSingleThreadExecutor()
  private lateinit var front: ImageView
  private lateinit var back: ImageView
  private lateinit var title: TextView
  private lateinit var subtitle: TextView
  private var items: List<ScreensaverArtworkStore.Item> = emptyList()
  private var index = 0
  private var running = false

  private val advance = object : Runnable {
    override fun run() {
      if (!running) return
      showNext()
      handler.postDelayed(this, SLIDE_MILLIS)
    }
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    isInteractive = false
    isFullscreen = true
    isScreenBright = false

    val root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
    back = artworkView()
    front = artworkView()
    root.addView(back)
    root.addView(front)
    // Bottom scrim so the caption stays legible over bright artwork.
    root.addView(
      View(this).apply {
        background = GradientDrawable(GradientDrawable.Orientation.BOTTOM_TOP, intArrayOf(0xB3000000.toInt(), 0x00000000))
      },
      FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, dp(220), Gravity.BOTTOM)
    )
    val caption = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    title = TextView(this).apply {
      setTextColor(Color.WHITE)
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
      paint.isFakeBoldText = true
    }
    subtitle = TextView(this).apply {
      setTextColor(0xB3FFFFFF.toInt())
      setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
    }
    caption.addView(title)
    caption.addView(subtitle)
    // tvOS-style safe frame: 80 x 60 on a 1920x1080 canvas = 40 x 30 dp.
    root.addView(
      caption,
      FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM or Gravity.START).apply {
        marginStart = dp(40)
        bottomMargin = dp(30)
      }
    )
    setContentView(root)
  }

  override fun onDreamingStarted() {
    super.onDreamingStarted()
    items = ScreensaverArtworkStore.read(this).shuffled()
    running = true
    if (items.isEmpty()) {
      title.text = "Plezzant"
      return
    }
    handler.post(advance)
  }

  override fun onDreamingStopped() {
    running = false
    handler.removeCallbacksAndMessages(null)
    super.onDreamingStopped()
  }

  override fun onDetachedFromWindow() {
    running = false
    handler.removeCallbacksAndMessages(null)
    loader.shutdownNow()
    super.onDetachedFromWindow()
  }

  private fun showNext() {
    val item = items[index % items.size]
    index++
    val width = resources.displayMetrics.widthPixels
    loader.execute {
      val bitmap = fetch(item.url, width)
      handler.post {
        if (!running || bitmap == null) return@post
        crossfadeTo(bitmap, item)
      }
    }
  }

  private fun crossfadeTo(bitmap: Bitmap, item: ScreensaverArtworkStore.Item) {
    back.setImageBitmap(bitmap)
    back.alpha = 0f
    back.scaleX = 1f
    back.scaleY = 1f
    back.animate().alpha(1f).setDuration(FADE_MILLIS).setListener(null).start()
    // Slow drift while the slide is up.
    back.animate().scaleX(1.06f).scaleY(1.06f).setDuration(SLIDE_MILLIS + FADE_MILLIS).start()
    front.animate().alpha(0f).setDuration(FADE_MILLIS).setListener(object : AnimatorListenerAdapter() {
      override fun onAnimationEnd(animation: Animator) {
        val swap = front
        front = back
        back = swap
        front.bringToFront()
      }
    }).start()
    title.text = item.title
    subtitle.text = item.subtitle
    title.bringToFront()
  }

  private fun artworkView() = ImageView(this).apply {
    scaleType = ImageView.ScaleType.CENTER_CROP
    layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
  }

  private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

  private fun fetch(url: String, targetWidth: Int): Bitmap? = try {
    val connection = URL(url).openConnection() as HttpURLConnection
    connection.connectTimeout = 8000
    connection.readTimeout = 15000
    val bytes = connection.inputStream.use { it.readBytes() }
    connection.disconnect()
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
    var sample = 1
    while (bounds.outWidth / (sample * 2) >= targetWidth) sample *= 2
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
  } catch (_: Exception) {
    null
  }

  companion object {
    private const val SLIDE_MILLIS = 12_000L
    private const val FADE_MILLIS = 1_500L
  }
}
