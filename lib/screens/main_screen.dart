import 'package:flutter/material.dart';
// ***** สำคัญ: ตรวจสอบพาธเหล่านี้! หากโฟลเดอร์ชื่อ 'screen' (เอกพจน์) ให้เปลี่ยนเป็น 'screen' *****
import 'package:tiktok_clone/screens/feed_screen.dart';
import 'package:tiktok_clone/screens/profile_screen.dart';
import 'package:tiktok_clone/screens/upload_screen.dart'; // สำหรับการนำทางไปหน้าอัปโหลด
import 'package:tiktok_clone/screens/shop_screen.dart'; // เพิ่ม import สำหรับ ShopScreen
import 'package:tiktok_clone/screens/message_screen.dart'; // เพิ่ม import สำหรับ MessageScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Index ของหน้าจอที่เลือกใน Bottom Navigation Bar

  // รายการ Widget ของหน้าจอต่างๆ ที่จะแสดงใน Bottom Navigation Bar
  // (หน้า UploadScreen จะถูกเปิดเป็นหน้าใหม่ ไม่ได้อยู่ในลิสต์นี้โดยตรง)
  final List<Widget> _pages = <Widget>[
    const FeedScreen(), // Index 0: หน้าหลัก (Feed)
    const ShopScreen(), // Index 1: หน้าจอร้านค้า
    const MessageScreen(), // Index 2: หน้าจอข้อความ
    const ProfileScreen(), // Index 3: หน้าจอโปรไฟล์ผู้ใช้
  ];

  // ฟังก์ชันที่ถูกเรียกเมื่อมีการแตะที่ Item ใน Bottom Navigation Bar
  void _onItemTapped(int index) {
    // หากกดปุ่ม + (ซึ่งมี index เป็น 2 ใน BottomNavigationBar UI) ให้นำทางไปหน้า UploadScreen
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const UploadScreen()),
      );
    } else {
      // สำหรับปุ่มอื่นๆ เราต้องปรับ index ให้ตรงกับ _pages list
      // Home (0) -> _pages[0]
      // Shop (1) -> _pages[1]
      // Messages (3) -> _pages[2] (เพราะ 2 ถูกข้ามไป)
      // Profile (4) -> _pages[3] (เพราะ 2 ถูกข้ามไป)
      setState(() {
        if (index < 2) {
          _selectedIndex = index;
        } else {
          _selectedIndex = index - 1; // ลบ 1 เพราะข้ามปุ่ม + ไป
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack ใช้เพื่อเก็บสถานะของหน้าจอต่างๆ เมื่อสลับไปมา
      // โดยจะแสดงเฉพาะ Widget ที่ index ตรงกับ _selectedIndex
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          // Item สำหรับหน้า Home
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'หน้าหลัก'),
          // Item สำหรับหน้า Shop
          const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'ร้านค้า'),
          // Item สำหรับปุ่ม + (อัปโหลด) ที่อยู่ตรงกลาง พร้อมดีไซน์พิเศษ
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 48, // กำหนดความกว้างของปุ่ม
              height: 32, // กำหนดความสูงของปุ่ม
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ชั้นล่างสุด (สีแดง) เลื่อนไปทางขวาเล็กน้อย
                  Positioned(
                    left: 2,
                    child: Container(
                      width: 44, // ความกว้างของแต่ละชั้น
                      height: 28, // ความสูงของแต่ละชั้น
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // ชั้นกลาง (สีฟ้า) เลื่อนไปทางซ้ายเล็กน้อย
                  Positioned(
                    right: 2,
                    child: Container(
                      width: 44,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // ชั้นบนสุด (สีขาว) พร้อมไอคอน +
                  Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 28),
                  ),
                ],
              ),
            ),
            label: '', // ไม่มีข้อความใต้ปุ่ม +
          ),
          // Item สำหรับหน้า Message
          const BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'ข้อความ'),
          // Item สำหรับหน้า Profile
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        // กำหนด currentIndex ให้ Bottom Navigation Bar UI
        // Home (0), Shop (1), Plus (2), Messages (3), Profile (4)
        currentIndex: _selectedIndex == 0
            ? 0
            : (_selectedIndex == 1
                ? 1
                : (_selectedIndex == 2
                    ? 3
                    : 4)), // ปรับ currentIndex ให้ตรงกับ UI
        selectedItemColor: Colors.white, // สีของไอคอนที่เลือก
        unselectedItemColor: Colors.grey, // สีของไอคอนที่ไม่ได้เลือก
        backgroundColor: Colors.black, // สีพื้นหลังของ Bottom Navigation Bar
        onTap: _onItemTapped, // กำหนดฟังก์ชันที่จะถูกเรียกเมื่อแตะ Item
        type: BottomNavigationBarType.fixed, // ทำให้ไอคอนมีขนาดคงที่
      ),
    );
  }
}
