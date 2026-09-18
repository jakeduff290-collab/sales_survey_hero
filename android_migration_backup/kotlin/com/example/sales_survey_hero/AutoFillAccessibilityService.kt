package com.example.sales_survey_hero

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class AutoFillAccessibilityService : AccessibilityService() {
    private var extractedData: List<String> = emptyList()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.survey_hero.EXECUTE_AUTO_FILL") {
                val rawData = intent.getStringExtra("survey_data") ?: return
                // Split the Gemini output by our double pipes
                extractedData = rawData.split("||").map { it.trim() }
                
                Toast.makeText(applicationContext, "Injecting Data...", Toast.LENGTH_SHORT).show()
                fillFields()
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val filter = IntentFilter("com.survey_hero.EXECUTE_AUTO_FILL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We only trigger when the broadcast is received, so we leave this blank
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(receiver)
        } catch (e: Exception) {}
    }

    private fun fillFields() {
        val rootNode = rootInActiveWindow ?: return
        val editableNodes = mutableListOf<AccessibilityNodeInfo>()
        
        // Scan the CRM screen for blank text boxes
        findEditableNodes(rootNode, editableNodes)

        // Sequentially drop the Gemini data into the fields
        for (i in 0 until minOf(extractedData.size, editableNodes.size)) {
            val node = editableNodes[i]
            val arguments = Bundle()
            arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, extractedData[i])
            node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
        }
    }

    private fun findEditableNodes(node: AccessibilityNodeInfo, editableNodes: MutableList<AccessibilityNodeInfo>) {
        if (node.isEditable || node.className == "android.widget.EditText") {
            editableNodes.add(node)
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { findEditableNodes(it, editableNodes) }
        }
    }
}
