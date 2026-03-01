import 'package:flutter/material.dart';
import 'package:flutter_application_1/forgot_password_screen.dart';
import 'appointment_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Center(
                child: Image.asset(
                  'assets/MersalImage/Mersalblack.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'سجل الدخول لمتابعة مواعيدك',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // حقل البريد الإلكتروني
              TextField(
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'أدخل بريدك الإلكتروني',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // رابط نسيت كلمة المرور فوق حقل كلمة المرور
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(
                        color: Colors.pink, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // حقل كلمة المرور
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  hintText: 'أدخل كلمة المرور',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // زر تسجيل الدخول
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const AppointmentScreen()),
  );
                },
                
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD65A4A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('أو سجل الدخول باستخدام'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // زر Google
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/MersalImage/Googel_Logo.png',
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text('تسجيل الدخول باستخدام Google'),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // زر Apple
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.apple, size: 24),
                    SizedBox(width: 10),
                    Text('تسجيل الدخول باستخدام Apple'),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // رابط إنشاء حساب جديد
              // رابط إنشاء حساب جديد
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text('ليس لديك حساب؟'),
    TextButton(
      onPressed: () {
        // نستخدم الاسم اللي عندك بالضبط
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(), 
          ),
        );
      },
      child: const Text(
        'أنشئ حسابًا جديدًا',
        style: TextStyle(
            color: Colors.pink, fontWeight: FontWeight.bold),
      ),
    ),
  ],
),
            ],
          ),
        ),
      ),
    );
  }
}

  }
}

