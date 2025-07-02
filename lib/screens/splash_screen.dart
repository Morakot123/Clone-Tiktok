import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // สำหรับ StreamSubscription (แม้ว่าจะไม่ได้ใช้ StreamSubscription โดยตรงในโค้ดนี้ แต่เป็นไลบรารีที่เกี่ยวข้องกับ Future/async)

// ***** สำคัญ: ตรวจสอบพาธเหล่านี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
import 'package:tiktok_clone/screens/login_screen.dart';
import 'package:tiktok_clone/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect(); // เรียกฟังก์ชัน _redirect เมื่อ Widget ถูกสร้างขึ้น
  }

  // ฟังก์ชันสำหรับตรวจสอบสถานะการล็อกอินและนำทางผู้ใช้
  Future<void> _redirect() async {
    // รอให้เฟรมแรกของ UI render เสร็จก่อน เพื่อให้ BuildContext พร้อมใช้งาน
    await Future.delayed(Duration.zero);

    // ตรวจสอบว่า Widget ยังคงอยู่ใน Widget tree หรือไม่ ก่อนที่จะใช้งาน BuildContext
    // เพื่อป้องกันข้อผิดพลาด "setState() called on a disposed object"
    if (!mounted) return;

    // ดึง session ปัจจุบันจาก Supabase Authentication
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // ถ้ามี session (ผู้ใช้ล็อกอินอยู่) ให้นำทางไปยัง MainScreen
      // pushReplacement ใช้เพื่อแทนที่หน้าปัจจุบันใน Navigator stack
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // ถ้าไม่มี session (ผู้ใช้ยังไม่ได้ล็อกอิน) ให้นำทางไปยัง LoginScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดง CircularProgressIndicator ขณะที่กำลังตรวจสอบสถานะการล็อกอิน
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
