import os, re

path = 'android/app/build.gradle'
if os.path.exists(path + '.kts'): path += '.kts'

with open(path, 'r') as f:
    text = f.read()

# Erase any old, misplaced camera dependencies
text = re.sub(r'^\s*implementation.*androidx\.camera.*$\n', '', text, flags=re.MULTILINE)

deps = """
    implementation "androidx.camera:camera-core:1.3.0"
    implementation "androidx.camera:camera-camera2:1.3.0"
    implementation "androidx.camera:camera-lifecycle:1.3.0"
    implementation "androidx.camera:camera-view:1.3.0"
"""
if path.endswith('.kts'):
    deps = deps.replace('implementation ', 'implementation(').replace('"', '")')

# Inject into the LAST dependencies block (the actual app block)
parts = text.rsplit('dependencies {', 1)
new_text = parts[0] + 'dependencies {' + deps + parts[1]

with open(path, 'w') as f:
    f.write(new_text)

print("✅ Camera libraries locked into the correct App block!")
