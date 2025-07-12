# Camera Integration Documentation

## Overview
The AI Dashcam App now includes real camera integration using Expo Camera API. The app can switch between front and rear cameras, and display live camera feeds.

## Features

### Camera Modes
- **Front Camera**: Uses the front-facing (selfie) camera
- **Rear Camera**: Uses the back-facing camera (default)
- **Both Cameras**: Shows rear camera as main view with front camera as picture-in-picture

### Camera Controls
- Camera mode selection buttons in the control panel
- Real-time camera switching
- Permission handling with user-friendly alerts

### Technical Implementation

#### Permissions
- Camera permissions are automatically requested on app startup
- Graceful fallback UI when permissions are denied
- Loading state while permissions are being requested

#### Camera Component
- Uses `CameraView` from `expo-camera`
- Supports both front and rear camera types
- 16:9 aspect ratio for optimal viewing
- Real-time camera feed display

#### State Management
- `hasPermission`: Tracks camera permission status
- `cameraType`: Current camera type ('front' or 'back')
- `activeCamera`: Selected camera mode ('front', 'rear', 'both')
- `cameraRef`: Reference to camera component

## Usage

1. **First Launch**: App will request camera permissions
2. **Camera Selection**: Use the camera mode buttons to switch between cameras
3. **Recording**: The record button works with the active camera feed
4. **AI Features**: AI alerts are displayed over the camera feed

## Android Configuration

The following permissions have been added to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="true"/>
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
```

## Dependencies

- `expo-camera`: ^16.1.10 (already included in package.json)

## Troubleshooting

### Camera Not Working
1. Check if camera permissions are granted
2. Ensure the device has a camera
3. Try restarting the app

### Permission Denied
- The app will show a fallback UI
- Users can grant permissions in device settings
- App will request permissions again on next launch

### Performance Issues
- Camera feeds are optimized for 16:9 aspect ratio
- Picture-in-picture mode is only active in 'both' camera mode
- Consider device performance when using multiple camera features 