import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // ตั้งค่าสีพื้นหลัง AppBar เป็นสีดำ
        elevation: 0, // ไม่มีเงาใต้ AppBar
        leading: IconButton(
          icon: const Icon(Icons.live_tv, color: Colors.white), // ไอคอน Live
          onPressed: () {
            // TODO: เพิ่มฟังก์ชัน Live ที่นี่
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ฟังก์ชัน Live กำลังพัฒนา')),
            );
          },
        ),
        title: SingleChildScrollView(
          // ทำให้เมนูสามารถเลื่อนในแนวนอนได้
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // จัดตำแหน่งเมนูให้อยู่ตรงกลาง
            children: [
              _buildAppBarMenuItem(context, 'สำรวจ'),
              const SizedBox(width: 20), // ระยะห่างระหว่างเมนู
              _buildAppBarMenuItem(context, 'เพื่อน'),
              const SizedBox(width: 20),
              _buildAppBarMenuItem(context, 'กำลังติดตาม'),
              const SizedBox(width: 20),
              _buildAppBarMenuItem(context, 'สำหรับคุณ',
                  isSelected: true), // "สำหรับคุณ" ถูกเลือกเป็นค่าเริ่มต้น
            ],
          ),
        ),
        // สามารถเพิ่ม actions อื่นๆ ทางด้านขวาได้ที่นี่ หากต้องการ
      ),
      body: const Center(
        child: Text(
          'หน้าจอข้อความ (กำลังพัฒนา)',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างแต่ละ Item ใน AppBar Menu
  Widget _buildAppBarMenuItem(BuildContext context, String text,
      {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        // TODO: เพิ่ม Logic สำหรับการสลับเนื้อหาหน้าจอตามเมนูที่เลือก
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกเมนู: $text')),
        );
      },
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // ทำให้ Column มีขนาดเล็กที่สุดเท่าที่จำเป็น
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey, // สีข้อความตามสถานะการเลือก
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal, // ตัวหนาถ้าถูกเลือก
              fontSize: 18,
            ),
          ),
          if (isSelected) // แสดงเส้นใต้ถ้าเมนูถูกเลือก
            Container(
              margin: const EdgeInsets.only(top: 4), // ระยะห่างจากข้อความ
              height: 3, // ความสูงของเส้นใต้
              width: 30, // ความกว้างของเส้นใต้
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary, // สีแดงชมพูของ TikTok
                borderRadius: BorderRadius.circular(1.5), // ขอบมนของเส้นใต้
              ),
            ),
        ],
      ),
    );
  }
}
