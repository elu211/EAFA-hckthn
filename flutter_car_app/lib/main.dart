import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

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
  String cameraViewMode = 'single'; // 'single' or 'dual'

  Timer? _timer;
  Timer? _speedTimer;
  Timer? _alertTimer;
  Timer? _captureTimer;
  final Random _random = Random();

  List<CameraDescription> _cameras = [];
  CameraController? _frontCameraController;
  CameraController? _rearCameraController;
  bool _isFrontCameraInitialized = false;
  bool _isRearCameraInitialized = false;
  final List<Map<String, dynamic>> _capturedImages = [];
  final List<Map<String, dynamic>> _aiResults = []; // Store AI analysis results
  bool _backendConnected = false; // Backend connection status
  
  // Backend API configuration
  static const String backendUrl = 'http://localhost:5000'; // For web and local development
  // static const String backendUrl = 'http://10.0.2.2:5000'; // For Android emulator
  static const String analyzeEndpoint = '/analyze';
  static const String healthEndpoint = '/health';

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _startTimers();
    _checkBackendConnection();
  }

  // Check backend connection on startup
  Future<void> _checkBackendConnection() async {
    final isConnected = await _checkBackendHealth();
    if (mounted) {
      setState(() {
        _backendConnected = isConnected;
      });
    }
    if (isConnected) {
      addAlert(AlertType.success, 'Backend AI model connected');
    } else {
      addAlert(AlertType.danger, 'Backend AI model not available');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedTimer?.cancel();
    _alertTimer?.cancel();
    _captureTimer?.cancel();
    _frontCameraController?.dispose();
    _rearCameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameras() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('Requesting camera permissions...');
      final cameras = await availableCameras();
      debugPrint('Camera permission check completed');
      
      if (mounted) {
        setState(() {
          _cameras = cameras;
        });
        if (_cameras.isNotEmpty) {
          await _initializeCameraControllers();
        } else {
          addAlert(AlertType.warning, 'No cameras found');
          debugPrint('No cameras available on this device');
        }
      }
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      if (mounted) {
        addAlert(AlertType.danger, 'Camera initialization failed: $e');
      }
    }
  }

  Future<void> _initializeCameraControllers() async {
    if (_cameras.isEmpty) return;
    
    if (mounted) {
      setState(() {
        _isFrontCameraInitialized = false;
        _isRearCameraInitialized = false;
      });
    }
    
    CameraDescription? frontCamera;
    CameraDescription? rearCamera;
    
    debugPrint('Available cameras: $_cameras');
    for (var cam in _cameras) {
      debugPrint('  ${cam.name} (${cam.lensDirection})');
    }
    
    for (var camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
      } else if (camera.lensDirection == CameraLensDirection.back) {
        rearCamera = camera;
      }
    }
    debugPrint('Selected front camera: $frontCamera');
    debugPrint('Selected rear camera: $rearCamera');

    if (frontCamera != null) {
      _frontCameraController?.dispose();
      _frontCameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      try {
        await _frontCameraController!.initialize();
        if (mounted) {
          setState(() {
            _isFrontCameraInitialized = true;
          });
        }
        debugPrint('Front camera initialized successfully');
      } catch (e) {
        debugPrint('Error initializing front camera: $e');
        if (mounted) {
          setState(() {
            _isFrontCameraInitialized = false;
          });
        }
      }
    }

    if (rearCamera != null) {
      _rearCameraController?.dispose();
      _rearCameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      try {
        await _rearCameraController!.initialize();
        if (mounted) {
          setState(() {
            _isRearCameraInitialized = true;
          });
        }
        debugPrint('Rear camera initialized successfully');
      } catch (e) {
        debugPrint('Error initializing rear camera: $e');
        if (mounted) {
          setState(() {
            _isRearCameraInitialized = false;
          });
        }
      }
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

  // void startRecording() {
  //   setState(() {
  //     isRecordingVideo = true;
  //   });
  //   addAlert(AlertType.success, 'Recording started (simulated)');
  //   debugPrint('Recording started - camera integration pending');
  // }

  // void stopRecording() {
  //   setState(() {
  //     isRecordingVideo = false;
  //   });
  //   addAlert(AlertType.info, 'Recording stopped and saved');
  //   debugPrint('Recording stopped - camera integration pending');
  // }

  // void toggleRecording() {
  //   if (isRecording) {
  //     stopRecording();
  //     setState(() {
  //       isRecording = false;
  //       recordingTime = 0;
  //     });
  //     _alertTimer?.cancel();
  //   } else {
  //     startRecording();
  //     setState(() {
  //       isRecording = true;
  //     });
  //     _startAlertTimer();
  //   }
  // }

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
            // Camera View Mode Selection
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cameraViewMode = 'single';
                          activeCamera = 'front';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cameraViewMode == 'single' && activeCamera == 'front'
                            ? Colors.blue
                            : Colors.grey[800],
                      ),
                      child: Text('Front'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          cameraViewMode = 'single';
                          activeCamera = 'rear';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cameraViewMode == 'single' && activeCamera == 'rear'
                            ? Colors.blue
                            : Colors.grey[800],
                      ),
                      child: Text('Rear'),
                    ),
                  ),
                  // SizedBox(width: 8),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         cameraViewMode = 'dual';
                  //       });
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: cameraViewMode == 'dual'
                  //           ? Colors.blue
                  //           : Colors.grey[800],
                  //     ),
                  //     child: Text('Dual'),
                  //   ),
                  // ),
                ],
              ),
            ),
            
            // Main Camera Display
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF374151),
                  border: Border.all(color: Color(0xFF4B5563), width: 2),
                ),
                child: cameraViewMode == 'dual'
                    ? Column(
                        children: [
                          Expanded(
                            child: _isFrontCameraInitialized && _frontCameraController != null
                                ? Stack(
                                    children: [
                                      CameraPreview(_frontCameraController!),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('FRONT', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text(
                                          'Front Camera',
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        Text(
                                          'Status: $_isFrontCameraInitialized',
                                          style: TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: _isRearCameraInitialized && _rearCameraController != null
                                ? Stack(
                                    children: [
                                      CameraPreview(_rearCameraController!),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('REAR', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      // Speed overlay for rear camera
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withAlpha((0.5 * 255).toInt()),
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

                                      // Backend Status Indicator
                                      Positioned(
                                        bottom: 16,
                                        right: 16,
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _backendConnected 
                                              ? Colors.green.withAlpha((0.8 * 255).toInt())
                                              : Colors.red.withAlpha((0.8 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _backendConnected ? Icons.psychology : Icons.error,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                _backendConnected ? 'AI' : 'NO AI',
                                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          _buildSingleCameraView(),
                          if (isRecording)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha((0.5 * 255).toInt()),
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
                              ),
                            ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha((0.5 * 255).toInt()),
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
                      // Container(
                      //   margin: EdgeInsets.only(bottom: 24),
                      //   child: Center(
                      //     child: GestureDetector(
                      //       onTap: toggleRecording,
                      //       child: Container(
                      //         width: 80,
                      //         height: 80,
                      //         decoration: BoxDecoration(
                      //           color: isRecording ? Color(0xFFEF4444) : Colors.white,
                      //           borderRadius: BorderRadius.circular(40),
                      //         ),
                      //         child: Icon(
                      //           isRecording ? Icons.stop : Icons.videocam,
                      //           size: 32,
                      //           color: isRecording ? Colors.white : Colors.black,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),

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
                            child: Row(
                              children: [
                                Expanded(
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
                                SizedBox(width: 12),
                              ],
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

  Widget _buildSingleCameraView() {
    CameraController? controller = activeCamera == 'front'
        ? _frontCameraController
        : _rearCameraController;
    bool isInitialized = activeCamera == 'front'
        ? _isFrontCameraInitialized
        : _isRearCameraInitialized;
    
    if (isInitialized && controller != null) {
      return Stack(
        children: [
          CameraPreview(controller),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.7 * 255).toInt()),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activeCamera.toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing $activeCamera camera...',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Front: $_isFrontCameraInitialized, Rear: $_isRearCameraInitialized',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'Available cameras: ${_cameras.length}',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
    }
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
    CameraController? controllerToUse = _rearCameraController?.value.isInitialized == true 
        ? _rearCameraController 
        : _frontCameraController?.value.isInitialized == true 
            ? _frontCameraController 
            : null;
            
    if (controllerToUse == null) {
      return;
    }

    try {
      final XFile image = await controllerToUse.takePicture();
      final timestamp = DateTime.now();
      
      if (mounted) {
        setState(() {
          _capturedImages.add({'file': image, 'timestamp': timestamp});
        });
        
        if (_capturedImages.length > 100) {
          setState(() {
            _capturedImages.removeAt(0);
          });
        }
      }
      
      debugPrint('Picture captured: ${image.path} at $timestamp');
      
      // Send image to backend for AI analysis
      await _sendImageToBackend(image, timestamp);
      
    } catch (e) {
      debugPrint('Error capturing picture: $e');
    }
  }

  // Send image to backend for AI analysis
  Future<void> _sendImageToBackend(XFile image, DateTime timestamp) async {
    try {
      // Convert image to bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      debugPrint('Image size: ${imageBytes.length} bytes');
      debugPrint('Sending image to backend: ${image.path}');
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl$analyzeEndpoint'),
      );
      
      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'dashcam_${timestamp.millisecondsSinceEpoch}.jpg',
        ),
      );
      
      // Add timestamp
      request.fields['timestamp'] = timestamp.toIso8601String();
      
      debugPrint('Request URL: ${request.url}');
      debugPrint('Request fields: ${request.fields}');
      debugPrint('Request files: ${request.files.length}');
      
      // Send request with timeout
      final response = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
      
      final responseBody = await response.stream.bytesToString();
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');
      
      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        debugPrint('AI Analysis Result: $result');
        
        if (mounted) {
          setState(() {
            _aiResults.add({
              'timestamp': timestamp,
              'result': result,
            });
          });
          
          // Keep only last 50 AI results
          if (_aiResults.length > 50) {
            setState(() {
              _aiResults.removeAt(0);
            });
          }
          
          // Process AI results and show alerts
          _processAIResult(result, timestamp);
        }
      } else {
        debugPrint('Backend error: ${response.statusCode} - $responseBody');
        if (mounted) {
          addAlert(AlertType.danger, 'Backend error: ${response.statusCode}');
        }
      }
      
    } catch (e) {
      debugPrint('Error sending image to backend: $e');
      if (mounted) {
        addAlert(AlertType.danger, 'Network error: ${e.toString()}');
      }
    }
  }

  // Process AI analysis results and show alerts
  void _processAIResult(Map<String, dynamic> result, DateTime timestamp) {
    try {
      // Get the raw prediction from your model
      final String prediction = result['prediction'] ?? 'unknown';
      final double confidence = result['confidence'] ?? 0.0;
      final Map<String, dynamic> allProbabilities = result['all_probabilities'] ?? {};
      
      // Show the raw result as an alert
      addAlert(AlertType.info, 'AI: $prediction (${(confidence * 100).toStringAsFixed(1)}%)');
      
      // Also show all probabilities as separate alerts
      allProbabilities.forEach((className, probability) {
        final probPercent = (probability * 100).toStringAsFixed(1);
        addAlert(AlertType.info, '$className: $probPercent%');
      });
      
      // Print detailed results to console
      debugPrint('=== AI MODEL RESULT ===');
      debugPrint('Prediction: $prediction');
      debugPrint('Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      debugPrint('All probabilities: $allProbabilities');
      debugPrint('========================');
      
    } catch (e) {
      debugPrint('Error processing AI result: $e');
      addAlert(AlertType.danger, 'AI processing error: $e');
    }
  }

  // Check backend health
  Future<bool> _checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl$healthEndpoint'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Carfully',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: AIDashcamApp(),
    debugShowCheckedModeBanner: false,
  ));
}