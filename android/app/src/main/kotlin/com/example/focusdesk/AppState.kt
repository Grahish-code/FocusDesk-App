package com.example.focusdesk

// This Object acts as a global singleton that both your Activity
// and your Service can access.

/// in short it help our app to send notification only when the app is not being used by the user
object AppState {
    // True = User is looking at the app
    // False = App is minimized, closed, or screen is off
    var isAppInForeground: Boolean = false
}