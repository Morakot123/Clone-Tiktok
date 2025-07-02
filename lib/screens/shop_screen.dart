import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้า'),
      ),
      body: const Center(
        child: Text(
          'หน้าจอร้านค้า (กำลังพัฒนา)',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
