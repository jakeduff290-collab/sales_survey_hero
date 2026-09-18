cam_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/FloatingCameraService.kt'
with open(cam_path, 'r') as f:
    cam_code = f.read()

# 1. Add a variable to hold the text in memory instead of just the clipboard
cam_code = cam_code.replace(
    'private var extractionPrompt: String = ""', 
    'private var extractionPrompt: String = ""\n    private var lastExtractedText: String = ""'
)

# 2. Update the extract callback to save the AI output to our new variable
old_handler = 'extractWithGemini(rawText, extractionPrompt) { formattedText, usedFallback ->\n                                    Handler(Looper.getMainLooper()).post {\n                                        try {'
new_handler = 'extractWithGemini(rawText, extractionPrompt) { formattedText, usedFallback ->\n                                    Handler(Looper.getMainLooper()).post {\n                                        lastExtractedText = formattedText\n                                        try {'
cam_code = cam_code.replace(old_handler, new_handler)

# 3. Change the PASTE button to send the text directly inside the broadcast
old_paste = 'setOnClickListener { sendBroadcast(Intent("com.survey_hero.EXECUTE_AUTO_FILL")) }'
new_paste = '''setOnClickListener { 
                val intent = Intent("com.survey_hero.EXECUTE_AUTO_FILL")
                intent.putExtra("survey_data", lastExtractedText)
                sendBroadcast(intent) 
            }'''
cam_code = cam_code.replace(old_paste, new_paste)

with open(cam_path, 'w') as f:
    f.write(cam_code)

# 4. Update the Accessibility Service to read the text directly from the broadcast, ignoring the clipboard
acc_path = 'android/app/src/main/kotlin/com/example/sales_survey_hero/AutoFillAccessibilityService.kt'
with open(acc_path, 'w') as f:
    f.write('''package com.example.sales_survey_hero

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
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
            // Read data DIRECTLY from the floating button, bypassing Android Clipboard security
            val rawData = intent?.getStringExtra("survey_data") ?: ""
            
            if (rawData.isEmpty()) {
                Toast.makeText(context, "⚠️ No data found. Scan a bill first.", Toast.LENGTH_SHORT).show()
                return
            }
            
            val fields = rawData.split("||").map { it.trim() }
            
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

print("V29 Direct-Transfer applied!")
