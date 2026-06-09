package com.gymcompanion.gym_companion

import android.app.Activity
import android.os.Bundle

/**
 * Required for Health Connect permission rationale on Android 14+.
 */
class HealthConnectRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        finish()
    }
}
