import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
import 'package:tiktok_clone/screens/comments_sheet.dart'; // เพิ่ม import สำหรับ CommentsSheet
import 'package:share_plus/share_plus.dart'; // ***** เพิ่ม import สำหรับ share_plus *****

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final bool isActive;

  const VideoCard({
    super.key,
    required this.videoData,
    this.isActive = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLiked = false; // สถานะ Like ของผู้ใช้ปัจจุบัน
  int _likesCount = 0; // จำนวน Like ทั้งหมดของวิดีโอ
  int _commentsCount = 0; // จำนวน Comment ทั้งหมดของวิดีโอ

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _likesCount =
        widget.videoData['likes_count'] ?? 0; // ดึงจำนวน Like เริ่มต้น
    _commentsCount =
        widget.videoData['comments_count'] ?? 0; // ดึงจำนวน Comment เริ่มต้น
    _checkIfLiked(); // ตรวจสอบสถานะ Like ของผู้ใช้ปัจจุบัน
  }

  @override
  void didUpdateWidget(covariant VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoData['video_url'] != widget.videoData['video_url']) {
      _controller.dispose();
      _initializeVideoPlayer();
      _likesCount = widget.videoData['likes_count'] ?? 0; // อัปเดตจำนวน Like
      _commentsCount =
          widget.videoData['comments_count'] ?? 0; // อัปเดตจำนวน Comment
      _checkIfLiked(); // ตรวจสอบสถานะ Like ใหม่
    } else if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller.play();
        _controller.setLooping(true);
      } else {
        _controller.pause();
        _controller.seekTo(Duration.zero);
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

  // ฟังก์ชันตรวจสอบว่าผู้ใช้ปัจจุบันกด Like วิดีโอนี้แล้วหรือยัง
  Future<void> _checkIfLiked() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLiked = false);
      return;
    }

    try {
      final response = await supabase
          .from('likes')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('video_id', widget.videoData['id'])
          .limit(1);

      if (mounted) {
        setState(() {
          _isLiked = response.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking like status: $e');
      if (mounted) setState(() => _isLiked = false);
    }
  }

  // ฟังก์ชันสำหรับจัดการการกด Like/Unlike
  Future<void> _toggleLike() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to like videos.')),
        );
      }
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await supabase.from('likes').insert({
          'user_id': currentUser.id,
          'video_id': widget.videoData['id'],
        });
        await supabase.rpc('increment_likes_count',
            params: {'video_id_param': widget.videoData['id']});
      } else {
        await supabase
            .from('likes')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('video_id', widget.videoData['id']);
        await supabase.rpc('decrement_likes_count',
            params: {'video_id_param': widget.videoData['id']});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like status: $e')),
        );
      }
    }
  }

  // ฟังก์ชันสำหรับแสดง BottomSheet คอมเมนต์
  void _showCommentsSheet() {
    final videoId = widget.videoData['id'] as String?;
    if (videoId == null) {
      debugPrint('Video ID is null, cannot show comments.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ทำให้ BottomSheet ขยายได้เต็มจอ
      builder: (context) {
        return CommentsSheet(
          videoId: videoId,
          onCommentPosted: () {
            _fetchCommentsCount(); // เมื่อมีการโพสต์คอมเมนต์ใหม่ ให้รีเฟรชจำนวนคอมเมนต์
          },
        );
      },
    );
  }

  // ฟังก์ชันสำหรับแชร์วิดีโอ
  void _shareVideo() {
    final videoUrl = widget.videoData['video_url'] as String?;
    final description =
        widget.videoData['description'] as String? ?? 'Check out this video!';

    if (videoUrl != null && videoUrl.isNotEmpty) {
      Share.share('$description\n$videoUrl');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video URL not available for sharing.')),
        );
      }
    }
  }

  // ฟังก์ชันสำหรับดึงจำนวนคอมเมนต์ล่าสุด
  Future<void> _fetchCommentsCount() async {
    try {
      final response = await supabase
          .from('videos')
          .select('comments_count')
          .eq('id', widget.videoData['id'])
          .single();

      if (mounted) {
        setState(() {
          _commentsCount = response['comments_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments count: $e');
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying && _isInitialized)
            Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white.withOpacity(0.7),
                size: 80.0,
              ),
            ),
          Positioned(
            bottom: 100,
            left: 16,
            right: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${widget.videoData['username'] ?? 'unknown'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.videoData['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Original sound - ${widget.videoData['username'] ?? 'unknown'}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: widget.videoData['avatar_url'] != null &&
                          widget.videoData['avatar_url'].isNotEmpty
                      ? NetworkImage(widget.videoData['avatar_url'] as String)
                          as ImageProvider<Object>?
                      : null,
                  child: (widget.videoData['avatar_url'] == null ||
                          widget.videoData['avatar_url'].isEmpty)
                      ? Text(
                          widget.videoData['username'] != null &&
                                  widget.videoData['username'].isNotEmpty
                              ? widget.videoData['username'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 25, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isLiked
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.white,
                  label: 'Like',
                  count: _likesCount.toString(),
                  onPressed: _toggleLike,
                ),
                _buildActionButton(
                  icon: Icons.comment,
                  label: 'Comment',
                  count: _commentsCount.toString(),
                  onPressed: _showCommentsSheet,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  count:
                      '10K', // Placeholder: คุณสามารถเพิ่มการนับจำนวน Share ได้ในอนาคต
                  onPressed:
                      _shareVideo, // ***** เรียกฟังก์ชัน _shareVideo *****
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required String label,
    required String count,
    VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor, size: 30),
          onPressed: onPressed,
        ),
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 16),
      ],
    );
  }
}
