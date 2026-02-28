import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'group_meeting_page.dart';
import 'tracking_page.dart';
// 1. أضيفي استيراد ملف صديقتك هنا (تأكدي من اسم الملف إذا كان login_screen.dart)
import 'login_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'مرسال',
      theme: ThemeData(
        fontFamily: 'Tajawal', 
        useMaterial3: true,
      ),
      // 2. هنا نغير الصفحة الأساسية لتكون شاشة تسجيل الدخول
      home: const LoginScreen(), 
    );
  }
}