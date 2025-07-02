import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart'; // แพ็กเกจ UI สำหรับ Supabase Auth
import 'dart:async'; // สำหรับ StreamSubscription

// ***** สำคัญ: ตรวจสอบพาธนี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
import 'package:tiktok_clone/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // StreamSubscription สำหรับรับฟังการเปลี่ยนแปลงสถานะการยืนยันตัวตนของ Supabase
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // เริ่มรับฟังการเปลี่ยนแปลงสถานะการยืนยันตัวตน
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event =
          data.event; // เหตุการณ์ที่เกิดขึ้น (เช่น signedIn, signedOut)
      if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้งาน BuildContext

      // หากผู้ใช้ลงชื่อเข้าใช้สำเร็จ (signedIn) ให้นำทางไปยัง MainScreen
      if (event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel(); // ยกเลิกการรับฟังเมื่อ Widget ถูก dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ / สมัครสมาชิก')),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // เพิ่ม Padding รอบๆ เนื้อหา
        children: [
          // Widget สำหรับการยืนยันตัวตนด้วยอีเมลจาก Supabase Auth UI
          SupaEmailAuth(
            onSignInComplete: (response) {
              // สามารถเพิ่ม logic หลังการลงชื่อเข้าใช้สำเร็จที่นี่ได้ (เช่น แสดงข้อความต้อนรับ)
              debugPrint('ลงชื่อเข้าใช้สำเร็จ: ${response.user?.email}');
            },
            onSignUpComplete: (response) {
              // สามารถเพิ่ม logic หลังการสมัครสมาชิกสำเร็จที่นี่ได้
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('สมัครสมาชิกสำเร็จ! โปรดตรวจสอบอีเมลเพื่อยืนยัน'),
                  ),
                );
              }
              debugPrint('สมัครสมาชิกสำเร็จ: ${response.user?.email}');
            },
            // เพิ่มช่องสำหรับกรอก Username ในหน้าสมัครสมาชิก
            metadataFields: [
              MetaDataField(
                prefixIcon: const Icon(Icons.person), // ไอคอนรูปคน
                label: 'ชื่อผู้ใช้ (Username)', // Label สำหรับช่องกรอก
                key: 'username', // Key ที่จะใช้ส่งค่าไป Supabase (ใน metadata)
              ),
            ],
          ),
          const Divider(), // เส้นแบ่ง

          // Widget สำหรับการยืนยันตัวตนด้วย Social Providers (Google, GitHub)
          SupaSocialsAuth(
            socialProviders: const [
              OAuthProvider.google, // เปิดใช้งาน Google OAuth
              OAuthProvider.github, // เปิดใช้งาน GitHub OAuth
            ],
            onSuccess: (session) {
              // การนำทางจะถูกจัดการโดย _authStateSubscription เมื่อผู้ใช้ลงชื่อเข้าใช้สำเร็จ
              debugPrint('Social Login สำเร็จ: ${session.user?.email}');
            },
            // คุณอาจต้องกำหนด redirectUrl และตั้งค่าใน Supabase Console สำหรับ Social Login
            // ตัวอย่าง: redirectUrl: 'io.supabase.flutter://login-callback'
          ),
        ],
      ),
    );
  }
}
