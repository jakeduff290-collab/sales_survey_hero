import os

groovy_file = 'android/app/build.gradle'
kts_file = 'android/app/build.gradle.kts'

if os.path.exists(kts_file):
    target = kts_file
    is_kts = True
elif os.path.exists(groovy_file):
    target = groovy_file
    is_kts = False
else:
    print("Error: Build file not found. Ensure you are in the project root.")
    exit(1)

with open(target, 'r') as f:
    lines = f.readlines()

# Clean out any partial/broken camera dependencies
clean_lines = [l for l in lines if 'androidx.camera' not in l and 'lifecycle-runtime-ktx' not in l]

with open(target, 'w') as f:
    added = False
    for line in clean_lines:
        f.write(line)
        if 'dependencies {' in line and not added:
            if is_kts:
                f.write('    implementation("androidx.camera:camera-core:1.3.0")\n')
                f.write('    implementation("androidx.camera:camera-camera2:1.3.0")\n')
                f.write('    implementation("androidx.camera:camera-lifecycle:1.3.0")\n')
                f.write('    implementation("androidx.camera:camera-view:1.3.0")\n')
                f.write('    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")\n')
            else:
                f.write('    implementation "androidx.camera:camera-core:1.3.0"\n')
                f.write('    implementation "androidx.camera:camera-camera2:1.3.0"\n')
                f.write('    implementation "androidx.camera:camera-lifecycle:1.3.0"\n')
                f.write('    implementation "androidx.camera:camera-view:1.3.0"\n')
                f.write('    implementation "androidx.lifecycle:lifecycle-runtime-ktx:2.6.2"\n')
            added = True

print(f"Dependencies successfully injected into: {target}")
