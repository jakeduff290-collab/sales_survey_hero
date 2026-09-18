import os, re

target = 'android/app/build.gradle'
is_kts = False
if os.path.exists(target + '.kts'):
    target += '.kts'
    is_kts = True

with open(target, 'r') as f:
    content = f.read()

# Strip any broken previous attempts to prevent duplicates
content = re.sub(r'\n\s*implementation.*androidx\.camera.*', '', content)

# The exact dependency strings
if is_kts:
    deps = '\n    implementation("androidx.camera:camera-core:1.3.0")\n    implementation("androidx.camera:camera-camera2:1.3.0")\n    implementation("androidx.camera:camera-lifecycle:1.3.0")\n    implementation("androidx.camera:camera-view:1.3.0")\n'
else:
    deps = '\n    implementation "androidx.camera:camera-core:1.3.0"\n    implementation "androidx.camera:camera-camera2:1.3.0"\n    implementation "androidx.camera:camera-lifecycle:1.3.0"\n    implementation "androidx.camera:camera-view:1.3.0"\n'

# Inject immediately after the dependencies block opens
content = re.sub(r'(dependencies\s*\{)', r'\1' + deps, content, count=1)

with open(target, 'w') as f:
    f.write(content)

print(f"✅ CameraX successfully hard-linked into {target}")
