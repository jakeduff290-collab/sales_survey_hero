import os

path = 'android/app/build.gradle'
is_kts = False
if os.path.exists(path + '.kts'):
    path += '.kts'
    is_kts = True

with open(path, 'a') as f:
    f.write('\n\n// Native CameraX Overrides\n')
    f.write('dependencies {\n')
    if is_kts:
        f.write('    implementation("androidx.camera:camera-core:1.3.0")\n')
        f.write('    implementation("androidx.camera:camera-camera2:1.3.0")\n')
        f.write('    implementation("androidx.camera:camera-lifecycle:1.3.0")\n')
        f.write('    implementation("androidx.camera:camera-view:1.3.0")\n')
    else:
        f.write('    implementation "androidx.camera:camera-core:1.3.0"\n')
        f.write('    implementation "androidx.camera:camera-camera2:1.3.0"\n')
        f.write('    implementation "androidx.camera:camera-lifecycle:1.3.0"\n')
        f.write('    implementation "androidx.camera:camera-view:1.3.0"\n')
    f.write('}\n')
