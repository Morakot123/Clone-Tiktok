import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiktok_clone/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pluxdpyopbzxarapmfah.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsdXhkcHlvcGJ6eGFyYXBtZmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyODg1NDQsImV4cCI6MjA2Njg2NDU0NH0.PAMZO-8ifHKFftfypNMfeCiSXGJwzx3d21fHG_0PE4I', // Supabase Anon Key ของคุณ
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Clone',
      // ใช้ Theme.dark() แล้วปรับแต่งเพิ่มเติมให้คล้าย TikTok
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // พื้นหลังหลักสีดำ
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black, // AppBar สีดำ
          elevation: 0, // ไม่มีเงาใต้ AppBar
          centerTitle: true, // จัด Title กลาง
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black, // Bottom Nav Bar สีดำ
          selectedItemColor: Colors.white, // ไอคอนที่เลือกสีขาว
          unselectedItemColor: Colors.grey, // ไอคอนที่ไม่ได้เลือกสีเทา
          type: BottomNavigationBarType.fixed, // ทำให้ไอคอนไม่ขยับเมื่อเลือก
        ),
        // ปรับ colorScheme เพื่อให้สีโดยรวมของแอปสอดคล้องกับ TikTok มากขึ้น
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.white, // สีหลัก เช่น TextFields, Icons
          secondary: const Color(
              0xFFFE2C55), // สีรอง เช่น ปุ่ม, Accent color (สีแดงชมพูของ TikTok)
          surface: Colors.black, // สีของพื้นผิว Widget ต่างๆ
          background: Colors.black, // สีพื้นหลัง
          error: Colors.red, // สีข้อผิดพลาด
          onPrimary: Colors.black, // สีของเนื้อหาบน primary
          onSecondary: Colors.white, // สีของเนื้อหาบน secondary
          onSurface: Colors.white, // สีของเนื้อหาบน surface
          onBackground: Colors.white, // สีของเนื้อหาบน background
          onError: Colors.white, // สีของเนื้อหาบน error
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false, // ซ่อนแบนเนอร์ "DEBUG"
    );
  }
}
