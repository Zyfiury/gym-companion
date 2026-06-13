package com.gymcompanion.gym_companion

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Health Connect opens this activity for permission rationale on Android 14+.
 * Forward to MainActivity so the plugin's Activity Result API can complete the flow.
 */
class HealthConnectRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val forward = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            data = intent.data
            putExtras(intent)
        }
        startActivity(forward)
        finish()
    }
}
