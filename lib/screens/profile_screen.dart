import 'package:flutter/material.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
import 'package:tiktok_clone/screens/login_screen.dart'; // สำคัญ: ตรวจสอบพาธนี้!
import 'package:video_player/video_player.dart'; // สำหรับเล่นวิดีโอใน thumbnail

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _videosFuture;
  // เพิ่ม Future สำหรับดึงข้อมูลโปรไฟล์
  late Future<Map<String, dynamic>?> _profileFuture;
  final user = supabase.auth.currentUser; // ผู้ใช้ปัจจุบันที่ล็อกอินอยู่

  @override
  void initState() {
    super.initState();
    // ตรวจสอบว่า user ไม่เป็น null ก่อนที่จะพยายามดึงข้อมูล
    if (user != null) {
      // ดึงวิดีโอที่ผู้ใช้อัปโหลด
      _videosFuture = supabase
          .from('videos')
          .select()
          .eq('user_id', user!.id)
          .order('created_at', ascending: false);

      // ดึงข้อมูลโปรไฟล์ของผู้ใช้จากตาราง 'profiles'
      _profileFuture = _fetchUserProfile(user!.id);
    } else {
      // หาก user เป็น null ให้ตั้งค่า Future เป็นค่าว่างเพื่อป้องกันข้อผิดพลาด
      _videosFuture = Future.value([]);
      _profileFuture = Future.value(null);
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์
  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('username, avatar_url') // เลือกคอลัมน์ที่ต้องการ
          .eq('id', userId)
          .single(); // คาดหวังผลลัพธ์เดียว

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in to view your profile.'));
    }

    return Scaffold(
      appBar: AppBar(
        // ใช้ FutureBuilder เพื่อแสดง username ที่ดึงมาจากตาราง profiles
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading Profile...');
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              debugPrint('Error or no profile data: ${snapshot.error}');
              return Text(
                  '@${user!.email?.split('@')[0] ?? 'Profile'}'); // Fallback to email
            }
            final username = snapshot.data!['username'] as String?;
            return Text(
                '@${username ?? user!.email?.split('@')[0] ?? 'Profile'}');
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Header (Avatar, stats)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // ใช้ FutureBuilder สำหรับ CircleAvatar เพื่อแสดง avatar_url หรือตัวอักษรแรกของ username
                FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    String displayChar = '?';
                    String? avatarUrl;
                    if (snapshot.hasData && snapshot.data != null) {
                      final username = snapshot.data!['username'] as String?;
                      avatarUrl = snapshot.data!['avatar_url'] as String?;
                      if (username != null && username.isNotEmpty) {
                        displayChar = username[0].toUpperCase();
                      } else if (user!.email != null &&
                          user!.email!.isNotEmpty) {
                        displayChar = user!.email![0].toUpperCase();
                      }
                    } else if (user!.email != null && user!.email!.isNotEmpty) {
                      displayChar = user!.email![0].toUpperCase();
                    }

                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl) as ImageProvider<Object>?
                          : null, // แสดงรูปภาพถ้ามี
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              displayChar,
                              style: const TextStyle(
                                  fontSize: 40, color: Colors.white),
                            )
                          : null, // ถ้ามีรูปภาพ ไม่ต้องแสดงตัวอักษร
                    );
                  },
                ),
                const SizedBox(width: 20),
                // แสดงจำนวนวิดีโอจริง
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _videosFuture,
                  builder: (context, snapshot) {
                    final videoCount = snapshot.data?.length ?? 0;
                    return Column(
                      children: [
                        Text(
                          '$videoCount', // แสดงจำนวนวิดีโอที่อัปโหลดจริง
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('Videos'),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 20),
                const Column(
                  children: [
                    Text(
                      '1.5M', // Placeholder: ควรดึงจำนวนผู้ติดตามจริงจาก Supabase
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text('Followers'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Videos Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Error fetching user videos: ${snapshot.error}');
                  return Center(
                      child: Text('Error loading videos: ${snapshot.error}'));
                }
                final videos = snapshot.data;
                if (videos == null || videos.isEmpty) {
                  return const Center(
                    child: Text('You have not uploaded any videos.'),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 9 / 16,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final videoUrl = videos[index]['video_url'] as String?;
                    if (videoUrl == null) {
                      return Container(
                          color: Colors.red,
                          child: const Center(child: Text('No URL')));
                    }
                    return GridTile(
                      child: _VideoThumbnail(
                        videoUrl: videoUrl,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget ขนาดเล็กสำหรับแสดง Video Thumbnail (โค้ดเดิม ไม่เปลี่ยนแปลง)
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      }).catchError((error) {
        debugPrint(
            'Error initializing video player for ${widget.videoUrl}: $error');
        if (mounted) {
          setState(() {
            _initialized = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: _controller.value.hasError
            ? const Icon(Icons.error_outline, color: Colors.red, size: 40)
            : const Center(child: CircularProgressIndicator()),
      );
    }
  }
}
