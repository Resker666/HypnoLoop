package com.hypnoloop.app

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

class LauncherIconManager(context: Context) {
    private val manager = context.packageManager
    private val components = linkedMapOf(
        "a" to ComponentName(context, "com.hypnoloop.app.LauncherA"),
        "b" to ComponentName(context, "com.hypnoloop.app.LauncherB"),
        "c" to ComponentName(context, "com.hypnoloop.app.LauncherC"),
        "d" to ComponentName(context, "com.hypnoloop.app.LauncherD"),
    )

    private fun active(): List<String> = components.filter { (id, component) ->
        when (manager.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> id == "b"
            else -> false
        }
    }.keys.toList()

    fun current(): String {
        val enabled = active()
        if (enabled.size == 1) return enabled.single()
        // Recover a missing or ambiguous launcher selection to the default.
        apply("b")
        check(active() == listOf("b")) { "Unable to recover launcher icon" }
        return "b"
    }

    fun select(id: String): String {
        require(components.containsKey(id)) { "Unknown launcher icon" }
        val previous = current()
        if (previous == id) return id
        try {
            apply(id)
            check(active() == listOf(id)) { "Launcher icon selection did not apply" }
        } catch (failure: Exception) {
            // If the older sequential API fails halfway, restore a launchable entry.
            try {
                apply(previous)
            } catch (rollback: Exception) {
                failure.addSuppressed(rollback)
            }
            throw failure
        }
        return id
    }

    private fun apply(id: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.setComponentEnabledSettings(components.map { (candidate, component) ->
                PackageManager.ComponentEnabledSetting(
                    component,
                    if (candidate == id) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                    else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            })
        } else {
            // Enable first: there must always be an entry that can launch the app.
            manager.setComponentEnabledSetting(
                components.getValue(id), PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
            components.filterKeys { it != id }.values.forEach { component ->
                manager.setComponentEnabledSetting(
                    component, PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
        }
        // MainActivity is deliberately never disabled: every alias targets it.
    }
}
