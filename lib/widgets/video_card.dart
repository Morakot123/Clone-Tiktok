import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // สำคัญ: ต้องมี import นี้

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final bool isActive; // เพื่อควบคุมการเล่น/หยุดวิดีโอ

  const VideoCard({
    super.key,
    required this.videoData,
    this.isActive = false, // ค่าเริ่มต้นเป็น false
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false; // ติดตามสถานะการเริ่มต้นของ controller

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  // เมื่อข้อมูล videoData หรือ isActive เปลี่ยนแปลง
  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoData['video_url'] != widget.videoData['video_url']) {
      // หาก URL วิดีโอเปลี่ยน ให้เริ่มต้น controller ใหม่
      _controller.dispose();
      _initializeVideoPlayer();
    } else if (oldWidget.isActive != widget.isActive) {
      // หากสถานะ isActive เปลี่ยนแปลง
      if (widget.isActive) {
        _controller.play(); // เล่นวิดีโอ
        _controller.setLooping(true); // เล่นซ้ำ
      } else {
        _controller.pause(); // หยุดวิดีโอ
        _controller.seekTo(Duration.zero); // กลับไปเริ่มต้น
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final videoUrl = widget.videoData['video_url'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) {
      debugPrint(
          'Video URL is null or empty for video: ${widget.videoData['id']}');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _controller.play();
          _controller.setLooping(true);
        }
      }
    } catch (e) {
      debugPrint(
          'Error initializing video player for ${widget.videoData['id']}: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: _controller.value.hasError
            ? const Icon(Icons.error_outline, color: Colors.red, size: 40)
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // วิดีโอเล่นเต็มหน้าจอ
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        // Overlay สำหรับข้อมูลผู้ใช้และปุ่มโต้ตอบ
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ข้อมูลผู้ใช้และคำบรรยาย
              Text(
                '@${widget.videoData['username'] ?? 'unknown'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.videoData['description'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // ปุ่ม Like/Comment/Share (วางด้านขวา)
        Positioned(
          right: 16,
          bottom: 100, // ปรับตำแหน่งตามต้องการ
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white, size: 30),
                onPressed: () {
                  // TODO: เพิ่ม logic สำหรับ Like
                  debugPrint('Like button pressed');
                },
              ),
              const Text('1.2M',
                  style: TextStyle(color: Colors.white)), // Placeholder
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white, size: 30),
                onPressed: () {
                  // TODO: เพิ่ม logic สำหรับ Comment
                  debugPrint('Comment button pressed');
                },
              ),
              const Text('50K',
                  style: TextStyle(color: Colors.white)), // Placeholder
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 30),
                onPressed: () {
                  // TODO: เพิ่ม logic สำหรับ Share
                  debugPrint('Share button pressed');
                },
              ),
              const Text('10K',
                  style: TextStyle(color: Colors.white)), // Placeholder
            ],
          ),
        ),
      ],
    );
  }
}
