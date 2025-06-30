import 'package:flutter/material.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
import 'package:tiktok_clone/widgets/video_card.dart'; // เพื่อแสดงผลวิดีโอแต่ละอัน

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>> _videosFuture;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchVideos();
  }

  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    // ดึงข้อมูลวิดีโอจากตาราง 'videos' ใน Supabase
    // ตรวจสอบชื่อตารางให้ตรงกับที่คุณตั้งค่าใน Supabase
    final response = await supabase
        .from('videos')
        .select()
        .order('created_at', ascending: false); // เรียงตามเวลาล่าสุด

    // ลบการ cast ที่ไม่จำเป็นออก (unnecessary_cast)
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // แสดงข้อผิดพลาดที่เฉพาะเจาะจงมากขึ้นเพื่อการดีบั๊ก
            debugPrint(
                'Error fetching videos: ${snapshot.error}'); // ใช้ debugPrint แทน print
            return Center(
                child: Text('Failed to load videos. Please try again later.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No videos found.'));
          }

          final videos = snapshot.data!;
          return PageView.builder(
            scrollDirection: Axis.vertical, // เลื่อนแนวตั้งเหมือน TikTok
            itemCount: videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return VideoCard(
                videoData: videos[index],
                isActive:
                    index == _currentPage, // ส่งสถานะ active ไปให้ VideoCard
              );
            },
          );
        },
      ),
    );
  }
}
