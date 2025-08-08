import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Local imports
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SessionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onBack;

  const SessionDetailsScreen({
    Key? key,
    required this.patient,
    required this.onBack,
  }) : super(key: key);

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _physicalHealthController = TextEditingController();
  final TextEditingController _mentalHealthController = TextEditingController();
  final TextEditingController _medicationNotesController = TextEditingController();
  
  String? _selectedPrice;
  final List<String> _priceOptions = ['800', '1000', '1200'];
  final List<String> _imagePaths = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  // Voice recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRecorder();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_isRecording) {
        _stopRecording();
      }
      if (_isPlaying) {
        _stopPlaying();
      }
    }
  }
  
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    
    // No need to explicitly open the recorder in the latest version
    // It's initialized when needed
  }
  
  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      if (!await _requestMicrophonePermission()) {
        _showSnackBar('Microphone permission is required to record voice notes');
        return;
      }

      // Generate a unique filename with timestamp and patient ID
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final patientId = widget.patient['id']?.toString() ?? 'unknown';
      final filename = 'voice_note_${patientId}_$timestamp.m4a';
      
      String path;
      
      if (_isWeb()) {
        // For web, we'll use a temporary path
        path = 'voice_notes/$filename';
        debugPrint('Web recording path: $path');
        _showSnackBar('Recording will be saved in browser storage');
      } else {
        try {
          // Get the current working directory
          final currentDir = Directory.current.path;
          debugPrint('Current directory: $currentDir');
          
          // Go up one level from 'lib' to get project root
          final projectRoot = currentDir.replaceAll(RegExp(r'[\\/]lib.*'), '');
          debugPrint('Project root: $projectRoot');
          
          // Create recordings directory
          final recordingsDir = Directory('$projectRoot/recordings');
          debugPrint('Recordings directory path: ${recordingsDir.path}');
          
          // Create directory if it doesn't exist
          if (!await recordingsDir.exists()) {
            debugPrint('Creating recordings directory...');
            await recordingsDir.create(recursive: true);
            debugPrint('Directory created successfully');
          }
          
          // Verify directory exists
          final dirExists = await recordingsDir.exists();
          debugPrint('Directory exists after creation: $dirExists');
          
          if (!dirExists) {
            throw Exception('Failed to create recordings directory');
          }
          
          // Set the full file path
          path = '${recordingsDir.path}/$filename';
          final fullPath = path.replaceAll('\\', '/');
          
          debugPrint('Audio will be saved to: $fullPath');
          _showSnackBar('Audio will be saved to: $fullPath');
        } catch (e) {
          debugPrint('Error setting up recordings directory: $e');
          // Fallback to temporary directory if there's an error
          final tempDir = await getTemporaryDirectory();
          path = '${tempDir.path}/$filename';
          _showSnackBar('Using temporary directory: $path');
        }
      }
      
      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000, // 128 kbps
          sampleRate: 44100, // 44.1 kHz
        ),
        path: path,
      );
      
      setState(() {
        _isRecording = true;
        _audioPath = path;
        _recordDuration = Duration.zero;
        _currentPosition = Duration.zero;
      });
      
      // Update recording duration
      _updateRecordDuration();
      
      _showSnackBar('Recording started');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showSnackBar('Failed to start recording: ${e.toString()}');
    }
  }
  
  // Check if the platform is web
  bool _isWeb() {
    return identical(0, 0.0); // A simple way to detect web platform
  }

  // Helper method to get image bytes for web and mobile
  Future<Uint8List?> _getImageBytes(String imagePath) async {
    try {
      if (_isWeb()) {
        // For web, handle both blob: and data: URLs
        if (imagePath.startsWith('blob:')) {
          // Handle blob URL
          final response = await http.get(Uri.parse(imagePath));
          if (response.statusCode == 200) {
            return response.bodyBytes;
          }
        } else if (imagePath.startsWith('data:image')) {
          // Handle data URL
          final parts = imagePath.split(',');
          if (parts.length == 2) {
            return base64Decode(parts[1]);
          }
        }
        // If we get here, try to read as a file path (for web when using file picker)
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            return await file.readAsBytes();
          }
        } catch (e) {
          print('Error reading file on web: $e');
        }
      } else {
        // For mobile, read the file directly
        final file = File(imagePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      print('Error getting image bytes: $e');
      return null;
    }
  }

  // Convert file path to web-compatible URL if needed
  String _getImageUrl(String path) {
    if (_isWeb()) {
      // For web, return as is (it's already a web URL or data URL)
      return path;
    } else {
      // For mobile, return the file path
      return path;
    }
  }
  
  // Helper method to get content type from file extension
  MediaType _getContentTypeFromExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        // Default to jpeg if extension is not recognized
        return MediaType('image', 'jpeg');
    }
  }
  
  // Helper method to get MIME type for audio files
  MediaType _getAudioMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return MediaType('audio', 'mpeg');
      case '.wav':
        return MediaType('audio', 'wav');
      case '.aac':
        return MediaType('audio', 'aac');
      case '.m4a':
      case '.mp4':
        return MediaType('audio', 'mp4');
      case '.ogg':
        return MediaType('audio', 'ogg');
      case '.webm':
        return MediaType('audio', 'webm');
      default:
        // Default to m4a if extension is not recognized
        return MediaType('audio', 'm4a');
    }
  }
  
  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    try {
      if (_isWeb()) {
        // On web, we just return true as the browser will handle the permission
        return true;
      }
      
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;
      
      final result = await Permission.microphone.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return false;
    }
  }
  
  // Request storage permission (mobile only)
  Future<bool> _requestStoragePermission() async {
    try {
      if (_isWeb()) return true; // Not needed on web
      
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      final result = await Permission.storage.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }
  
  void _updateRecordDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
        _updateRecordDuration();
      }
    });
  }
  
  Future<void> _stopRecording() async {
    try {
      // Stop the recording and get the file path
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        if (!_isWeb()) {
          // For mobile, get file size using File API
          try {
            final file = File(path);
            final fileSize = await file.length();
            _showSnackBar('Recording saved: ${_formatFileSize(fileSize)}');
          } catch (e) {
            debugPrint('Error getting file size: $e');
            _showSnackBar('Recording saved');
          }
        } else {
          // For web, we don't need to access the file system
          _showSnackBar('Recording saved');
        }
        
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      } else {
        _showSnackBar('No recording data to save');
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showSnackBar('Failed to stop recording: ${e.toString()}');
    }
  }
  
  Future<void> _playRecording() async {
    if (_audioPath == null) return;
    
    try {
      if (_isWeb()) {
        // For web, use setUrl instead of setFilePath
        await _audioPlayer.setUrl(_audioPath!);
      } else {
        // For mobile, use setFilePath
        await _audioPlayer.setFilePath(_audioPath!);
      }
      
      await _audioPlayer.play();
      
      setState(() {
        _isPlaying = true;
      });
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }
        }
      });
      
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
      
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _showSnackBar('Failed to play recording: ${e.toString()}');
      
      // Reset playback state on error
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }
  
  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }
  
  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _notesController.dispose();
    _physicalHealthController.dispose();
    _mentalHealthController.dispose();
    _medicationNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPatientHeader(),
          _buildTabs(),
          Expanded(
            child: _buildCurrentTabContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF4F46E5)),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else if (widget.onBack != null) {
            widget.onBack();
          }
        },
        padding: const EdgeInsets.only(left: 16, right: 8),
      ),
      title: Text(
        'Session Details',
        style: GoogleFonts.inter(
          color: const Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: 64,
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x1F000000), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient['name'] ?? 'Patient Name',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.27,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.patient['age'] ?? ''} years • ${widget.patient['gender'] ?? ''}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontSize: 14,
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 12,
                height: 1.33,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'icon': Icons.favorite_border, 'label': 'Physical Health'},
      {'icon': Icons.psychology_outlined, 'label': 'Mental Health'},
      {'icon': Icons.medication_outlined, 'label': 'Medicines'},
      {'icon': Icons.mic_none, 'label': 'Voice Notes'},
    ];

    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return _buildTabItem(
            icon: tabs[index]['icon'] as IconData,
            label: tabs[index]['label'] as String,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
                  height: 1.42,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Physical Health
        return _buildPhysicalHealthTab();
      case 1: // Mental Health
        return _buildMentalHealthTab();
      case 2: // Medicines
        return _buildMedicinesTab();
      case 3: // Voice Notes
        return _buildVoiceNotesTab();
      default:
        return Container();
    }
  }

  Widget _buildPhysicalHealthTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Physical Health Issues',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF111827),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Write or draw physical health observations here. Your handwriting will be converted to text automatically...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(0),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthTab() {
    return _buildSectionTemplate(
      icon: Icons.psychology_outlined,
      title: 'Mental Health Observations',
      placeholder: 'Record your mental health observations here. Include mood, behavior, and any other relevant notes.',
    );
  }

  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    try {
      // Check and request storage permission for mobile
      if (!_isWeb()) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          _showSnackBar('Storage permission is required to upload images');
          return;
        }
      }

      // Show a bottom sheet to let user choose between camera and gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Reduce image quality to save space
        maxWidth: 1200,  // Limit image width
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          if (_isWeb()) {
            // For web, just use the temporary file path
            setState(() {
              _imagePaths.add(image.path);
              _showSnackBar('Image added successfully');
            });
          } else {
            // For mobile, save to app directory
            final appDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final ext = path.extension(image.path);
            final fileName = 'medicine_${widget.patient['id'] ?? 'unknown'}_$timestamp$ext';
            
            // Create a directory for medicine images if it doesn't exist
            final medicineDir = Directory('${appDir.path}/medicine_images');
            if (!await medicineDir.exists()) {
              await medicineDir.create(recursive: true);
            }
            
            final savedImagePath = '${medicineDir.path}/$fileName';
            final savedImage = await File(image.path).copy(savedImagePath);
            
            setState(() {
              _imagePaths.add(savedImage.path);
              _showSnackBar('Image added successfully');
            });
          }
        } catch (e) {
          _showSnackBar('Failed to process image: $e');
          debugPrint('Image processing error: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Failed to pick image: ${e.toString()}');
      debugPrint('Image picker error: $e');
    }
  }

  // Submit session details to the server
  Future<void> _submitSessionDetails() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the static getToken method directly on AuthService
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get session ID from patient data or use a default
      final sessionId = widget.patient['session_id']?.toString() ?? '7';
      
      // Log the data being sent for debugging
      print('Submitting session data for session ID: $sessionId');
      print('Physical Health Notes: ${_notesController.text}');
      print('Mental Health Notes: ${_mentalHealthController.text}');
      print('Medication Notes: ${_medicationNotesController.text}');
      print('Medicine Price: $_selectedPrice');
      print('Audio Path: $_audioPath');
      print('Image Paths: $_imagePaths');

      // Create the complete session data structure
      final sessionData = {
        'physical_health_notes': _notesController.text,
        'mental_health_notes': _mentalHealthController.text,
        'medicine_notes': _medicationNotesController.text,  // Changed from medication_notes to medicine_notes
        'medicine_price': _selectedPrice,
        'session_date': DateTime.now().toIso8601String(),
      };

      // Debug: Print the complete session data
      print('Session Data to be sent:');
      sessionData.forEach((key, value) {
        print('$key: ${value.toString()} (${value.runtimeType})');
      });

      final url = 'https://spandan.koptotech.solutions/api/sessions/$sessionId/complete';
      print('Sending request to: $url');
      
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);
      
      // Add form fields directly instead of nested JSON
      sessionData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      // Add token to headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add audio file if exists
      if (_audioPath != null && _audioPath!.isNotEmpty) {
        try {
          final audioFile = File(_audioPath!);
          if (await audioFile.exists()) {
            print('Adding audio file: ${audioFile.path}');
            
            // Get the file extension and determine MIME type
            final fileExt = path.extension(_audioPath!).toLowerCase();
            final mimeType = _getAudioMimeType(fileExt);
            
            // Create a unique filename with timestamp and patient ID
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final filename = 'voice_note_${widget.patient['id'] ?? 'unknown'}_$timestamp$fileExt';
            
            print('Audio file details:');
            print('  - Path: ${audioFile.path}');
            print('  - Size: ${(await audioFile.length()) / 1024} KB');
            print('  - MIME Type: ${mimeType.mimeType}');
            print('  - Uploading as: $filename');
            
            // Add the audio file to the request
            request.files.add(await http.MultipartFile.fromPath(
              'voice_notes',  // Changed from 'voice_notes_path' to 'voice_notes'
              audioFile.path,
              filename: filename,
              contentType: mimeType,
            ));
            
            print('Successfully added audio file to request');
          } else {
            final errorMsg = 'Audio file not found at path: ${audioFile.path}';
            print(errorMsg);
            _showSnackBar(errorMsg);
          }
        } catch (e, stackTrace) {
          final errorMsg = 'Error adding audio file: $e';
          print(errorMsg);
          print('Stack trace: $stackTrace');
          _showSnackBar('Error: Could not attach audio file');
        }
      } else {
        print('No audio file to upload');
      }

      // Add images if they exist
      print('\n=== PROCESSING ${_imagePaths.length} IMAGES ===');
      for (var i = 0; i < _imagePaths.length; i++) {
        try {
          final imagePath = _imagePaths[i];
          print('\n--- Processing image ${i + 1} of ${_imagePaths.length} ---');
          print('  - Original path: $imagePath');
          
          if (_isWeb()) {
            // For web, use bytes directly
            print('  - Platform: Web');
            print('  - Reading image bytes...');
            final stopwatch = Stopwatch()..start();
            final bytes = await _getImageBytes(imagePath);
            stopwatch.stop();
            
            if (bytes == null) {
              print('  ❌ Failed to read image bytes for web');
              print('  - Took: ${stopwatch.elapsedMilliseconds}ms');
              continue;
            }
            
            print('  ✅ Successfully read image data');
            print('  - Size: ${bytes.length} bytes');
            print('  - Took: ${stopwatch.elapsedMilliseconds}ms');
            
            final fileExt = path.extension(imagePath).toLowerCase();
            final contentType = _getContentTypeFromExtension(fileExt);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final filename = 'medicine_${widget.patient['id'] ?? 'unknown'}_${timestamp}_$i$fileExt';
            
            print('  - Preparing multipart file:');
            print('    - Filename: $filename');
            print('    - Content-Type: ${contentType.mimeType}');
            print('    - Field name: medicine_images[]');
            
            final fileField = http.MultipartFile.fromBytes(
              'medicine_images[]',
              bytes,
              filename: filename,
              contentType: contentType,
            );
            
            print('  - Adding file to request...');
            request.files.add(await fileField);
            print('  ✅ File added to request');
          } else {
            // For mobile, use file path
            print('  - Platform: Mobile');
            final imageFile = File(imagePath);
            final exists = await imageFile.exists();
            print('  - File exists: $exists');
            
            if (!exists) {
              print('  ❌ Image file not found at path: $imagePath');
              continue;
            }
            
            final fileExt = path.extension(imagePath).toLowerCase();
            final contentType = _getContentTypeFromExtension(fileExt);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final filename = 'medicine_${widget.patient['id'] ?? 'unknown'}_${timestamp}_$i$fileExt';
            final fileSize = await imageFile.length();
            
            print('  - Preparing multipart file:');
            print('    - Path: ${imageFile.path}');
            print('    - Filename: $filename');
            print('    - Size: $fileSize bytes');
            print('    - Content-Type: ${contentType.mimeType}');
            print('    - Field name: medicine_images[]');
            
            final fileField = http.MultipartFile.fromPath(
              'medicine_images[]',
              imageFile.path,
              filename: filename,
              contentType: contentType,
            );
            
            print('  - Adding file to request...');
            request.files.add(await fileField);
            print('  ✅ File added to request');
          }
          
        } catch (e, stackTrace) {
          print('❌ Error adding image file at index $i:');
          print('  - Path: ${_imagePaths[i]}');
          print('  - Error: $e');
          print('  - Stack trace: $stackTrace');
          _showSnackBar('Error adding image ${i + 1}: ${e.toString()}');
        }
      }

      // Print request details before sending
      print('\n=== REQUEST DETAILS ===');
      print('URL: ${request.url}');
      print('Method: ${request.method}');
      print('Headers:');
      request.headers.forEach((key, value) => print('  $key: $value'));
      print('\nFields:');
      request.fields.forEach((key, value) => print('  $key: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}${value.toString().length > 100 ? '...' : ''}'));
      print('\nFiles to upload: ${request.files.length}');
      for (var file in request.files) {
        print('  - ${file.filename} (${file.contentType})');
      }
      print('=====================\n');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        final responseData = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Session saved successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        // Error
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 
              'Failed to save session. Status: ${response.statusCode}');
        } catch (e) {
          throw Exception('Failed to save session. Status: ${response.statusCode}. ${response.body}');
        }
      }
    } catch (e) {
      _showSnackBar('Failed to save session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMedicinesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medication Details',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Notes Section - Moved to top
                Text(
                  'Medicine Notes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _medicationNotesController,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF111827),
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes about the medication...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Image Upload Section - Moved to middle
                Text(
                  'Upload Prescription/Medicine Images',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Image Grid
                _imagePaths.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_file, size: 48, color: Color(0xFF9CA3AF)),
                            const SizedBox(height: 12),
                            Text(
                              'Drag & drop images here or',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                              label: const Text('Browse Files'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supports JPG, PNG, GIF (Max 5MB each)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _imagePaths.length + (_imagePaths.length < 10 ? 1 : 0), // Max 10 images
                            itemBuilder: (context, index) {
                              if (index == _imagePaths.length) {
                                // Add Image Button
                                return GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined, 
                                            size: 24, color: Color(0xFF9CA3AF)),
                                        SizedBox(height: 4),
                                        Text('Add More', 
                                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // Display Selected Image
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _isWeb()
                                          ? Image.network(
                                              _imagePaths[index],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                                  ),
                                                );
                                              },
                                            )
                                          : Image.file(
                                              File(_imagePaths[index]),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _imagePaths.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, 
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${_imagePaths.length} of 10',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }
                            },
                          ),
                          if (_imagePaths.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${_imagePaths.length} ${_imagePaths.length == 1 ? 'image' : 'images'} selected',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                        ],
                      ),
                
                const SizedBox(height: 24),
                
                // Medicine Price Dropdown
                Text(
                  'Medicine Price (₹)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select price'),
                      value: _selectedPrice,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                      items: _priceOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('₹$value'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPrice = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNotesTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mic_none,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Voice Notes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the record button to start a new voice note. Tap again to stop.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4B5563),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Recording indicator and controls
                if (_isRecording || _audioPath != null)
                  _buildRecordingControls(),
                
                // Record button (centered)
                Center(
                  child: _isRecording || _audioPath != null 
                      ? const SizedBox.shrink() 
                      : _buildRecordButton(),
                ),
                
                // File info when recording exists
                if (_audioPath != null && !_isRecording)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recording saved:',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _audioPath!.split('/').last,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                
                // Transcription area (placeholder for now)
                const SizedBox(height: 24),
                Text(
                  'Transcription will appear here...',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : const Color(0xFF4F46E5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : const Color(0xFF4F46E5)).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
  
  Widget _buildRecordingControls() {
    return Column(
      children: [
        // Timer
        Text(
          _formatDuration(_isRecording ? _recordDuration : _currentPosition),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        if (_audioPath != null && !_isRecording) ...[
          const SizedBox(height: 8),
          Text(
            'File: ${_getDisplayPath(_audioPath!)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        
        // Play/Pause/Stop buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecording && _audioPath != null) ...[
              // Play/Pause button
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 48,
                  color: const Color(0xFF4F46E5),
                ),
                onPressed: _isPlaying ? _stopPlaying : _playRecording,
              ),
              
              // Stop button (only when playing)
              if (_isPlaying)
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle,
                    size: 48,
                    color: Colors.red,
                  ),
                  onPressed: _stopPlaying,
                ),
              
              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _audioPath = null;
                    _isPlaying = false;
                    _currentPosition = Duration.zero;
                  });
                },
              ),
            ] else if (_isRecording) ...[
              // Stop recording button
              IconButton(
                icon: const Icon(
                  Icons.stop_circle,
                  size: 48,
                  color: Colors.red,
                ),
                onPressed: _stopRecording,
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String _getDisplayPath(String path) {
    if (_isWeb()) {
      return 'Browser Storage: ${path.split('/').last}';
    }
    
    // For mobile, show a shorter path
    final parts = path.split('app_flutter');
    if (parts.length > 1) {
      return '.../app_flutter${parts[1]}';
    }
    return path;
  }
  
  Widget _buildSectionTemplate({
    required IconData icon,
    required String title,
    required String placeholder,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: title == 'Mental Health Observations' ? _mentalHealthController : null,
                maxLines: null,
                expands: true,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF111827),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _submitSessionDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            icon: const Icon(Icons.save, size: 18, color: Colors.white),
            label: Text(
              'Save Session',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.42,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}