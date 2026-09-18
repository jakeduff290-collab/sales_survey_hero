import re

# Update FloatingCameraService to use prompt-based structured parsing with '||' delimiters
cam_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(cam_path, 'r') as f:
    cam_code = f.read()

structured_parser = """
    private fun parseWithPrompt(text: String): String {
        // Multi-field extraction matching user prompt templates (e.g., SoCalGas template)
        var name = ""
        var address = ""
        var account = ""
        
        try {
            val accRegex = Regex("Account Number\\\\s*([\\\\d\\\\s]+)", RegexOption.IGNORE_CASE)
            accRegex.find(text)?.let { account = it.groupValues[1].replace(" ", "").trim() }

            val serviceRegex = Regex("Service For\\\\s*\\\\n(.*?)\\\\n(.*?)\\\\n(.*)", RegexOption.IGNORE_CASE)
            serviceRegex.find(text)?.let { 
                name = it.groupValues[1].trim()
                address = (it.groupValues[2].trim() + ", " + it.groupValues[3].trim()).take(30)
            }
        } catch (e: Exception) {}

        // Fallback if structured tokens aren't found
        if (name.isEmpty() && account.isEmpty()) return text

        // Format fields separated by '||' for sequential accessibility box-filling
        return "$name || $address || $account"
    }
"""

cam_code = cam_code.replace("private fun toTitleCase", structured_parser + "\n    private fun toTitleCase")
cam_code = cam_code.replace('parseSoCalGas(toTitleCase(rawText))', 'parseWithPrompt(toTitleCase(rawText))')
cam_code = cam_code.replace('toTitleCase(rawText)', 'parseWithPrompt(toTitleCase(rawText))')

with open(cam_path, 'w') as f:
    f.write(cam_code)

# Update AutoFillAccessibilityService to handle sequential '||' injection across separate fields
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
            
            Toast.makeText(context, "⚡ Auto-Filled $pastedCount fields sequentially!", Toast.LENGTH_SHORT).show()
        }
    }

    private fun findEditableNodes(node: AccessibilityNodeInfo, list: MutableList<AccessibilityNodeInfo>) {
        if (node.isEditable) { 
            list.add(node) 
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { findEditableNodes(it, list) }
        }
    }

    override fun onServiceConnected() {
        registerReceiver(pasteReceiver, IntentFilter("com.survey_hero.EXECUTE_AUTO_FILL"), Context.RECEIVER_EXPORTED)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
''')

print("V25 Multi-field prompt pipeline applied successfully!")
