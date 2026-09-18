# 1. Update FloatingCameraService to send the broadcast when the paste button is tapped
cam_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(cam_path, 'r') as f:
    cam_code = f.read()

# Restore the explicit broadcast click listener
old_click = 'setOnClickListener { Toast.makeText(applicationContext, "📋 Ready! Tap a text box to auto-fill.", Toast.LENGTH_SHORT).show() }'
new_click = 'setOnClickListener { sendBroadcast(Intent("com.survey_hero.EXECUTE_AUTO_FILL")) }'
cam_code = cam_code.replace(old_click, new_click)

with open(cam_path, 'w') as f:
    f.write(cam_code)

# 2. Update AutoFillAccessibilityService to listen for that broadcast and inject fields sequentially
acc_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/AutoFillAccessibilityService.kt'
with open(acc_path, 'w') as f:
    f.write('''package com.example.sales_survey_hero

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class AutoFillAccessibilityService : AccessibilityService() {
    private val pasteReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = clipboard.primaryClip
            
            if (clip == null || clip.itemCount == 0) {
                Toast.makeText(context, "⚠️ Clipboard is empty. Scan a bill first.", Toast.LENGTH_SHORT).show()
                return
            }
            
            val rawData = clip.getItemAt(0).text?.toString() ?: ""
            val fields = rawData.split("||").map { it.trim() }
            
            if (fields.isEmpty() || fields[0].isEmpty()) {
                Toast.makeText(context, "⚠️ No structured data to paste", Toast.LENGTH_SHORT).show()
                return
            }

            val rootNode = rootInActiveWindow
            if (rootNode == null) {
                Toast.makeText(context, "⚠️ Window content not accessible", Toast.LENGTH_SHORT).show()
                return
            }

            val editableNodes = mutableListOf<AccessibilityNodeInfo>()
            findEditableNodes(rootNode, editableNodes)

            if (editableNodes.isEmpty()) {
                Toast.makeText(context, "⚠️ No text boxes found on screen", Toast.LENGTH_SHORT).show()
                return
            }

            var pastedCount = 0
            for ((index, value) in fields.withIndex()) {
                if (index < editableNodes.size && value.isNotEmpty()) {
                    val node = editableNodes[index]
                    val arguments = Bundle().apply { 
                        putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, value) 
                    }
                    node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
                    pastedCount++
                }
            }
            
            Toast.makeText(context, "⚡ Auto-Filled $pastedCount fields!", Toast.LENGTH_SHORT).show()
        }
    }

    private fun findEditableNodes(node: AccessibilityNodeInfo, list: MutableList<AccessibilityNodeInfo>) {
        if (node.isEditable || node.className?.toString()?.contains("EditText") == true) { 
            list.add(node) 
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { findEditableNodes(it, list) }
        }
    }

    override fun onServiceConnected() {
        registerReceiver(pasteReceiver, IntentFilter("com.survey_hero.EXECUTE_AUTO_FILL"), Context.RECEIVER_EXPORTED)
        Toast.makeText(this, "✅ Survey Hero Auto-Ready", Toast.LENGTH_SHORT).show()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
''')

print("V28 broadcast-paste restored!")
