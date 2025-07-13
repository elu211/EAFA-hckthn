import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';

// Define types for better type safety
enum AlertType { danger, warning, info, success }

class Alert {
  final int id;
  final AlertType type;
  final String message;
  final DateTime timestamp;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

class AIFeatures {
  bool laneDetection;
  bool collisionWarning;
  bool speedLimit;
  bool parkingMode;

  AIFeatures({
    this.laneDetection = true,
    this.collisionWarning = true,
    this.speedLimit = true,
    this.parkingMode = false,
  });
}

class AIDashcamApp extends StatefulWidget {
  const AIDashcamApp({super.key});

  @override
  State<AIDashcamApp> createState() => _AIDashcamAppState();
}

class _AIDashcamAppState extends State<AIDashcamApp> {
  bool isRecording = false;
  String activeCamera = 'rear';
  int recordingTime = 0;
  DateTime currentTime = DateTime.now();
  double speed = 0;
  List<Alert> alerts = [];
  AIFeatures aiFeatures = AIFeatures();
  String cameraType = 'back';
  bool isRecordingVideo = false;

  Timer? _timer;
  Timer? _speedTimer;
  Timer? _alertTimer;
  Timer? _captureTimer; // Timer for automatic picture capture
  final Random _random = Random();

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false; // Add flag for capture indicator
  List<Map<String, dynamic>> _capturedImages = []; // Store captured images

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _startTimers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedTimer?.cancel();
    _alertTimer?.cancel();
    _captureTimer?.cancel(); // Cancel capture timer
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final cameras = await availableCameras();
      setState(() {
        _cameras = cameras;
      });
      if (_cameras.isNotEmpty) {
        await _initializeCameraController();
      }
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      addAlert(AlertType.danger, 'Camera initialization failed');
    }
  }

  Future<void> _initializeCameraController() async {
    if (_cameras.isEmpty) return;
    
    // Dispose old controller properly
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    
    setState(() {
      _isCameraInitialized = false;
    });
    
    CameraDescription? selectedCamera;
    try {
      if (activeCamera == 'front') {
        selectedCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        selectedCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }
    } catch (e) {
      debugPrint('Error selecting camera: $e');
      selectedCamera = _cameras.first;
    }
    
    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      addAlert(AlertType.danger, 'Failed to initialize camera');
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    }
  }

  Future<void> _switchCamera(String mode) async {
    if (activeCamera == mode) return; // Don't switch if already on that camera
    
    setState(() {
      activeCamera = mode;
      cameraType = mode == 'front' ? 'front' : 'back';
    });
    
    addAlert(AlertType.info, 'Switching to $mode camera...');
    
    await _initializeCameraController();
    
    if (_isCameraInitialized) {
      addAlert(AlertType.success, 'Switched to $mode camera');
    } else {
      addAlert(AlertType.danger, 'Failed to switch to $mode camera');
    }
  }

  void _startTimers() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
        if (isRecording) {
          recordingTime++;
        }
      });
    });

    _speedTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        speed = max(0, speed + (_random.nextDouble() - 0.5) * 10);
      });
    });

    _captureTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _capturePicture();
      }
    });
  }

  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void startRecording() {
    setState(() {
      isRecordingVideo = true;
    });
    addAlert(AlertType.success, 'Recording started (simulated)');
    debugPrint('Recording started - camera integration pending');
  }

  void stopRecording() {
    setState(() {
      isRecordingVideo = false;
    });
    addAlert(AlertType.info, 'Recording stopped and saved');
    debugPrint('Recording stopped - camera integration pending');
  }

  void toggleRecording() {
    if (isRecording) {
      stopRecording();
      setState(() {
        isRecording = false;
        recordingTime = 0;
      });
      _alertTimer?.cancel();
    } else {
      startRecording();
      setState(() {
        isRecording = true;
      });
      _startAlertTimer();
    }
  }

  void _startAlertTimer() {
    _alertTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      final alertTypes = [
        {'type': AlertType.warning, 'message': 'Lane departure detected'},
        {'type': AlertType.danger, 'message': 'Forward collision risk'},
        {'type': AlertType.info, 'message': 'Speed limit: 65 mph'},
        {'type': AlertType.success, 'message': 'Parking mode activated'}
      ];

      if (_random.nextDouble() < 0.3) {
        final randomAlert = alertTypes[_random.nextInt(alertTypes.length)];
        addAlert(randomAlert['type'] as AlertType, randomAlert['message'] as String);
      }
    });
  }

  void addAlert(AlertType type, String message) {
    final newAlert = Alert(
      id: DateTime.now().millisecondsSinceEpoch,
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );
    setState(() {
      alerts = [newAlert, ...alerts.take(4)];
    });
  }

  Color getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.danger:
        return Color(0xFFEF4444);
      case AlertType.warning:
        return Color(0xFFF59E0B);
      case AlertType.info:
        return Color(0xFF3B82F6);
      case AlertType.success:
        return Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Main Camera Display
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  border: Border.all(color: Color(0xFF4B5563), width: 2),
                ),
                child: Stack(
                  children: [
                    // Camera Feed
                    if (_isCameraInitialized && _cameraController != null)
                      CameraPreview(_cameraController!)
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isCameraInitialized)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
                              )
                            else
                              Icon(Icons.camera_alt, size: 64, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 16),
                            Text(
                              activeCamera == 'front' ? 'Front Camera' : 'Rear Camera',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _isCameraInitialized ? 'Camera Ready' : 'Initializing Camera...',
                              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                            ),
                            if (_cameras.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'No cameras detected',
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Camera Overlays
                    Positioned(
                      top: 16,
                      left: 16,
                      child: isRecording ? Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('REC', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontFamily: 'monospace')),
                            SizedBox(width: 8),
                            Text(formatTime(recordingTime), style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace')),
                          ],
                        ),
                      ) : SizedBox.shrink(),
                    ),

                    // Speed and Location Overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text('${speed.round()} mph', style: TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),

                    // Capture Indicator
                    if (_isCapturing)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('CAPTURING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // AI Alerts Panel
            Container(
              height: 80,
              color: Color(0xFF111827),
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, size: 16, color: Color(0xFF60A5FA)),
                      SizedBox(width: 8),
                      Text('AI ALERTS', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: alerts.take(2).length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: getAlertColor(alert.type),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.message,
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Control Panel
            Expanded(
              flex: 1,
              child: Container(
                color: Color(0xFF111827),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Recording Controls
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: GestureDetector(
                            onTap: toggleRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isRecording ? Color(0xFFEF4444) : Colors.white,
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: Icon(
                                isRecording ? Icons.stop : Icons.videocam,
                                size: 32,
                                color: isRecording ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Camera Selection
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Camera Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Row(
                              children: ['front', 'rear'].map((mode) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: mode == 'front' ? 8 : 0),
                                  child: GestureDetector(
                                    onTap: !_isCameraInitialized ? null : () {
                                      _switchCamera(mode);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: activeCamera == mode ? Color(0xFF2563EB) : Color(0xFF374151),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (activeCamera == mode && !_isCameraInitialized)
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                          if (activeCamera == mode && !_isCameraInitialized)
                                            Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: SizedBox.shrink(),
                                            ),
                                          Text(
                                            mode[0].toUpperCase() + mode.substring(1),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: !_isCameraInitialized && activeCamera != mode 
                                                ? Color(0xFF6B7280) 
                                                : Colors.white, 
                                              fontSize: 14
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),

                      // AI Features
                      Container(
                        margin: EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Features', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildFeatureItem('Lane Detection', aiFeatures.laneDetection, () {
                                  setState(() {
                                    aiFeatures.laneDetection = !aiFeatures.laneDetection;
                                  });
                                }),
                                _buildFeatureItem('Collision Warning', aiFeatures.collisionWarning, () {
                                  setState(() {
                                    aiFeatures.collisionWarning = !aiFeatures.collisionWarning;
                                  });
                                }),
                                _buildFeatureItem('Speed Limit', aiFeatures.speedLimit, () {
                                  setState(() {
                                    aiFeatures.speedLimit = !aiFeatures.speedLimit;
                                  });
                                }),
                                _buildFeatureItem('Parking Mode', aiFeatures.parkingMode, () {
                                  setState(() {
                                    aiFeatures.parkingMode = !aiFeatures.parkingMode;
                                  });
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF374151),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.settings, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Settings', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning, size: 20, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Emergency', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Status Footer
            Container(
              color: Color(0xFF1F2937),
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text(
                  'Storage: 128GB • Available: 89GB • Auto-backup: On',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, bool isChecked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isChecked ? Color(0xFF2563EB) : Colors.transparent,
                border: Border.all(color: isChecked ? Color(0xFF2563EB) : Color(0xFF4B5563)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: isChecked ? Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _capturePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true; // Set flag to show capturing indicator
      });
      
      final XFile image = await _cameraController!.takePicture();
      final timestamp = DateTime.now();
      
      setState(() {
        _capturedImages.add({'file': image, 'timestamp': timestamp});
        _isCapturing = false; // Clear flag after capture
      });
      
      // Keep only the last 100 images to prevent memory issues
      if (_capturedImages.length > 100) {
        setState(() {
          _capturedImages.removeAt(0);
        });
      }
      
      debugPrint('Picture captured: ${image.path} at $timestamp');
    } catch (e) {
      debugPrint('Error capturing picture: $e');
      setState(() {
        _isCapturing = false; // Clear flag on error
      });
    }
  }
}

void main() {
  runApp(MaterialApp(
    title: 'AI Dashcam',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: AIDashcamApp(),
    debugShowCheckedModeBanner: false,
  ));
}