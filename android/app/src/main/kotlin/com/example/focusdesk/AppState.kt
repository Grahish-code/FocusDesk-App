package com.example.focusdesk

// This Object acts as a global singleton that both your Activity
// and your Service can access.
object AppState {
    // True = User is looking at the app
    // False = App is minimized, closed, or screen is off
    var isAppInForeground: Boolean = false
}