import 'dart:io';
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
  
  String? _selectedDose;
  final List<String> _doseOptions = ['800', '1000', '1200'];
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
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          RecordConfig(encoder: AudioEncoder.aacLc),
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
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showSnackBar('Failed to start recording');
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
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showSnackBar('Failed to stop recording');
    }
  }
  
  Future<void> _playRecording() async {
    if (_audioPath == null) return;
    
    try {
      await _audioPlayer.setFilePath(_audioPath!);
      await _audioPlayer.play();
      
      setState(() {
        _isPlaying = true;
      });
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
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
      _showSnackBar('Failed to play recording');
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
        onPressed: widget.onBack,
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
                child: Text(
                  'Remote Session',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.33,
                    letterSpacing: 0.2,
                  ),
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Get the application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(image.path);
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        setState(() {
          _imagePaths.add(savedImage.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
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

      // Get session ID from widget.patient or another source
      final sessionId = widget.patient['session_id'] as int?;
      if (sessionId == null) {
        throw Exception('Session ID is missing');
      }

      await ApiService.completeSession(
        sessionId: sessionId,
        token: token,
        physicalHealthNotes: _physicalHealthController.text,
        mentalHealthNotes: _mentalHealthController.text,
        medicationNotes: _medicationNotesController.text,
        selectedDosage: _selectedDose,
        imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
      );

      _showSnackBar('Session details saved successfully');
      
      // Optionally navigate back or show success message
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      _showSnackBar('Failed to save session details: $e');
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
                // Dosage Dropdown
                Text(
                  'Dosage (mg)',
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
                      hint: const Text('Select dosage'),
                      value: _selectedDose,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                      items: _doseOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('$value mg'),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDose = newValue;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Image Upload Section
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _imagePaths.length + 1, // +1 for the add button
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      // Add Image Button
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, 
                                  size: 32, color: Color(0xFF9CA3AF)),
                              SizedBox(height: 4),
                              Text('Add Image', 
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
                            child: Image.file(
                              File(_imagePaths[index]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
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
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Notes Section
                Text(
                  'Additional Notes',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
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
                // Recording indicator and controls
                if (_isRecording || _audioPath != null)
                  _buildRecordingControls(),
                  
                // Record button
                if (!_isRecording && _audioPath == null)
                  _buildRecordButton(),
                  
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
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
              child: Text(
                placeholder,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                  height: 1.5,
                ),
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
            onPressed: () {
              // Save session logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session saved successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              );
            },
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
