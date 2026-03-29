import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
// 1. لازم تستوردين صفحة الإعدادات عشان يقرأ المتغير العام
import 'settings_page.dart'; 
import 'appointment_details_page.dart';
import 'appointment_page.dart';
import 'edit_appointment_page.dart';

void main() {
  runApp(const MyApp());
}

// 2. حولنا MyApp إلى StatefulWidget عشان يقدر "يعيد بناء نفسه" لما يتغير الثيم
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // هذه السطر بنحتاجه عشان ننادي إعادة البناء من أي مكان
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  // دالة لتحديث الواجهة كاملة
  void changeTheme() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'مرسال',
      
      // 3. هنا الربط السحري بالمتغير اللي في صفحة الإعدادات
      themeMode: isGlobalDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      theme: ThemeData(
        fontFamily: 'Tajawal', 
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
      ),
      
      // إعدادات الثيم الداكن (الأسود)
      darkTheme: ThemeData(
        fontFamily: 'Tajawal',
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      
      home: const OnboardingScreen(), 
    );
  }
}
