# Camera Integration Guide

## Current Status
✅ **App is now working without camera errors**
✅ **All UI components are functional**
✅ **Recording simulation works**
✅ **Camera permissions are configured**

## Next Steps to Add Real Camera

### 1. Install Camera Dependencies
```bash
npx expo install expo-camera expo-media-library
```

### 2. Rebuild the App
After installing camera dependencies, you need to rebuild:
```bash
npx expo run:android
```

### 3. Update the Code
Replace the placeholder camera code in `app/(tabs)/index.tsx`:

#### Add imports:
```typescript
import { Camera } from 'expo-camera';
import * as MediaLibrary from 'expo-media-library';
```

#### Replace camera states:
```typescript
// Camera states
const [hasCameraPermission, setHasCameraPermission] = useState<boolean | null>(null);
const [cameraType, setCameraType] = useState<'front' | 'back'>('back');
const [flashMode, setFlashMode] = useState<'off' | 'on'>('off');
const cameraRef = React.useRef<Camera>(null);

useEffect(() => {
  (async () => {
    const { status: cameraStatus } = await Camera.requestCameraPermissionsAsync();
    const { status: mediaStatus } = await MediaLibrary.requestPermissionsAsync();
    
    if (cameraStatus !== 'granted' || mediaStatus !== 'granted') {
      RNAlert.alert(
        'Permissions Required',
        'Camera and media library permissions are required for dashcam functionality.',
        [{ text: 'OK' }]
      );
      return;
    }
    
    setHasCameraPermission(true);
  })();
}, []);
```

#### Replace recording functions:
```typescript
const startRecording = async () => {
  if (!cameraRef.current) return;

  try {
    const video = await cameraRef.current.recordAsync({
      quality: '1080p',
      maxDuration: 3600, // 1 hour max
      mute: false,
    });

    // Save to media library
    await MediaLibrary.saveToLibraryAsync(video.uri);
    
    setIsRecording(false);
  } catch (error) {
    console.error('Recording error:', error);
    RNAlert.alert('Recording Error', 'Failed to start recording');
  }
};

const stopRecording = async () => {
  if (!cameraRef.current) return;
  
  try {
    await cameraRef.current.stopRecording();
  } catch (error) {
    console.error('Stop recording error:', error);
  }
};
```

#### Replace camera placeholder with real camera:
```typescript
{/* Main Camera Display */}
<View style={styles.cameraContainer}>
  <Camera
    ref={cameraRef}
    style={styles.camera}
    type={cameraType}
    flashMode={flashMode}
    ratio="16:9"
  >
    {/* Camera Overlays */}
    <View style={styles.cameraOverlay}>
      {/* Recording Indicator */}
      {isRecording && (
        <View style={styles.recordingIndicator}>
          <View style={styles.recordingDot} />
          <Text style={styles.recordingText}>REC</Text>
          <Text style={styles.recordingTime}>{formatTime(recordingTime)}</Text>
        </View>
      )}

      {/* Camera Controls */}
      <View style={styles.cameraControls}>
        <TouchableOpacity
          style={styles.controlButton}
          onPress={toggleFlash}
        >
          <Ionicons 
            name={flashMode === 'off' ? "flash-off" : "flash"} 
            size={24} 
            color="white" 
          />
        </TouchableOpacity>
      </View>

      {/* Speed and Location Overlay */}
      <View style={styles.speedOverlay}>
        <Ionicons name="location" size={16} color="white" />
        <Text style={styles.speedText}>{Math.round(speed)} mph</Text>
      </View>
    </View>
  </Camera>
</View>
```

### 4. Test on Device
1. Connect Android device with USB debugging
2. Run: `npx expo run:android`
3. Grant camera and media permissions when prompted
4. Test recording functionality

## Features Available After Integration
- ✅ Real camera feed (front/back)
- ✅ Video recording with 1080p quality
- ✅ Automatic save to gallery
- ✅ Flash control
- ✅ Recording timer
- ✅ Camera switching
- ✅ All existing UI features

## Troubleshooting
- If you get "ExpoCamera native module" error, rebuild the app
- If permissions fail, check device settings
- If recording fails, ensure media library permissions are granted 