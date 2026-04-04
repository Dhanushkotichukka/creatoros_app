import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/post_provider.dart';
import '../models/multi_post/platform_type.dart';

class PublishingProgressScreen extends StatefulWidget {
  final PostProvider provider;
  final bool isScheduling;

  const PublishingProgressScreen({
    Key? key, 
    required this.provider,
    this.isScheduling = false,
  }) : super(key: key);

  @override
  State<PublishingProgressScreen> createState() => _PublishingProgressScreenState();
}

class _PublishingProgressScreenState extends State<PublishingProgressScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  bool _isSuccess = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _simulatedProgressTimer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startPublishingProcess();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulatedProgressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPublishingProcess() async {
    setState(() {
      _progress = 0.05;
      _statusMessage = 'Uploading media to secure storage...';
      _isSuccess = false;
      _hasError = false;
    });

    // Simulate steady progress while waiting for the monolithic API call to finish
    _simulatedProgressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_progress < 0.85) {
        setState(() {
          _progress += 0.02;
          if (_progress > 0.3 && _progress < 0.6) {
             _statusMessage = 'Processing video format...';
          } else if (_progress >= 0.6) {
             _statusMessage = widget.isScheduling 
                ? 'Registering your schedule with platforms...'
                : 'Pushing content directly to social platforms...';
          }
        });
      }
    });

    try {
      if (widget.isScheduling) {
        await widget.provider.schedulePost();
      } else {
        await widget.provider.publishNow();
      }

      // Automatically push to 100% on success
      _simulatedProgressTimer?.cancel();
      setState(() {
        _progress = 1.0;
        _isSuccess = true;
        _statusMessage = widget.isScheduling 
           ? 'Successfully Scheduled!' 
           : 'Successfully Published!';
      });
      _pulseController.stop();

    } catch (e) {
      _simulatedProgressTimer?.cancel();
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _statusMessage = 'Publishing Failed';
      });
      _pulseController.stop();
    }
  }

  IconData _getPlatformIcon(PlatformType type) {
    switch (type) {
      case PlatformType.youtube: return Icons.play_arrow;
      case PlatformType.instagram: return Icons.camera_alt;
      case PlatformType.linkedin: return Icons.work;
      case PlatformType.facebook: return Icons.facebook;
    }
  }

  Widget _buildPlatformIcons() {
    final connected = widget.provider.connectedPlatforms;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: connected.map((p) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 20,
            child: Icon(_getPlatformIcon(p), color: Colors.blueAccent, size: 20),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlatformData = widget.provider.activePost.platformData[widget.provider.selectedPlatform];
    final displayTitle = selectedPlatformData?.title.isNotEmpty == true 
        ? selectedPlatformData!.title 
        : widget.provider.activePost.title;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.isScheduling ? 'Scheduling Content' : 'Publishing Content'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent back button during upload if desired, or handle it manually
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Status Icon
                if (_hasError)
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 100)
                else if (_isSuccess)
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 100)
                else
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withOpacity(0.2),
                        border: Border.all(color: Colors.blueAccent, width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent, size: 50),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),

                // Video Title
                Text(
                  displayTitle.isNotEmpty ? displayTitle : 'Untitled Video',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Target Platforms Indicator
                const Text(
                  'Targeting platforms:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildPlatformIcons(),

                const SizedBox(height: 40),

                // Progress Bar or Error Message
                if (_hasError) ...[
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.redAccent.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                     ),
                     child: Text(
                       _errorMessage.isNotEmpty ? _errorMessage : 'An unknown error occurred during sync.',
                       style: const TextStyle(color: Colors.redAccent),
                       textAlign: TextAlign.center,
                     ),
                   ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade900,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_progress * 100).toInt()}% • $_statusMessage',
                    style: TextStyle(color: _isSuccess ? Colors.greenAccent : Colors.blueAccent, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 60),

                // Actions
                if (_isSuccess)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Return aggressively to the root videos/hub section
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Back to Videos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                else if (_hasError)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blueAccent,
                          ),
                          onPressed: _startPublishingProcess,
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () {
                       // Generally bad ux to cancel mid-flight HTTP request abruptly, but allowing soft pop
                       Navigator.pop(context);
                    },
                    child: const Text('Run in Background', style: TextStyle(color: Colors.grey)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
