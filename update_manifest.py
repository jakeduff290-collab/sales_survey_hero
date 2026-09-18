import os

manifest_path = 'android/app/src/main/AndroidManifest.xml'
with open(manifest_path, 'r') as f:
    content = f.read()

service_block = """
        <service
            android:name=".AutoFillAccessibilityService"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
            android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>
"""

if "AutoFillAccessibilityService" not in content:
    content = content.replace('</application>', service_block + '</application>')
    with open(manifest_path, 'w') as f:
        f.write(content)
    print("Manifest successfully updated with Accessibility Service!")
else:
    print("Service already exists in manifest.")
