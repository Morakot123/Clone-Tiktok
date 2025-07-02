import 'package:flutter/material.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
// ***** สำคัญ: ตรวจสอบพาธนี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
import 'package:tiktok_clone/screens/login_screen.dart';
import 'package:video_player/video_player.dart'; // สำหรับเล่นวิดีโอใน thumbnail
import 'package:image_picker/image_picker.dart'; // เพิ่ม import สำหรับ image_picker
import 'package:path/path.dart'
    as p; // เพิ่ม import สำหรับจัดการ path ของไฟล์ (เช่น นามสกุลไฟล์)
import 'dart:io'; // เพิ่ม import นี้สำหรับ File (ใช้กับ FileImage)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>>
      _videosFuture; // Future สำหรับข้อมูลวิดีโอของผู้ใช้
  late Future<Map<String, dynamic>?>
      _profileFuture; // Future สำหรับข้อมูลโปรไฟล์ของผู้ใช้
  Map<String, dynamic>?
      _currentProfileData; // ตัวแปร State เพื่อเก็บข้อมูลโปรไฟล์ที่โหลดมาแล้ว

  final user = supabase.auth.currentUser; // ผู้ใช้ปัจจุบันที่ล็อกอินอยู่

  final TextEditingController _usernameController =
      TextEditingController(); // Controller สำหรับช่องกรอก Username
  XFile?
      _selectedAvatar; // สำหรับเก็บรูป Avatar ที่เลือกจาก Gallery (แต่ยังไม่ได้อัปโหลด/บันทึก)

  @override
  void initState() {
    super.initState();
    _loadProfileAndVideos(); // โหลดข้อมูลโปรไฟล์และวิดีโอเมื่อ Widget ถูกสร้าง
  }

  // ฟังก์ชันสำหรับโหลดข้อมูลโปรไฟล์และวิดีโอของผู้ใช้
  Future<void> _loadProfileAndVideos() async {
    if (user != null) {
      // ดึงวิดีโอทั้งหมดที่ผู้ใช้ปัจจุบันอัปโหลด
      _videosFuture = supabase
          .from('videos')
          .select()
          .eq('user_id', user!.id) // กรองวิดีโอตาม user_id ของผู้ใช้ปัจจุบัน
          .order('created_at', ascending: false); // เรียงตามเวลาล่าสุด

      // ดึงข้อมูลโปรไฟล์ของผู้ใช้จากตาราง 'profiles'
      // รวมถึง followers_count และ following_count
      _profileFuture = supabase
          .from('profiles')
          .select('username, avatar_url, followers_count, following_count')
          .eq('id', user!.id)
          .single(); // คาดหวังผลลัพธ์เดียวสำหรับโปรไฟล์ผู้ใช้

      // เมื่อ Future ของโปรไฟล์เสร็จสิ้น (ไม่ว่าจะสำเร็จหรือล้มเหลว)
      _profileFuture.then((profileData) {
        if (mounted) {
          setState(() {
            _currentProfileData = profileData; // อัปเดตข้อมูลโปรไฟล์ที่โหลดมา
            // ตั้งค่าค่าเริ่มต้นของ TextField ด้วย username ปัจจุบัน
            _usernameController.text =
                profileData?['username'] as String? ?? '';
            // รีเซ็ต _selectedAvatar เมื่อโหลดโปรไฟล์ใหม่ เพื่อไม่ให้รูปเก่าที่เลือกค้างอยู่
            _selectedAvatar = null;
          });
        }
      });
    } else {
      // หากผู้ใช้ไม่ได้ล็อกอิน ให้ตั้งค่า Future เป็นค่าว่างเปล่า
      _videosFuture = Future.value([]);
      _profileFuture = Future.value(null);
      if (mounted) {
        setState(() {
          _currentProfileData = null;
        });
      }
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์ (ใช้ภายใน _loadProfileAndVideos)
  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('username, avatar_url, followers_count, following_count')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // ฟังก์ชันสำหรับ Logout
  Future<void> _logout() async {
    await supabase.auth.signOut(); // ลงชื่อออกจาก Supabase
    if (mounted) {
      // นำทางกลับไปหน้า LoginScreen และล้าง Navigator stack ทั้งหมด
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // ลบทุกหน้าใน Stack
      );
    }
  }

  // ฟังก์ชันสำหรับเลือกรูปโปรไฟล์ (Avatar) จาก Gallery
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // อัปเดต _selectedAvatar แต่ยังไม่ setState ทันที
      // การ setState จะเกิดขึ้นใน setModalState() ของ StatefulBuilder ใน BottomSheet
      _selectedAvatar = pickedFile;
    }
  }

  // ฟังก์ชันสำหรับบันทึกการแก้ไขโปรไฟล์
  Future<void> _saveProfileChanges() async {
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ผู้ใช้ยังไม่ได้ล็อกอิน')),
        );
      }
      return;
    }

    String? newAvatarUrl;
    if (_selectedAvatar != null) {
      // อ่านไฟล์รูปภาพเป็น bytes
      final avatarBytes = await _selectedAvatar!.readAsBytes();
      // ดึงนามสกุลไฟล์
      final fileExtension = p.extension(_selectedAvatar!.path);
      // สร้างชื่อไฟล์ที่ไม่ซ้ำกันด้วย user ID และ timestamp
      final avatarFileName =
          '${user!.id}/${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      try {
        // อัปโหลดรูป Avatar ไปยัง Supabase Storage ใน Bucket 'avatars'
        await supabase.storage
            .from('avatars')
            .uploadBinary(avatarFileName, avatarBytes);
        // รับ Public URL ของรูปที่อัปโหลด
        newAvatarUrl =
            supabase.storage.from('avatars').getPublicUrl(avatarFileName);
      } catch (e) {
        debugPrint('Error uploading avatar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถอัปโหลดรูปโปรไฟล์ได้: $e')),
          );
        }
        return; // หยุดการทำงานหากอัปโหลดรูปไม่ได้
      }
    }

    try {
      // อัปเดตตาราง profiles ด้วย username ใหม่และ avatar_url ใหม่ (ถ้ามี)
      await supabase.from('profiles').update({
        'username':
            _usernameController.text.trim(), // trim() เพื่อลบช่องว่างหน้า/หลัง
        if (newAvatarUrl != null)
          'avatar_url':
              newAvatarUrl, // เพิ่ม avatar_url เฉพาะถ้ามีการอัปโหลดใหม่
      }).eq('id', user!.id); // อัปเดตเฉพาะโปรไฟล์ของ user_id ปัจจุบัน

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตโปรไฟล์สำเร็จ!')),
        );
        Navigator.of(context).pop(); // ปิด BottomSheet หลังจากบันทึก
        _loadProfileAndVideos(); // โหลดข้อมูลโปรไฟล์และวิดีโอใหม่เพื่อรีเฟรช UI
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถอัปเดตโปรไฟล์ได้: $e')),
        );
      }
    }
  }

  // ฟังก์ชันสำหรับแสดง BottomSheet แก้ไขโปรไฟล์
  void _showEditProfileSheet(Map<String, dynamic>? initialProfileData) {
    // ตั้งค่า TextEditingController ด้วย username ปัจจุบันเมื่อเปิด BottomSheet
    _usernameController.text = initialProfileData?['username'] as String? ?? '';
    // รีเซ็ต _selectedAvatar เมื่อเปิด BottomSheet เพื่อให้เริ่มต้นที่รูปเดิม
    _selectedAvatar = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // ทำให้ BottomSheet ขยายได้เต็มจอหากเนื้อหายาว (รองรับคีย์บอร์ด)
      builder: (context) {
        // StatefulBuilder ใช้เพื่อให้สามารถเรียก setState ภายใน BottomSheet ได้
        // โดยไม่จำเป็นต้อง setState ของ ProfileScreen ทั้งหมด
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String? currentAvatarUrl =
                initialProfileData?['avatar_url'] as String?;

            // Logic สำหรับการเลือก ImageProvider ที่จะใช้แสดงใน CircleAvatar
            ImageProvider<Object>? avatarImageProvider;
            if (_selectedAvatar != null) {
              // ถ้ามีการเลือกรูปใหม่จาก Gallery ให้ใช้ FileImage
              avatarImageProvider = FileImage(File(_selectedAvatar!.path));
            } else if (currentAvatarUrl != null &&
                currentAvatarUrl.isNotEmpty) {
              // ถ้ามี avatar_url เดิมจาก Supabase ให้ใช้ NetworkImage
              avatarImageProvider = NetworkImage(currentAvatarUrl);
            }
            // ถ้าไม่มีทั้งสองอย่าง avatarImageProvider จะยังคงเป็น null

            return Padding(
              // ปรับ Padding ด้านล่างเพื่อหลีกเลี่ยงคีย์บอร์ดบัง
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // ทำให้ Column มีขนาดเท่าที่จำเป็น
                children: [
                  Text(
                    'แก้ไขโปรไฟล์',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      await _pickAvatar(); // เรียกฟังก์ชันเลือกรูป
                      setModalState(
                          () {}); // อัปเดต UI ภายใน BottomSheet เพื่อแสดงรูปที่เลือก
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage:
                          avatarImageProvider, // ใช้ ImageProvider ที่เตรียมไว้
                      child: (avatarImageProvider == null)
                          ? const Icon(Icons.camera_alt,
                              size: 40,
                              color: Colors.white) // แสดงไอคอนกล้องถ้าไม่มีรูป
                          : null, // ถ้ามีรูป ไม่ต้องแสดงไอคอน
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller:
                        _usernameController, // ผูกกับ TextEditingController
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้',
                      border: OutlineInputBorder(), // ขอบรอบ TextField
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        _saveProfileChanges, // เรียกฟังก์ชันบันทึกการแก้ไข
                    child: const Text('บันทึกการเปลี่ยนแปลง'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController
        .dispose(); // เคลียร์ Controller เมื่อ Widget ถูก dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // แสดงข้อความหากผู้ใช้ไม่ได้ล็อกอิน
    if (user == null) {
      return const Center(child: Text('โปรดล็อกอินเพื่อดูโปรไฟล์ของคุณ'));
    }

    return Scaffold(
      appBar: AppBar(
        // ใช้ FutureBuilder เพื่อแสดง username ที่ดึงมาจากตาราง profiles
        title: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('กำลังโหลดโปรไฟล์...');
            }
            final currentProfileData = snapshot.data; // ดึงข้อมูลโปรไฟล์ที่นี่

            if (snapshot.hasError ||
                !snapshot.hasData ||
                currentProfileData == null) {
              debugPrint('Error or no profile data: ${snapshot.error}');
              // Fallback ไปใช้ชื่อจากอีเมลหากมีข้อผิดพลาดหรือไม่มีข้อมูลโปรไฟล์
              return Text('@${user!.email?.split('@')[0] ?? 'โปรไฟล์'}');
            }
            final username = currentProfileData['username'] as String?;
            return Text(
                '@${username ?? user!.email?.split('@')[0] ?? 'โปรไฟล์'}');
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout), // ปุ่ม Logout
        ],
      ),
      body: Column(
        children: [
          // ส่วนหัวของโปรไฟล์ (รูป Avatar, สถิติ)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // FutureBuilder สำหรับแสดง Avatar และจัดการการกดเพื่อแก้ไข
                FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    String displayChar =
                        '?'; // ตัวอักษรเริ่มต้นถ้าไม่มีรูป/ชื่อ
                    String? avatarUrl;
                    final currentProfileData =
                        snapshot.data; // ดึงข้อมูลโปรไฟล์ที่นี่

                    if (currentProfileData != null) {
                      final username =
                          currentProfileData['username'] as String?;
                      avatarUrl = currentProfileData['avatar_url'] as String?;
                      if (username != null && username.isNotEmpty) {
                        displayChar = username[0].toUpperCase();
                      } else if (user!.email != null &&
                          user!.email!.isNotEmpty) {
                        displayChar = user!.email![0].toUpperCase();
                      }
                    } else if (user!.email != null && user!.email!.isNotEmpty) {
                      displayChar = user!.email![0].toUpperCase();
                    }

                    // Logic สำหรับ ImageProvider ของ Avatar หลัก
                    ImageProvider<Object>? mainAvatarImageProvider;
                    if (avatarUrl != null && avatarUrl.isNotEmpty) {
                      mainAvatarImageProvider = NetworkImage(avatarUrl);
                    }

                    return GestureDetector(
                      onTap: () => _showEditProfileSheet(
                          _currentProfileData), // ส่งข้อมูลโปรไฟล์ไปให้ BottomSheet
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                            mainAvatarImageProvider, // ใช้ ImageProvider ที่เตรียมไว้
                        child: (mainAvatarImageProvider == null)
                            ? Text(
                                displayChar,
                                style: const TextStyle(
                                    fontSize: 40, color: Colors.white),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Followers Count
                FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    final followersCount =
                        snapshot.data?['followers_count'] ?? 0;
                    return Column(
                      children: [
                        Text(
                          '$followersCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('ผู้ติดตาม'),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Following Count
                FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    final followingCount =
                        snapshot.data?['following_count'] ?? 0;
                    return Column(
                      children: [
                        Text(
                          '$followingCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('กำลังติดตาม'),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Videos Count
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _videosFuture,
                  builder: (context, snapshot) {
                    final videoCount = snapshot.data?.length ?? 0;
                    return Column(
                      children: [
                        Text(
                          '$videoCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text('วิดีโอ'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // ปุ่มแก้ไขโปรไฟล์
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity, // ทำให้ปุ่มเต็มความกว้าง
              child: OutlinedButton(
                onPressed: () => _showEditProfileSheet(
                    _currentProfileData), // ส่งข้อมูลโปรไฟล์ที่โหลดแล้ว
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey), // ขอบสีเทา
                  foregroundColor: Colors.white, // สีข้อความ
                ),
                child: const Text('แก้ไขโปรไฟล์'),
              ),
            ),
          ),
          const Divider(), // เส้นแบ่ง

          // ส่วนแสดงวิดีโอ Grid
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
                      child:
                          Text('ข้อผิดพลาดในการโหลดวิดีโอ: ${snapshot.error}'));
                }
                final videos = snapshot.data;
                if (videos == null || videos.isEmpty) {
                  return const Center(
                    child: Text('คุณยังไม่ได้อัปโหลดวิดีโอใดๆ'),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // แสดง 3 คอลัมน์
                    childAspectRatio: 9 / 16, // อัตราส่วนเหมือนวิดีโอแนวตั้ง
                    crossAxisSpacing: 2, // ระยะห่างระหว่างคอลัมน์
                    mainAxisSpacing: 2, // ระยะห่างระหว่างแถว
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final videoUrl = videos[index]['video_url'] as String?;
                    if (videoUrl == null) {
                      return Container(
                          color: Colors.red,
                          child: const Center(child: Text('ไม่มี URL')));
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

// Widget ขนาดเล็กสำหรับแสดง Video Thumbnail ใน Grid
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  late VideoPlayerController _controller;
  bool _initialized = false; // ติดตามสถานะการเริ่มต้นของ VideoPlayer

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // ตรวจสอบว่า Widget ยังคง mounted ก่อนเรียก setState
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      }).catchError((error) {
        // จัดการข้อผิดพลาดในการเริ่มต้น VideoPlayer
        debugPrint(
            'Error initializing video player for ${widget.videoUrl}: $error');
        if (mounted) {
          setState(() {
            _initialized =
                false; // ทำเครื่องหมายว่าไม่สามารถเริ่มต้นได้หากมีข้อผิดพลาด
          });
        }
      });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // เคลียร์ทรัพยากรของ VideoPlayer เมื่อ Widget ถูก dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      // แสดงวิดีโอเมื่อ Player เริ่มต้นแล้ว
      return FittedBox(
        fit: BoxFit.cover, // ทำให้วิดีโอเต็มพื้นที่โดยรักษาสัดส่วน
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    } else {
      // แสดง placeholder (เช่น สีดำ หรือไอคอนข้อผิดพลาด) ขณะที่กำลังโหลด หรือโหลดไม่ได้
      return Container(
        color: Colors.black,
        child: _controller.value.hasError
            ? const Icon(Icons.error_outline,
                color: Colors.red, size: 40) // แสดงไอคอนข้อผิดพลาด
            : const Center(child: CircularProgressIndicator()), // แสดงโหลดดิ้ง
      );
    }
  }
}
