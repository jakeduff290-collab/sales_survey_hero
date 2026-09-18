import os

path = 'android/app/build.gradle'
with open(path, 'r') as f:
    lines = f.readlines()

# Clean out any stray camera dependencies from previous attempts
clean_lines = [l for l in lines if 'androidx.camera' not in l and 'androidx.lifecycle:lifecycle-runtime-ktx' not in l]

# Rewrite the file, injecting dependencies perfectly into the block
with open(path, 'w') as f:
    added = False
    for line in clean_lines:
        f.write(line)
        if 'dependencies {' in line and not added:
            f.write('    implementation "androidx.camera:camera-core:1.3.0"\n')
            f.write('    implementation "androidx.camera:camera-camera2:1.3.0"\n')
            f.write('    implementation "androidx.camera:camera-lifecycle:1.3.0"\n')
            f.write('    implementation "androidx.camera:camera-view:1.3.0"\n')
            f.write('    implementation "androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"\n')
            added = True

print("Dependencies injected flawlessly!")
