import 'package:flutter/material.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client

class CommentsSheet extends StatefulWidget {
  final String videoId; // รับ videoId เพื่อดึงคอมเมนต์ของวิดีโอนั้นๆ
  final VoidCallback?
      onCommentPosted; // เพิ่ม callback เมื่อโพสต์คอมเมนต์สำเร็จ

  const CommentsSheet({
    super.key,
    required this.videoId,
    this.onCommentPosted, // เพิ่มใน constructor
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับดึงคอมเมนต์ของวิดีโอ
  Future<List<Map<String, dynamic>>> _fetchComments() async {
    try {
      // ดึงคอมเมนต์จากตาราง 'comments' และ Join กับ 'profiles'
      // เพื่อดึง username และ avatar_url ของผู้คอมเมนต์
      final response = await supabase
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('video_id', widget.videoId)
          .order('created_at', ascending: true); // เรียงตามเวลาเก่าสุดไปใหม่สุด

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  // ฟังก์ชันสำหรับโพสต์คอมเมนต์ใหม่
  Future<void> _postComment() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to comment.')),
        );
      }
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment cannot be empty.')),
        );
      }
      return;
    }

    try {
      await supabase.from('comments').insert({
        'user_id': currentUser.id,
        'video_id': widget.videoId,
        'comment_text': _commentController.text.trim(),
      });

      // เรียก Supabase Function เพื่อเพิ่ม comments_count
      await supabase.rpc('increment_comments_count',
          params: {'video_id_param': widget.videoId});

      _commentController.clear(); // ล้างช่องคอมเมนต์
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
        setState(() {
          _commentsFuture = _fetchComments(); // รีเฟรชรายการคอมเมนต์
        });
        // เรียก callback เพื่อแจ้ง VideoCard ว่ามีการโพสต์คอมเมนต์ใหม่
        widget.onCommentPosted?.call();
      }
    } catch (e) {
      debugPrint('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height *
          0.7, // กำหนดความสูงของ BottomSheet
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black, // พื้นหลังสีดำ
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header ของ BottomSheet
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2.5),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Text(
            'Comments',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),

          // รายการคอมเมนต์
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Error loading comments: ${snapshot.error}');
                  return Center(
                      child: Text('Error loading comments: ${snapshot.error}'));
                }
                final comments = snapshot.data;
                if (comments == null || comments.isEmpty) {
                  return const Center(
                      child: Text('No comments yet. Be the first to comment!'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final profile =
                        comment['profiles'] as Map<String, dynamic>?;
                    final username =
                        profile?['username'] as String? ?? 'Anonymous';
                    final avatarUrl = profile?['avatar_url'] as String?;
                    final commentText =
                        comment['comment_text'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                        as ImageProvider<Object>?
                                    : null,
                            child: (avatarUrl == null || avatarUrl.isEmpty)
                                ? Text(
                                    username[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  commentText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${comment['created_at'].toString().substring(0, 10)}', // แสดงวันที่อย่างง่าย
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ช่องใส่คอมเมนต์และปุ่มส่ง
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context)
                  .viewInsets
                  .bottom, // ปรับให้คีย์บอร์ดไม่บัง
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send,
                      color: Theme.of(context).colorScheme.secondary),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
