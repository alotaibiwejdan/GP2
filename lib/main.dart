import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. استيراد المكتبة الأساسية
import 'lamia_onboarding_screen.dart';
import 'settings_page.dart'; 
import 'appointment_details_page.dart';
import 'appointment_page.dart';
import 'edit_appointment_page.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:  FirebaseOptions(
      apiKey:"AIzaSyAvj2HL2LD2HDHsD2GyEy5RBRW_CnwnRxc",
      authDomain:"mersal-90cf9.firebaseapp.com",
      projectId:"mersal-90cf9",
      storageBucket:"mersal-90cf9.firebasestorage.app",
      messagingSenderId:"760561356873",
      appId:"1:760561356873:web:159892e163597019766f98",
      measurementId:"G-3MTL89GLZ3",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
  void changeTheme() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'مرسال',
      
      // الربط بالثيم (شغال تمام مثل ما سويتيه)
      themeMode: isGlobalDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      theme: ThemeData(
        fontFamily: 'Tajawal', 
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
      ),
      
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
