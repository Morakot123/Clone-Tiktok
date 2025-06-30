import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // สำหรับ StreamSubscription

// ***** สำคัญ: ตรวจสอบพาธเหล่านี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
// ตัวอย่าง: import 'package:tiktok_clone/screen/login_screen.dart';
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
    _redirect();
  }

  Future<void> _redirect() async {
    // รอให้เฟรมแรก render เสร็จก่อน เพื่อให้ context พร้อมใช้งาน
    await Future.delayed(Duration.zero);

    // ตรวจสอบว่า Widget ยังคงอยู่ใน Widget tree หรือไม่ ก่อนใช้งาน context
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // ถ้ามี session (ล็อกอินอยู่) ให้ไปหน้าหลัก
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // ถ้าไม่มี session ให้ไปหน้าล็อกอิน
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
