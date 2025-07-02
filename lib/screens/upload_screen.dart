import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // สำหรับเลือกรูปภาพ/วิดีโอจาก Gallery
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client
import 'package:video_player/video_player.dart'; // สำหรับเล่นพรีวิววิดีโอ (แก้ไข: ลบ ':' ออก)
import 'package:path/path.dart'
    as p; // สำหรับจัดการ path ของไฟล์ (เช่น นามสกุลไฟล์)
import 'dart:io'; // สำหรับ File (ใช้กับ VideoPlayerController.file)

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _videoFile; // เก็บไฟล์วิดีโอที่เลือก
  final TextEditingController _descriptionController =
      TextEditingController(); // Controller สำหรับช่องกรอกคำบรรยาย
  bool _isLoading = false; // สถานะการโหลด (กำลังอัปโหลด)
  VideoPlayerController?
      _videoPlayerController; // Controller สำหรับพรีวิววิดีโอ
  bool _isPlayerInitialized = false; // สถานะการเริ่มต้นของ VideoPlayer

  @override
  void dispose() {
    _descriptionController.dispose(); // เคลียร์ Controller
    _videoPlayerController
        ?.dispose(); // เคลียร์ VideoPlayerController หากมีอยู่
    super.dispose();
  }

  // ฟังก์ชันสำหรับเลือกวิดีโอจาก Gallery
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery); // เลือกวิดีโอจาก Gallery

    if (!mounted) return; // ตรวจสอบ mounted ก่อน setState

    if (pickedFile != null) {
      // Dispose controller เก่าถ้ามีอยู่ เพื่อป้องกันการชนกันของทรัพยากร
      _videoPlayerController?.dispose();
      _isPlayerInitialized = false; // ตั้งค่าสถานะเป็น false ก่อนเริ่มต้นใหม่

      // สร้าง VideoPlayerController ใหม่จากไฟล์ที่เลือก
      _videoPlayerController =
          VideoPlayerController.file(File(pickedFile.path));
      try {
        await _videoPlayerController!.initialize(); // เริ่มต้น VideoPlayer
        if (mounted) {
          setState(() {
            _videoFile = pickedFile; // เก็บไฟล์วิดีโอที่เลือก
            _isPlayerInitialized = true; // ตั้งค่าสถานะว่า Player เริ่มต้นแล้ว
            _videoPlayerController!.play(); // เล่นพรีวิวอัตโนมัติ
            _videoPlayerController!.setLooping(true); // เล่นซ้ำ
          });
        }
      } catch (e) {
        debugPrint('Error initializing video player for preview: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถโหลดพรีวิววิดีโอได้: $e')),
          );
          setState(() {
            _videoFile = null; // ไม่แสดงวิดีโอถ้าโหลดพรีวิวไม่ได้
            _isPlayerInitialized = false;
          });
        }
      }
    } else {
      // ถ้าไม่ได้เลือกวิดีโอ ให้เคลียร์วิดีโอที่เคยเลือกไว้และ dispose controller
      setState(() {
        _videoFile = null;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
        _isPlayerInitialized = false;
      });
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดวิดีโอไปยัง Supabase
  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดเลือกวิดีโอก่อนอัปโหลด')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true); // แสดงโหลดดิ้ง

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "ผู้ใช้ยังไม่ได้ยืนยันตัวตน";

      final videoBytes =
          await _videoFile!.readAsBytes(); // อ่านไฟล์วิดีโอเป็น bytes
      final videoPath = _videoFile!.path;
      // สร้างชื่อไฟล์ที่ไม่ซ้ำกันด้วย user ID และ timestamp พร้อมนามสกุลไฟล์
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${p.extension(videoPath)}';

      // 1. อัปโหลดไฟล์วิดีโอไปยัง Supabase Storage (Bucket 'videos')
      await supabase.storage.from('videos').uploadBinary(fileName, videoBytes);

      if (!mounted) return;
      // 2. รับ Public URL ของวิดีโอที่อัปโหลด
      final videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);

      // 3. แทรกข้อมูลวิดีโอลงในตาราง 'videos' ในฐานข้อมูล Supabase
      await supabase.from('videos').insert({
        'user_id': user.id,
        'video_url': videoUrl,
        'description': _descriptionController.text,
        'username': user.email?.split('@')[0] ??
            'unknown', // ใช้ username จากอีเมล (หรือดึงจาก profiles ถ้าต้องการ)
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดวิดีโอสำเร็จ!')),
      );

      // ล้างข้อมูลและหยุดพรีวิวหลังจากอัปโหลดสำเร็จ
      if (!mounted) return;
      setState(() {
        _videoFile = null; // เคลียร์ไฟล์ที่เลือก
        _descriptionController.clear(); // ล้างช่องคำบรรยาย
        _videoPlayerController?.dispose(); // Dispose controller
        _videoPlayerController = null; // ตั้งค่าเป็น null
        _isPlayerInitialized = false; // ตั้งค่าสถานะเป็น false
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดล้มเหลว: $e')),
      );
      debugPrint('Upload error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false); // ซ่อนโหลดดิ้ง
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อัปโหลดวิดีโอ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แสดงพรีวิววิดีโอถ้ามีไฟล์ถูกเลือกและ Player เริ่มต้นแล้ว
            if (_videoFile != null &&
                _isPlayerInitialized &&
                _videoPlayerController != null)
              AspectRatio(
                aspectRatio: _videoPlayerController!
                    .value.aspectRatio, // ใช้อัตราส่วนของวิดีโอ
                child: VideoPlayer(_videoPlayerController!), // แสดง VideoPlayer
              )
            // แสดงโหลดดิ้งขณะที่กำลังเตรียมพรีวิว
            else if (_videoFile != null && !_isPlayerInitialized)
              const Center(child: CircularProgressIndicator())
            // แสดงปุ่มเลือกวิดีโอเมื่อยังไม่มีวิดีโอถูกเลือก หรือโหลดพรีวิวไม่ได้
            else
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('เลือกวิดีโอจากคลังภาพ'),
              ),

            // ปุ่ม "เลือกวิดีโออื่น" จะแสดงเมื่อมีวิดีโอถูกเลือกแล้ว
            if (_videoFile != null) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickVideo, // อนุญาตให้เลือกวิดีโอใหม่
                child: const Text('เลือกวิดีโออื่น'),
              ),
            ],

            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController, // ผูกกับ Controller
              decoration: const InputDecoration(
                labelText: 'คำบรรยาย',
                hintText: 'ใส่คำบรรยายสั้นๆ สำหรับวิดีโอของคุณ',
                border: OutlineInputBorder(), // ขอบรอบ TextField
              ),
              maxLines: 3, // อนุญาตให้ใส่หลายบรรทัด
            ),
            const SizedBox(height: 20),
            // ปุ่มอัปโหลด
            _isLoading
                ? const CircularProgressIndicator() // แสดงโหลดดิ้งเมื่อกำลังอัปโหลด
                : ElevatedButton(
                    onPressed: _uploadVideo, // เรียกฟังก์ชันอัปโหลด
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple, // สีพื้นหลังปุ่ม
                      foregroundColor: Colors.white, // สีข้อความปุ่ม
                      minimumSize:
                          const Size.fromHeight(50), // ทำให้ปุ่มเต็มความกว้าง
                    ),
                    child: const Text(
                      'อัปโหลด',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
