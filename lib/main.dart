import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ***** สำคัญ: ตรวจสอบพาธนี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
import 'package:tiktok_clone/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Project URL และ Anon Key ของคุณ
  // โปรดตรวจสอบให้แน่ใจว่า URL และ Anon Key ตรงกับโปรเจกต์ของคุณใน Supabase Dashboard
  await Supabase.initialize(
    url: 'https://pluxdpyopbzxarapmfah.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsdXhkcHlvcGJ6eGFyYXBtZmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyODg1NDQsImV4cCI6MjA2Njg2NDU0NH0.PAMZO-8ifHKFftfypNMfeCiSXGJwzx3d21fHG_0PE4I',
  );

  runApp(const MyApp());
}

// สร้างตัวแปร global เพื่อให้เข้าถึง Supabase client ได้ง่ายจากทั่วทั้งแอป
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Clone',
      // กำหนดธีมสีและสไตล์โดยรวมของแอป
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor:
            Colors.black, // สีพื้นหลังของ Scaffold ทั้งหมดเป็นสีดำ
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // สีของ AppBar เป็นสีดำ
          elevation: 0, // ไม่มีเงาใต้ AppBar
          centerTitle: true, // จัด Title ให้อยู่ตรงกลาง
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:
              Colors.black, // สีพื้นหลังของ Bottom Navigation Bar เป็นสีดำ
          selectedItemColor: Colors.white, // สีของไอคอน/ข้อความที่เลือก
          unselectedItemColor: Colors.grey, // สีของไอคอน/ข้อความที่ไม่ได้เลือก
          type: BottomNavigationBarType.fixed, // ทำให้ไอคอนมีขนาดคงที่
        ),
        // กำหนด ColorScheme สำหรับการใช้งานทั่วทั้งแอป
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.white, // สีหลัก
          secondary:
              const Color(0xFFFE2C55), // สีรอง (ใช้สำหรับสีแดงชมพูของ TikTok)
          surface: Colors.black, // สีพื้นผิว
          background: Colors.black, // สีพื้นหลัง
          error: Colors.red, // สีสำหรับแสดงข้อผิดพลาด
          onPrimary: Colors.black, // สีของข้อความ/ไอคอนบนสี Primary
          onSecondary: Colors.white, // สีของข้อความ/ไอคอนบนสี Secondary
          onSurface: Colors.white, // สีของข้อความ/ไอคอนบนสี Surface
          onBackground: Colors.white, // สีของข้อความ/ไอคอนบนสี Background
          onError: Colors.white, // สีของข้อความ/ไอคอนบนสี Error
        ),
      ),
      home: const SplashScreen(), // กำหนดหน้าจอแรกที่แอปจะแสดงเมื่อเริ่มต้น
      debugShowCheckedModeBanner: false, // ซ่อนแบนเนอร์ "DEBUG" ที่มุมขวาบน
    );
  }
}
