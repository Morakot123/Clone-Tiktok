import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart'; // สำคัญ: ต้องมี import นี้
import 'dart:async'; // สำหรับ StreamSubscription

// ***** สำคัญ: ตรวจสอบพาธนี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
// ตัวอย่าง: import 'package:tiktok_clone/screen/main_screen.dart';
import 'package:tiktok_clone/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้งาน BuildContext

      if (event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Sign Up')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SupaEmailAuth(
            onSignInComplete: (response) {
              // สามารถเพิ่ม logic หลังการลงชื่อเข้าใช้สำเร็จที่นี่ได้
            },
            onSignUpComplete: (response) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Sign Up successful! Please check your email for verification.'),
                  ),
                );
              }
            },
            metadataFields: [
              MetaDataField(
                prefixIcon: const Icon(Icons.person),
                label: 'Username',
                key: 'username',
              ),
            ],
          ),
          const Divider(),
          SupaSocialsAuth(
            socialProviders: const [
              OAuthProvider.google,
              OAuthProvider.github,
            ],
            onSuccess: (session) {
              // onAuthStateChange จะจัดการการนำทาง
            },
            // คุณอาจต้องกำหนด redirectUrl และตั้งค่าใน Supabase Console
          ),
        ],
      ),
    );
  }
}
