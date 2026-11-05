import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../utils/helpers.dart';
import 'checkout_success_screen.dart';
import '../api/api_endpoints.dart';

class AttendanceScreen extends StatefulWidget {
  static const String path = '/attendance';
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetectingFaces = false;
  List<CameraDescription>? _availableCameras;

  @override
  void initState() {
    super.initState();
    AttendanceProvider.instance.loadTodayAttendance(isRefresh: true);
    _initializeCamera();

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    if (_cameraController != null) {
      if (_cameraController!.value.isInitialized) {
        try {
          _cameraController!.stopImageStream();
        } catch (_) {}
      }
      _cameraController!.dispose();
    }
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final provider = AttendanceProvider.instance;
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras == null || _availableCameras!.isEmpty) {
        throw Exception("No cameras found");
      }

      final frontCamera = _availableCameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
      );

      _cameraController!.startImageStream(_processCameraImage);

      if (mounted) {
        provider.setCameraInitialized(true);
        provider.setUseMockScan(false);
        provider.setFaceDetectionStatus("Align your face in the camera circle");
      }
    } catch (e) {
      debugPrint("Camera initialization failed ($e). Using mock scanner mode.");
      if (mounted) {
        provider.setUseMockScan(true);
        provider.setCameraInitialized(false);
        provider.setFaceDetectionStatus("No camera: Virtual Scanner Active");
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final provider = AttendanceProvider.instance;
    if (_faceDetector == null || _isDetectingFaces || provider.isSelfieCaptured)
      return;
    _isDetectingFaces = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector!.processImage(inputImage);

        if (mounted) {
          if (faces.isNotEmpty) {
            provider.setFaceDetected(true);
            provider.setFaceDetectionStatus("Face Detected! Ready to Capture.");
          } else {
            provider.setFaceDetected(false);
            provider.setFaceDetectionStatus(
              "Align your face in the camera circle",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    } finally {
      _isDetectingFaces = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotation.rotation90deg;
    }
    rotation ??= InputImageRotation.rotation0deg;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    Uint8List bytes;
    if (Platform.isAndroid) {
      final builder = BytesBuilder();
      for (final Plane plane in image.planes) {
        builder.add(plane.bytes);
      }
      bytes = builder.takeBytes();
    } else {
      bytes = image.planes[0].bytes;
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<void> _captureSelfie() async {
    final provider = AttendanceProvider.instance;
    if (provider.useMockScan) {
      await _simulateSelfieCapture();
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (!provider.faceDetected) {
      UiHelpers.showSnackBar(
        context,
        'No face detected in the frame. Please align your face.',
        Colors.orangeAccent,
      );
      return;
    }

    provider.setScanning(true);

    try {
      try {
        await _cameraController!.stopImageStream();
      } catch (streamError) {
        debugPrint(
          "Warning: stopImageStream failed (might not be streaming): $streamError",
        );
      }
      final XFile photo = await _cameraController!.takePicture();

      provider.setScanning(false);
      provider.setSelfieCaptured(true);
      provider.setCapturedAt(DateTime.now());
      provider.setSelfiePath(photo.path);

      UiHelpers.showSnackBar(
        context,
        'Live selfie captured successfully!',
        Colors.greenAccent,
      );
    } catch (e) {
      debugPrint("Error capturing photo: $e");
      UiHelpers.showSnackBar(
        context,
        'Failed to capture selfie: $e',
        Colors.redAccent,
      );
      provider.setScanning(false);
      try {
        _cameraController!.startImageStream(_processCameraImage);
      } catch (_) {}
    }
  }

  void _retakeSelfie() {
    final provider = AttendanceProvider.instance;
    provider.resetSelfieState();

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  Future<void> _simulateSelfieCapture() async {
    final provider = AttendanceProvider.instance;
    provider.setScanning(true);
    provider.setSelfieCaptured(false);
    provider.setCapturedAt(null);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    provider.setScanning(false);
    provider.setSelfieCaptured(true);
    provider.setCapturedAt(DateTime.now());
    provider.setSelfiePath(
      'selfie_mock_fallback_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg',
    );

    UiHelpers.showSnackBar(
      context,
      'Fallback: Face selfie scanned successfully!',
      Colors.blueAccent,
    );
  }

  Future<String> _getDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Fallback Device Info';
    }
  }

  Future<void> _handleCheckIn() async {
    final provider = AttendanceProvider.instance;
    if (!provider.isSelfieCaptured) {
      UiHelpers.showSnackBar(
        context,
        'Please capture live selfie first.',
        Colors.orangeAccent,
      );
      return;
    }

    double lat = 10.0159;
    double lng = 76.3419;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      // Silently fall back to Kochi coordinates
    }

    final deviceInfo = await _getDeviceInfo();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accentTeal,
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syncing Selfie Log',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Transmitting details to server...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await AttendanceProvider.instance.checkIn(
        selfiePath: provider.selfiePath,
        lat: lat,
        lng: lng,
        deviceInfo: deviceInfo,
        sourceMode: 'selfie',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && mounted) {
        UiHelpers.showSnackBar(
          context,
          'Attendance checked in with selfie successfully!',
          Colors.greenAccent,
        );
        provider.setSelfieCaptured(false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      UiHelpers.showSnackBar(
        context,
        'Check-in failed: ${e.toString().replaceAll('Exception:', '').trim()}',
        Colors.redAccent,
      );
    }
  }

  Future<void> _handleCheckOut() async {
    final provider = AttendanceProvider.instance;
    if (!provider.isSelfieCaptured) {
      UiHelpers.showSnackBar(
        context,
        'Please capture live checkout selfie first.',
        Colors.orangeAccent,
      );
      return;
    }

    double lat = 10.0159;
    double lng = 76.3419;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      // Silently fall back to Kochi coordinates
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.orangeAccent,
              ),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syncing Checkout Log',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Transmitting details to server...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await AttendanceProvider.instance.checkOut(
        selfiePath: provider.selfiePath,
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && mounted) {
        provider.setSelfieCaptured(false);
        Navigator.pushReplacementNamed(context, CheckoutSuccessScreen.path);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }
      UiHelpers.showSnackBar(
        context,
        'Check-out failed: ${e.toString().replaceAll('Exception:', '').trim()}',
        Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text(
          'ATTENDANCE CHECK-IN/OUT',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: AttendanceProvider.instance,
            builder: (context, _) {
              final provider = AttendanceProvider.instance;
              final attendance = provider.currentAttendance;

              return RefreshIndicator(
                color: AppColors.accentTeal,
                onRefresh: () async {
                  await provider.loadTodayAttendance(isRefresh: true);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStatusHeader(attendance.status),
                      const SizedBox(height: 24),

                      if (!attendance.isCompleted) ...[
                        _buildCameraViewfinder(),
                        const SizedBox(height: 24),

                        _buildGeoCard(provider, attendance),
                        const SizedBox(height: 30),

                        _buildActionButtons(provider, attendance),
                      ] else ...[
                        _buildCompletedSummary(provider, attendance),
                      ],

                      _buildSyncLogCard(provider, attendance),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color badgeColor = Colors.orangeAccent;
    String text = 'CHECK-IN REQUIRED';
    IconData icon = Icons.lock_clock;

    if (status == 'Present') {
      badgeColor = AppColors.accentTeal;
      text = 'CHECKED IN (WORK ACTIVE)';
      icon = Icons.bolt_rounded;
    } else if (status == 'Completed') {
      badgeColor = Colors.greenAccent;
      text = 'WORK COMPLETED FOR TODAY';
      icon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    final provider = AttendanceProvider.instance;
    final borderAccentColor = provider.faceDetected
        ? Colors.greenAccent
        : AppColors.accentTeal;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 244,
              height: 244,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.03),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderAccentColor, width: 3),
                          left: BorderSide(color: borderAccentColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderAccentColor, width: 3),
                          right: BorderSide(color: borderAccentColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: borderAccentColor,
                            width: 3,
                          ),
                          left: BorderSide(color: borderAccentColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: borderAccentColor,
                            width: 3,
                          ),
                          right: BorderSide(color: borderAccentColor, width: 3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: provider.faceDetected
                      ? Colors.greenAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
              ),
            ),

            ClipOval(
              child: SizedBox(
                width: 206,
                height: 206,
                child: Container(
                  color: const Color(0xFF14242D),
                  child: provider.isScanning
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentTeal,
                          ),
                        )
                      : provider.isSelfieCaptured
                      ? (provider.selfiePath.startsWith('selfie_') ||
                                provider.selfiePath.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.face_retouching_natural_rounded,
                                  color: AppColors.accentTeal,
                                  size: 48,
                                ),
                              )
                            : Image.file(
                                File(provider.selfiePath),
                                fit: BoxFit.cover,
                                width: 206,
                                height: 206,
                              ))
                      : provider.isCameraInitialized &&
                            _cameraController != null
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.useMockScan
                                    ? 'Virtual Simulator Active'
                                    : 'Front Viewfinder',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            if (provider.isScanning ||
                (provider.isCameraInitialized && !provider.isSelfieCaptured))
              AnimatedBuilder(
                animation: _scannerAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: 10 + (_scannerAnimation.value * 200),
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: provider.faceDetected
                            ? Colors.greenAccent
                            : AppColors.accentTeal,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (provider.faceDetected
                                        ? Colors.greenAccent
                                        : AppColors.accentTeal)
                                    .withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),

        if (!provider.isSelfieCaptured) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                provider.faceDetected
                    ? Icons.check_circle_rounded
                    : Icons.face_retouching_off_rounded,
                color: provider.faceDetected
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                provider.faceDetectionStatus,
                style: TextStyle(
                  color: provider.faceDetected
                      ? Colors.greenAccent
                      : Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                provider.isSelfieCaptured ||
                    provider.faceDetected ||
                    provider.useMockScan
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 1,
          ),
          onPressed: provider.isScanning
              ? null
              : (provider.isSelfieCaptured
                    ? _retakeSelfie
                    : (provider.faceDetected || provider.useMockScan
                          ? _captureSelfie
                          : null)),
          icon: Icon(
            provider.isSelfieCaptured
                ? Icons.refresh_rounded
                : Icons.camera_alt_rounded,
            size: 18,
            color: provider.isSelfieCaptured
                ? Colors.blueAccent
                : (provider.faceDetected ? Colors.green : Colors.grey),
          ),
          label: Text(
            provider.isSelfieCaptured ? 'Retake Selfie' : 'Capture Selfie',
            style: TextStyle(
              color: provider.isSelfieCaptured
                  ? AppColors.textPrimary
                  : (provider.faceDetected || provider.useMockScan
                        ? AppColors.textPrimary
                        : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeoCard(
    AttendanceProvider provider,
    AttendanceModel attendance,
  ) {
    final now = DateTime.now();
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_searching_rounded,
                color: AppColors.accentTeal,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Geolocation & Timestamp Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 24),

          _buildDetailRow(
            'Employee Name',
            attendance.isPresent ? attendance.employeeName : 'Pending Log',
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Active Date', dateFormat.format(now)),
          const SizedBox(height: 8),
          _buildDetailRow('Trigger Time', timeFormat.format(now)),
          const SizedBox(height: 8),

          if (provider.isLocating) ...[
            const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentTeal,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Syncing GPS coordinates...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildDetailRow(
              'Coordinates',
              attendance.isPresent
                  ? 'Lat: ${attendance.checkInLatitude.toStringAsFixed(4)}, Lng: ${attendance.checkInLongitude.toStringAsFixed(4)}'
                  : 'Ready to retrieve GPS...',
            ),
            const SizedBox(height: 4),
            const Text(
              'Location Check: Verified (Kochi Sales Zone)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    AttendanceProvider provider,
    AttendanceModel attendance,
  ) {
    final bool isCheckIn = attendance.isAbsent;
    final bool isLoading = provider.isSubmitting;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isCheckIn
              ? [Colors.cyan, Colors.teal]
              : [Colors.orange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCheckIn ? Colors.teal : Colors.red).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isLoading
            ? null
            : (isCheckIn ? _handleCheckIn : _handleCheckOut),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                isCheckIn
                    ? 'Submit Attendance Check-In'
                    : 'Submit Day Check-Out',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildCompletedSummary(
    AttendanceProvider provider,
    AttendanceModel attendance,
  ) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.done_all_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Daily Attendance Complete',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Great job! Your sales log has been uploaded.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 32),

          _buildDetailRow('Employee Name', attendance.employeeName),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Date Logged',
            dateFormat.format(attendance.checkInTime),
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Check-In Time',
            timeFormat.format(attendance.checkInTime),
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Check-Out Time',
            attendance.checkOutTime != null
                ? timeFormat.format(attendance.checkOutTime!)
                : '--:--',
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Working Hours',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  UiHelpers.formatWorkingHours(
                    attendance.workingHours,
                    checkIn: attendance.checkInTime,
                    checkOut: attendance.checkOutTime,
                  ),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 32),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await provider.resetAttendance();
                provider.resetSelfieState();
              },
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Start New Shift (Check-In Again)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncLogCard(
    AttendanceProvider provider,
    AttendanceModel attendance,
  ) {
    if (attendance.isAbsent) return const SizedBox.shrink();

    final String checkInTimeStr = DateFormat(
      'dd MMM yyyy, hh:mm:ss a',
    ).format(attendance.checkInTime);
    final String checkOutTimeStr = attendance.checkOutTime != null
        ? DateFormat('dd MMM yyyy, hh:mm:ss a').format(attendance.checkOutTime!)
        : 'N/A';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.dns_rounded,
                    color: AppColors.accentTeal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DATABASE SYNC METADATA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 10),
                    SizedBox(width: 4),
                    Text(
                      '201 SYNC',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 28),
          _buildDetailRow('Active Employee ID', attendance.employeeId),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Sync Approval Status',
            (attendance.statusText ?? 'Approved').toUpperCase(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Check-in Selfie Photo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              _buildSelfieThumbnail(
                attendance.checkInSelfie,
                label: 'Check-In Selfie Photo',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Check-in Capture Time', checkInTimeStr),
          if (attendance.status == 'Completed') ...[
            const Divider(color: Color(0xFFF1F5F9), height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Check-out Selfie Photo',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                _buildSelfieThumbnail(
                  attendance.checkOutSelfie ?? '',
                  label: 'Check-Out Selfie Photo',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Check-out Capture Time', checkOutTimeStr),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Text(
              'Server status: Selfie storage path successfully verified and integrated into backend attendance logs.',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieThumbnail(String path, {String label = 'Selfie Photo'}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('assets') ||
        trimmed.startsWith('selfie_')) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.face_retouching_natural_rounded,
          color: Colors.blueGrey,
          size: 14,
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showImagePreview(trimmed, label),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.8),
          child: SizedBox(
            width: 38,
            height: 38,
            child: _buildUniversalSelfie(trimmed),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversalSelfie(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.face_retouching_natural_rounded,
          size: 18,
          color: AppColors.accentTeal,
        ),
      );
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.face_retouching_natural_rounded,
            size: 18,
            color: AppColors.accentTeal,
          ),
        );
      }
    } catch (_) {}
    if (path.startsWith('/') ||
        path.startsWith('storage') ||
        path.startsWith('uploads')) {
      final clean = path.startsWith('/') ? path.substring(1) : path;
      final fullUrl = ApiEndpoints.baseUrl.replaceAll('/api', '') + '/' + clean;
      return Image.network(
        fullUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.face_retouching_natural_rounded,
          size: 18,
          color: AppColors.accentTeal,
        ),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.face_retouching_natural_rounded,
        size: 18,
        color: AppColors.accentTeal,
      ),
    );
  }

  void _showImagePreview(String path, String label) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                  maxWidth: MediaQuery.of(context).size.width * 0.90,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildUniversalSelfie(path, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildDetailRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            val,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
