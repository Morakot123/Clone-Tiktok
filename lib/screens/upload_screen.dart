// ไม่ต้อง import 'dart:io'; เพราะไม่ได้ใช้งานโดยตรง
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_clone/main.dart'; // เพื่อเข้าถึง supabase client

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  XFile? _videoFile;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    // ตรวจสอบ mounted ก่อนเรียก setState หลัง async operation
    if (!mounted) return;
    setState(() {
      _videoFile = pickedFile;
    });
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video first')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not authenticated";

      final videoBytes = await _videoFile!.readAsBytes();
      final videoPath = _videoFile!.path;
      // สร้างชื่อไฟล์ที่ไม่ซ้ำกันด้วย user ID และ timestamp
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${videoPath.split('.').last}';

      // 1. อัปโหลดไปยัง Supabase Storage (Bucket 'videos')
      await supabase.storage.from('videos').uploadBinary(fileName, videoBytes);

      // 2. รับ Public URL ของวิดีโอที่อัปโหลด
      if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ context
      final videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);

      // 3. แทรกข้อมูลวิดีโอลงในตาราง 'videos' ในฐานข้อมูล
      await supabase.from('videos').insert({
        'user_id': user.id,
        'video_url': videoUrl,
        'description': _descriptionController.text,
        'username':
            user.email?.split('@')[0] ?? 'unknown', // ใช้ username จากอีเมล
      });

      if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );

      // ล้างข้อมูลหลังจากอัปโหลดสำเร็จ
      if (!mounted) return; // ตรวจสอบ mounted ก่อนเรียก setState
      setState(() {
        _videoFile = null;
        _descriptionController.clear();
      });
    } catch (e) {
      if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      debugPrint('Upload error: $e'); // ใช้ debugPrint
    } finally {
      if (!mounted) return; // ตรวจสอบ mounted ก่อนเรียก setState
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_videoFile == null)
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Pick Video from Gallery'),
              )
            else
              Column(
                children: [
                  Text('Selected: ${_videoFile!.name}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickVideo,
                    child: const Text('Pick another video'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter a short description for your video',
                border: OutlineInputBorder(),
              ),
              maxLines: 3, // อนุญาตให้ใส่หลายบรรทัด
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size.fromHeight(50), // ทำให้ปุ่มเต็มความกว้าง
                    ),
                    child: const Text(
                      'Upload',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
