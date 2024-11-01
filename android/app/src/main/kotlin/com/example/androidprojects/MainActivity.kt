package com.example.androidprojects

import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    // add the following block of code
    override fun onPostResume() {
        super.onPostResume()
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.navigationBarColor = 0 // for transparent nav bar
        window.statusBarColor = 0 // for transparent status bar
    }
}
