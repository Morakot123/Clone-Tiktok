import 'package:flutter/material.dart';
// ***** สำคัญ: ตรวจสอบพาธเหล่านี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
// ตัวอย่าง: import 'package:tiktok_clone/screen/feed_screen.dart';
import 'package:tiktok_clone/screens/feed_screen.dart';
import 'package:tiktok_clone/screens/profile_screen.dart';
import 'package:tiktok_clone/screens/upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // ลบ 'const' ออกจาก List declaration เพราะ Widgets ด้านในไม่ใช่ compile-time constants
  final List<Widget> _pages = <Widget>[
    const FeedScreen(), // เพิ่ม const ที่ constructor หากเป็น StatelessWidget หรือมี const constructor
    const UploadScreen(), // เพิ่ม const ที่ constructor
    const ProfileScreen(), // เพิ่ม const ที่ constructor
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
