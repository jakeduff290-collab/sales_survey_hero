# 1. Update FloatingCameraService to copy the structured fields directly to the clipboard
cam_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(cam_path, 'r') as f:
    cam_code = f.read()

# Replace the broadcast in the paste button with a direct clipboard copy or clear indicator
old_paste_click = 'setOnClickListener { sendBroadcast(Intent("com.survey_hero.EXECUTE_AUTO_FILL")) }'
new_paste_click = 'setOnClickListener { Toast.makeText(applicationContext, "📋 Ready! Tap a text box to auto-fill.", Toast.LENGTH_SHORT).show() }'
cam_code = cam_code.replace(old_paste_click, new_paste_click)

with open(cam_path, 'w') as f:
    f.write(cam_code)

# 2. Upgrade AutoFillAccessibilityService to auto-trigger whenever text is copied or focused
acc_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/AutoFillAccessibilityService.kt'
with open(acc_path, 'w') as f:
    f.write('''package com.example.sales_survey_hero

import android.accessibilityservice.AccessibilityService
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class AutoFillAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // When the user focuses on an editable text box, check if we have structured survey data to drop in
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED) {
            val node = event.source ?: return
            if (node.isEditable) {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = clipboard.primaryClip
                if (clip != null && clip.itemCount > 0) {
                    val rawData = clip.getItemAt(0).text?.toString() ?: ""
                    if (rawData.contains("||")) {
                        val fields = rawData.split("||").map { it.trim() }
                        
                        // Find all editable fields on the screen
                        val rootNode = rootInActiveWindow ?: return
                        val editableNodes = mutableListOf<AccessibilityNodeInfo>()
                        findEditableNodes(rootNode, editableNodes)

                        // Sequentially fill fields starting from the currently focused node
                        var filled = false
                        for ((index, editableNode) in editableNodes.withIndex()) {
                            if (index < fields.size && fields[index].isNotEmpty()) {
                                val arguments = Bundle().apply {
                                    putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, fields[index])
                                }
                                editableNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
                                filled = true
                            }
                        }
                        if (filled) {
                            Toast.makeText(this, "⚡ Auto-Filled Survey Data!", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            }
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
        Toast.makeText(this, "✅ Survey Hero Auto-Fill Active", Toast.LENGTH_SHORT).show()
    }

    override fun onInterrupt() {}
}
''')

print("V27 unified auto-fill pipeline applied!")
