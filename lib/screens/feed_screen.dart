import 'package:flutter/material.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
import 'package:tiktok_clone/widgets/video_card.dart'; // เพื่อแสดงผลวิดีโอแต่ละอัน

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>>
      _videosFuture; // Future สำหรับเก็บข้อมูลวิดีโอ
  int _currentPage = 0; // Index ของวิดีโอที่กำลังแสดงผลปัจจุบันใน PageView

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchVideos(); // เริ่มดึงข้อมูลวิดีโอเมื่อ Widget ถูกสร้าง
  }

  // ฟังก์ชันสำหรับดึงข้อมูลวิดีโอพร้อมข้อมูลโปรไฟล์ของผู้ใช้ที่อัปโหลด
  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    try {
      // ดึงข้อมูลจากตาราง 'videos' และทำการ Join กับตาราง 'profiles'
      // '*, profiles(username, avatar_url)' หมายถึง:
      // - '*' ดึงทุกคอลัมน์จากตาราง 'videos' (รวมถึง likes_count, comments_count)
      // - 'profiles(username, avatar_url)' ดึงเฉพาะคอลัมน์ 'username' และ 'avatar_url'
      //   จากตาราง 'profiles' ที่เชื่อมโยงกับ 'user_id' ในตาราง 'videos'
      final response = await supabase
          .from('videos')
          .select(
              '*, profiles(username, avatar_url)') // ทำการ Join เพื่อดึง username และ avatar_url
          .order('created_at',
              ascending: false); // เรียงตามเวลาล่าสุดที่อัปโหลด

      // Supabase จะคืนค่ามาในรูปแบบ List<Map<String, dynamic>>
      // โดยข้อมูล profiles จะอยู่ใน Map ย่อยภายใต้ key 'profiles'
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      debugPrint('Error fetching videos with profiles: $e');
      // ในกรณีเกิดข้อผิดพลาด ให้คืนค่าเป็น List ว่างเปล่า เพื่อไม่ให้แอป Crash
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // ทำให้ body ขยายไปอยู่ด้านหลัง AppBar (เพื่อให้วิดีโอเต็มจอ)
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // ตั้งค่าสีพื้นหลัง AppBar เป็นโปร่งใส
        elevation: 0, // ไม่มีเงาใต้ AppBar
        leading: IconButton(
          icon: const Icon(Icons.live_tv,
              color: Colors.white, size: 28), // ไอคอน Live
          onPressed: () {
            // TODO: เพิ่มฟังก์ชัน Live ที่นี่
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ฟังก์ชัน Live กำลังพัฒนา')),
            );
          },
        ),
        title: SingleChildScrollView(
          // ทำให้เมนูสามารถเลื่อนในแนวนอนได้
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment
                .center, // จัดตำแหน่งเมนูให้อยู่ตรงกลาง (ถ้ามีพื้นที่พอ)
            children: [
              _buildAppBarMenuItem(context, 'สำรวจ'),
              const SizedBox(width: 20), // ระยะห่างระหว่างเมนู
              _buildAppBarMenuItem(context, 'เพื่อน'),
              const SizedBox(width: 20),
              _buildAppBarMenuItem(context, 'กำลังติดตาม'),
              const SizedBox(width: 20),
              _buildAppBarMenuItem(context, 'สำหรับคุณ',
                  isSelected: true), // "สำหรับคุณ" ถูกเลือกเป็นค่าเริ่มต้น
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: Colors.white, size: 28), // ไอคอนค้นหา
            onPressed: () {
              // TODO: เพิ่มฟังก์ชันค้นหาที่นี่
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟังก์ชันค้นหากำลังพัฒนา')),
              );
            },
          ),
          const SizedBox(width: 8), // ระยะห่างจากขอบขวา
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _videosFuture, // กำหนด Future ที่จะรอผลลัพธ์
        builder: (context, snapshot) {
          // แสดง CircularProgressIndicator ขณะที่กำลังโหลดข้อมูล
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // แสดงข้อความข้อผิดพลาดหากเกิดปัญหาในการดึงข้อมูล
          if (snapshot.hasError) {
            debugPrint('Error fetching videos: ${snapshot.error}');
            return const Center(
                child: Text('ไม่สามารถโหลดวิดีโอได้ โปรดลองอีกครั้งในภายหลัง'));
          }
          // แสดงข้อความหากไม่มีข้อมูลวิดีโอ
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบวิดีโอ'));
          }

          final videos = snapshot.data!; // ดึงข้อมูลวิดีโอที่ได้มา

          // PageView.builder สำหรับการเลื่อนวิดีโอแบบ Infinite Scroll แนวตั้ง
          return PageView.builder(
            scrollDirection:
                Axis.vertical, // กำหนดให้เลื่อนในแนวตั้งเหมือน TikTok
            itemCount: videos.length, // จำนวนวิดีโอทั้งหมด
            onPageChanged: (index) {
              // อัปเดต _currentPage เมื่อมีการเลื่อนหน้า
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final videoData = videos[index]; // ข้อมูลวิดีโอปัจจุบัน
              // ดึงข้อมูลโปรไฟล์ที่ถูก Join มาจาก Supabase
              final profileData =
                  videoData['profiles'] as Map<String, dynamic>?;

              // สร้าง Map ใหม่ที่รวมข้อมูลทั้งหมดที่ VideoCard ต้องการ
              // Supabase จะส่งข้อมูล profiles มาเป็น Map ย่อยภายใต้ key 'profiles'
              // เราจึงต้องดึง username และ avatar_url ออกมาแล้วรวมกับ videoData หลัก
              final combinedVideoData = {
                ...videoData, // ข้อมูลเดิมจากตาราง videos (รวมถึง likes_count, comments_count)
                'username':
                    profileData?['username'], // username จากตาราง profiles
                'avatar_url':
                    profileData?['avatar_url'], // avatar_url จากตาราง profiles
              };

              // แสดงผล VideoCard สำหรับวิดีโอแต่ละอัน
              return VideoCard(
                videoData:
                    combinedVideoData, // ส่งข้อมูลที่รวมแล้วไปยัง VideoCard
                isActive: index ==
                    _currentPage, // ส่งสถานะ active ไปให้ VideoCard เพื่อควบคุมการเล่น/หยุดวิดีโอ
              );
            },
          );
        },
      ),
    );
  }

  // Helper Widget สำหรับสร้างแต่ละ Item ใน AppBar Menu
  Widget _buildAppBarMenuItem(BuildContext context, String text,
      {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        // TODO: เพิ่ม Logic สำหรับการสลับเนื้อหาหน้าจอตามเมนูที่เลือก
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกเมนู: $text')),
        );
      },
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // ทำให้ Column มีขนาดเล็กที่สุดเท่าที่จำเป็น
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey, // สีข้อความตามสถานะการเลือก
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal, // ตัวหนาถ้าถูกเลือก
              fontSize: 18,
            ),
          ),
          if (isSelected) // แสดงเส้นใต้ถ้าเมนูถูกเลือก
            Container(
              margin: const EdgeInsets.only(top: 4), // ระยะห่างจากข้อความ
              height: 3, // ความสูงของเส้นใต้
              width: 30, // ความกว้างของเส้นใต้
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary, // สีแดงชมพูของ TikTok
                borderRadius: BorderRadius.circular(1.5), // ขอบมนของเส้นใต้
              ),
            ),
        ],
      ),
    );
  }
}
