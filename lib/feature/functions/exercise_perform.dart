import 'dart:async';
import 'dart:convert'; // For base64 and json
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as io; // Added
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

// Helper to draw landmarks
class PosePainter extends CustomPainter {
  final List<Offset> landmarks;
  final Size imageSize;
  final bool mirrorLandmarks; // New flag
  final Paint P_left =
      Paint()
        ..color = Colors.lightBlueAccent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8;
  final Paint P_right =
      Paint()
        ..color = Colors.yellowAccent
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8;

  // MediaPipe Pose connections (simplified for example)
  // You might want to define these more accurately based on MediaPipe's 33 landmarks
  final List<List<int>> connections = [
    // Face (approx)
    [0, 1], [1, 2], [2, 3], [3, 7], [0, 4], [4, 5], [5, 6], [6, 8], [9, 10],
    // Shoulders
    [11, 12],
    // Torso
    [11, 23], [12, 24], [23, 24],
    // Left Arm
    [11, 13], [13, 15],
    // Right Arm
    [12, 14], [14, 16],
    // Left Leg
    [23, 25], [25, 27], [27, 29], [27, 31], [29, 31],
    // Right Leg
    [24, 26], [26, 28], [28, 30], [28, 32], [30, 32],
  ];

  PosePainter({
    required this.landmarks,
    required this.imageSize,
    this.mirrorLandmarks = false,
  }); // Default to false

  @override
  void paint(Canvas canvas, Size size) {
    // size is the CustomPaint widget's size
    if (landmarks.isEmpty || imageSize.isEmpty) return;

    final paint =
        Paint()
          ..color = Colors.red
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5.0;

    final connectionPaint =
        Paint()
          ..color = Colors.lightGreenAccent
          ..strokeWidth = 3.0;

    List<Offset> processedLandmarks =
        landmarks.map((originalLm) {
          // originalLm is (lx, ly) from server, normalized to landscape
          // Step 1: Transform for sensor rotation (landscape sensor to portrait view)
          // originalLm.dx is normalized to landscape sensor's width
          // originalLm.dy is normalized to landscape sensor's height
          double xNormForPortraitCanvas =
              originalLm.dy; // ly becomes the X on portrait view
          double yNormForPortraitCanvas =
              1.0 - originalLm.dx; // (1-lx) becomes the Y on portrait view

          // Step 2: Apply mirroring if needed (for front camera's mirrored feed)
          if (mirrorLandmarks) {
            xNormForPortraitCanvas =
                1.0 - xNormForPortraitCanvas; // Flip the new x-coordinate
          }

          return Offset(
            xNormForPortraitCanvas * size.width, // Scale to canvas width
            yNormForPortraitCanvas * size.height, // Scale to canvas height
          );
        }).toList();

    for (final landmark in processedLandmarks) {
      canvas.drawCircle(landmark, 5, paint);
    }

    // Draw connections
    for (var connection in connections) {
      if (connection[0] < processedLandmarks.length &&
          connection[1] < processedLandmarks.length) {
        // crude L/R coloring
        final Paint P_to_use;
        if ([
              11,
              13,
              15,
              17,
              19,
              21,
              23,
              25,
              27,
              29,
              31,
            ].contains(connection[0]) &&
            [
              11,
              13,
              15,
              17,
              19,
              21,
              23,
              25,
              27,
              29,
              31,
            ].contains(connection[1])) {
          P_to_use = P_left;
        } else if ([
              12,
              14,
              16,
              18,
              20,
              22,
              24,
              26,
              28,
              30,
              32,
            ].contains(connection[0]) &&
            [
              12,
              14,
              16,
              18,
              20,
              22,
              24,
              26,
              28,
              30,
              32,
            ].contains(connection[1])) {
          P_to_use = P_right;
        } else {
          P_to_use = connectionPaint;
        }
        canvas.drawLine(
          processedLandmarks[connection[0]],
          processedLandmarks[connection[1]],
          P_to_use,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.mirrorLandmarks != mirrorLandmarks; // Include new flag
  }
}

class ExercisePerform extends StatefulWidget {
  final int targetReps;
  final String initialExerciseType;

  const ExercisePerform({
    super.key,
    required this.targetReps,
    this.initialExerciseType = "bicep_curl", // Default if not provided
  });

  @override
  State<ExercisePerform> createState() => _ExercisePerformState();
}

class _ExercisePerformState extends State<ExercisePerform>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  io.Socket? _socket;
  bool _isProcessingFrame = false;
  Timer? _frameThrottleTimer;

  List<Offset> _landmarks = [];
  Size _cameraImageSize = Size.zero;
  String _currentExercise = "";
  int _currentReps = 0;
  String _currentPosition = "N/A";
  String _serverMessage = "Initializing...";

  final List<String> _availableExercises = [
    "bicep_curl",
    "squat",
    "lateral_raise",
    "overhead_press",
    "torso_twist",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentExercise = widget.initialExerciseType;
    _requestCameraPermission(); // This will call _initializeAllServices if permission is granted
  }

  Future<void> _initializeAllServices() async {
    if (!_isCameraPermissionGranted) {
      // This case should ideally be handled by _requestCameraPermission re-attempting or showing UI
      print("Attempted to initialize services without camera permission.");
      if (mounted) {
        setState(() {
          _serverMessage = "Camera permission needed to start.";
        });
      }
      return;
    }
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      print("Services already initialized.");
      // If socket is disconnected, try to reconnect it
      if (_socket == null || _socket!.disconnected) {
        _initializeSocketIO();
      }
      return;
    }

    await _initializeCamera(); // Initializes camera and starts stream if successful
    if (_isCameraInitialized) {
      // Only initialize socket if camera is ready
      _initializeSocketIO();
    }
  }

  Future<void> _disposeAllResources() async {
    _frameThrottleTimer?.cancel();
    _frameThrottleTimer = null;

    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
      } catch (e) {
        print("Error disposing camera controller: $e");
      }
    }

    _socket?.dispose();
    _socket = null;

    // Use a local variable for mounted status to avoid issues if dispose is called late.
    bool isMounted = mounted;

    if (isMounted) {
      setState(() {
        _cameraController = null;
        _isCameraInitialized = false;
        _landmarks = [];
        // _serverMessage = "Disconnected"; // Update status message
      });
    } else {
      // If not mounted, just nullify
      _cameraController = null;
      _isCameraInitialized = false;
      _landmarks = [];
    }
  }

  Future<void> _requestCameraPermission() async {
    final permStatus = await Permission.camera.request();
    if (!mounted) return;

    if (permStatus == PermissionStatus.granted) {
      setState(() {
        _isCameraPermissionGranted = true;
        _serverMessage = "Permission granted. Initializing...";
      });
      await _initializeAllServices();
    } else {
      setState(() {
        _isCameraPermissionGranted = false;
        _serverMessage =
            "Camera permission denied. Grant in settings & restart exercise.";
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (!_isCameraPermissionGranted) {
      print("Camera initialization skipped: permission not granted.");
      return;
    }
    // If already initialized and controller is valid, do nothing.
    if (_isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      print("Camera already initialized and valid.");
      // Ensure stream is running if it should be
      if (!_cameraController!.value.isStreamingImages &&
          _socket != null &&
          _socket!.connected) {
        _startImageStream(); // Defined below
      }
      return;
    }

    // If a controller exists but isn't initialized (e.g. previous attempt failed), dispose it first.
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null; // Nullify to ensure a fresh instance
    }

    final cameras = await availableCameras();
    if (!mounted || cameras.isEmpty) {
      if (mounted) setState(() => _serverMessage = "No cameras available");
      return;
    }

    CameraDescription selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) {
        // If widget is disposed during async operation
        _cameraController?.dispose(); // Clean up the newly created controller
        return;
      }

      final previewSize = _cameraController!.value.previewSize;
      if (previewSize != null) {
        _cameraImageSize = Size(
          previewSize.height,
          previewSize.width,
        ); // For portrait from landscape sensor
      } else {
        _cameraImageSize = Size.zero;
      }

      setState(() {
        _isCameraInitialized = true;
        _serverMessage = "Camera initialized. Connecting to server...";
      });

      _startImageStream();
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _serverMessage = "Error initializing camera: $e";
          _isCameraInitialized = false; // Ensure state reflects failure
        });
      }
      _cameraController?.dispose(); // Clean up on error
      _cameraController = null;
    }
  }

  void _startImageStream() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isStreamingImages) {
      return; // Not ready or already streaming
    }
    _cameraController!.startImageStream((CameraImage image) {
      if (_frameThrottleTimer == null || !_frameThrottleTimer!.isActive) {
        _frameThrottleTimer = Timer(const Duration(milliseconds: 200), () {
          if (mounted && // Ensure widget is still mounted
              !_isProcessingFrame &&
              _cameraController != null &&
              _cameraController!
                  .value
                  .isStreamingImages && // Check if still streaming
              _socket != null &&
              _socket!.connected) {
            _onFrameReceived(image);
          }
        });
      }
    });
  }

  void _initializeSocketIO() {
    if (_socket != null && _socket!.connected) {
      print("Socket.IO already connected. Ensuring exercise type is current.");
      _sendSelectExerciseToServer(_currentExercise);
      return;
    }

    final serverIp = "192.168.105.172"; // CONFIGURATION: Your server IP

    if (serverIp == "YOUR_SERVER_IP_PLACEHOLDER") {
      if (mounted) {
        setState(() {
          _serverMessage = "Server IP not configured in code.";
        });
      }
      return;
    }

    final String uriString = 'http://$serverIp:5000';
    print("Socket.IO: Attempting to connect to $uriString");

    try {
      _socket = io.io(uriString, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        print('Socket.IO: Connected. SID: ${_socket?.id}');
        if (mounted) {
          setState(() => _serverMessage = "Connected. Setting exercise...");
        }
        _sendSelectExerciseToServer(_currentExercise);
        if (_isCameraInitialized &&
            _cameraController != null &&
            _cameraController!.value.isInitialized &&
            !_cameraController!.value.isStreamingImages) {
          _startImageStream();
        }
      });

      _socket!.onDisconnect((reason) {
        print('Socket.IO: Disconnected. Reason: $reason');
        if (mounted) {
          setState(
            () =>
                _serverMessage =
                    "Disconnected. Reps: $_currentReps/${widget.targetReps}",
          );
        }
      });

      _socket!.onError((data) {
        print('Socket.IO: General Error: $data');
        if (mounted) {
          setState(
            () => _serverMessage = "Connection Error: Check Server or Network.",
          );
        }
      });

      _socket!.onConnectError((data) {
        print('Socket.IO: Connection Attempt Error: $data');
        if (mounted) {
          setState(
            () => _serverMessage = "Failed to connect. Check Server IP & Port.",
          );
        }
      });

      _socket!.on('connection_ack', (data) {
        print('Socket.IO: Received connection_ack: $data');
        if (mounted && data is Map) {
          setState(() {
            _serverMessage = data['message'] ?? _serverMessage;
            _currentExercise = data['current_exercise'] ?? _currentExercise;
          });
        }
      });

      _socket!.on('exercise_changed', (data) {
        print('Socket.IO: Received exercise_changed: $data');
        if (mounted && data is Map) {
          setState(() {
            _serverMessage = data['message'] ?? "Exercise Updated";
            String serverExercise =
                data['current_exercise'] ?? _currentExercise;
            if (_currentExercise != serverExercise)
              _currentExercise = serverExercise;

            _currentReps = 0;
            _currentPosition = "N/A";
            _landmarks = [];
          });
        }
      });

      _socket!.on('frame_processed', (data) {
        if (mounted && data is Map) {
          if (data['landmarks'] != null && data['landmarks'] is List) {
            List<dynamic> lmData = data['landmarks'];
            setState(() {
              _landmarks =
                  lmData.map((lm) {
                    if (lm is Map && lm['x'] is num && lm['y'] is num) {
                      return Offset(
                        (lm['x'] as num).toDouble(),
                        (lm['y'] as num).toDouble(),
                      );
                    }
                    return Offset.zero;
                  }).toList();
            });
          }
          if (data['exercise_status'] != null &&
              data['exercise_status'] is Map) {
            final status = data['exercise_status'];
            setState(() {
              _currentExercise = status['exercise_type'] ?? _currentExercise;
              _currentReps = status['reps'] ?? _currentReps;
              _currentPosition = status['position'] ?? "N/A";
              _serverMessage =
                  "Tracking: ${_currentExercise.replaceAll('_', ' ').toUpperCase()}";
              if (_currentReps >= widget.targetReps) {
                _navigateToPreviousScreenWithResult(true);
              }
            });
          }
          if (mounted) setState(() {});
        }
      });

      _socket!.on('server_error', (data) {
        print('Socket.IO: Received server_error event: $data');
        if (mounted && data is Map) {
          setState(() {
            _serverMessage = data['message'] ?? "A server error occurred";
          });
        }
      });

      _socket!.on('error', (data) {
        print('Socket.IO: Received generic error event: $data');
        String errorMessage = "An error occurred";
        if (data is Map && data['message'] is String) {
          errorMessage = data['message'];
        } else if (data is String) {
          errorMessage = data;
        }
        if (mounted) {
          setState(() {
            _serverMessage = errorMessage;
          });
        }
      });
      _socket!.connect();
    } catch (e) {
      print("Socket.IO: Exception during setup or connect: $e");
      if (mounted)
        setState(() => _serverMessage = "Socket.IO setup exception.");
    }
  }

  void _sendSelectExerciseToServer(String exerciseType) {
    if (_socket != null && _socket!.connected) {
      final payload = {
        'event_type': 'select_exercise',
        'exercise_type': exerciseType,
      };
      print("Socket.IO: Sending 'message' event with payload: $payload");
      _socket!.emit('message', payload);
    } else {
      print("Socket.IO: Cannot send select_exercise - socket not connected.");
      if (mounted)
        setState(
          () => _serverMessage = "Not connected. Cannot change exercise.",
        );
    }
  }

  Future<void> _onFrameReceived(CameraImage cameraImage) async {
    if (!mounted ||
        _cameraController == null ||
        !_cameraController!.value.isStreamingImages) {
      if (mounted)
        setState(() => _isProcessingFrame = false);
      else
        _isProcessingFrame = false;
      return;
    }
    if (mounted) setState(() => _isProcessingFrame = true);

    try {
      Uint8List? jpegBytes = await _convertCameraImageToJpeg(cameraImage);
      if (jpegBytes != null &&
          mounted &&
          _socket != null &&
          _socket!.connected) {
        String base64Image = base64Encode(jpegBytes);
        final payload = {
          'event_type': 'process_frame',
          'image_data': 'data:image/jpeg;base64,$base64Image',
        };
        _socket!.emit('message', payload);
      }
    } catch (e) {
      print("Error processing/sending frame: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessingFrame = false);
      } else {
        _isProcessingFrame = false;
      }
    }
  }

  // IMPORTANT: Image conversion is complex and platform-dependent.
  // This is a basic example. You might need a more robust solution,
  // potentially using native code or a more advanced image processing package.
  // Consider running this in an isolate for performance.
  Future<Uint8List?> _convertCameraImageToJpeg(CameraImage cameraImage) async {
    try {
      img.Image? image;
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final int width = cameraImage.width;
        final int height = cameraImage.height;

        final yPlane = cameraImage.planes[0].bytes;
        final uPlane = cameraImage.planes[1].bytes;
        final vPlane = cameraImage.planes[2].bytes;
        final yRowStride = cameraImage.planes[0].bytesPerRow;
        final uvRowStride = cameraImage.planes[1].bytesPerRow;
        final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

        image = img.Image(width: width, height: height);

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int yIndex = y * yRowStride + x;

            if (yIndex >= yPlane.length) {
              continue;
            }
            final int yValue = yPlane[yIndex];

            final int uvXSub = x ~/ 2;
            final int uvYSub = y ~/ 2;

            final int uIndex = uvYSub * uvRowStride + uvXSub * uvPixelStride;
            final int vIndex = uvYSub * uvRowStride + uvXSub * uvPixelStride;

            if (uIndex >= uPlane.length || vIndex >= vPlane.length) {
              continue;
            }

            final int uValue = uPlane[uIndex];
            final int vValue = vPlane[vIndex];

            yuv2rgb(int yVal, int uVal, int vVal) {
              int r = (yVal + 1.402 * (vVal - 128)).round().clamp(0, 255);
              int g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
                  .round()
                  .clamp(0, 255);
              int b = (yVal + 1.772 * (uVal - 128)).round().clamp(0, 255);
              return img.ColorRgb8(r, g, b);
            }

            final color = yuv2rgb(yValue, uValue, vValue);
            image.setPixel(x, y, color);
          }
        }
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        image = img.Image.fromBytes(
          width: cameraImage.width,
          height: cameraImage.height,
          bytes: cameraImage.planes[0].bytes.buffer,
          format: img.Format.float32,
        );
      } else {
        print("Unsupported image format: ${cameraImage.format.group}");
        return null;
      }

      return Uint8List.fromList(
        img.encodeJpg(image, quality: 70),
      ); // JPEG with quality
    } catch (e, stackTrace) {
      print("Error converting CameraImage to Jpeg: $e\n$stackTrace");
    }
    return null;
  }

  void _navigateToPreviousScreenWithResult(bool completed) {
    if (mounted) {
      _cameraController?.stopImageStream();
      _socket?.dispose();
      Navigator.pop(context, {'reps': _currentReps, 'completed': completed});
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // If permission is granted but camera is not initialized (e.g. after being paused)
        if (_isCameraPermissionGranted &&
            (!_isCameraInitialized ||
                _cameraController == null ||
                !_cameraController!.value.isInitialized)) {
          print("App resumed, re-initializing services.");
          await _initializeAllServices();
        } else if (_isCameraPermissionGranted &&
            _isCameraInitialized &&
            (_socket == null || _socket!.disconnected)) {
          // Camera might be fine, but socket disconnected
          print(
            "App resumed, Socket.IO disconnected, re-initializing Socket.IO.",
          );
          _initializeSocketIO();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached: // Flutter 3.10+
        print("App inactive/paused/detached, disposing resources.");
        await _disposeAllResources();
        break;
      case AppLifecycleState.hidden: // Flutter 3.13+
        // Similar to paused/detached, ensure resources are released
        print("App hidden, disposing resources.");
        await _disposeAllResources();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Using Future.microtask to ensure dispose logic runs after current event loop
    Future.microtask(() async {
      await _disposeAllResources();
    });
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (!_isCameraPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _serverMessage,
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: Text("Open Settings"),
            ),
          ],
        ),
      );
    }
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Center(
        child: Text(
          _serverMessage.isNotEmpty ? _serverMessage : "Initializing Camera...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    bool shouldMirror =
        _cameraController!.description.lensDirection ==
        CameraLensDirection.front;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Mirror the CameraPreview if it's the front camera
        if (shouldMirror)
          Transform.scale(
            scaleX: -1,
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        if (_landmarks.isNotEmpty)
          // Also mirror the CustomPaint canvas if the preview is mirrored
          if (shouldMirror)
            Transform.scale(
              scaleX: -1,
              child: CustomPaint(
                painter: PosePainter(
                  landmarks: _landmarks,
                  imageSize: _cameraImageSize,
                  mirrorLandmarks: shouldMirror,
                ),
                size: Size.infinite,
              ),
            )
          else
            CustomPaint(
              painter: PosePainter(
                landmarks: _landmarks,
                imageSize: _cameraImageSize,
                mirrorLandmarks: shouldMirror,
              ),
              size: Size.infinite,
            ),
        _buildUIOverlay(),
      ],
    );
  }

  Widget _buildUIOverlay() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Exercise Selection and Server Message
          Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _currentExercise,
                    dropdownColor: Colors.grey[800],
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    underline: Container(),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _currentExercise) {
                        _sendSelectExerciseToServer(newValue);
                      }
                    },
                    items:
                        _availableExercises.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.replaceAll('_', ' ').toUpperCase(),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _serverMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Row: Rep Count and Status
          Container(
            color: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "REPS",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      "$_currentReps / ${widget.targetReps}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "STATUS",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      _currentPosition.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentExercise.replaceAll('_', ' ').toUpperCase()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              () => _navigateToPreviousScreenWithResult(false), // Not completed
        ),
      ),
      backgroundColor:
          Colors.black, // Background for areas not covered by camera
      body: SafeArea(
        child:
            _isCameraPermissionGranted
                ? _buildCameraPreview()
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _serverMessage,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: openAppSettings,
                        child: Text("Open Settings"),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

// Example of how to navigate to this screen:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => ExercisePerform(
//       targetReps: 10,
//       initialExerciseType: "squat",
//     ),
//   ),
// ).then((result) {
//   if (result != null && result is Map) {
//     int achievedReps = result['reps'];
//     bool completed = result['completed'];
//     print("Exercise session ended. Achieved reps: $achievedReps, Completed: $completed");
//     // Handle the result, e.g., show a summary
//   }
// });
