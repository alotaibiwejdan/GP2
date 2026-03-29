import 'package:flutter/material.dart';
import 'package:flutter_application_1/forgot_password_screen.dart';
import 'appointment_screen.dart';
import 'register_screen.dart';
import 'settings_page.dart'; // ضروري عشان يعرف هل إحنا في دارك مود أو لا

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. تحديد الألوان بناءً على الوضع (فاتح أو داكن)
    final textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    final bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
    final inputFillColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center( // يخلي المحتوى في النص
          child: SingleChildScrollView(
            // تقليل الـ padding لضمان عدم ظهور خطوط الصفراء (Overflow)
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // شعار التطبيق (اللوجو)
                Center(
                  child: Image.asset(
                    'assets/MersalImage/Mersalblack.png',
                    height: 90, // صغرنا الحجم شوي عشان المساحة
                    color: isGlobalDarkMode ? Colors.white : null, // يقلب أبيض في الدارك مود
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.campaign, size: 80, color: Colors.purple);
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  'سجل الدخول لمتابعة مواعيدك',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // حقل البريد الإلكتروني
                _buildTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'أدخل بريدك الإلكتروني',
                  textColor: textColor,
                  fillColor: inputFillColor,
                ),
                
                // رابط نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // حقل كلمة المرور
                _buildTextField(
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  isObscure: true,
                  textColor: textColor,
                  fillColor: inputFillColor,
                ),
                
                const SizedBox(height: 25),

                // زر تسجيل الدخول الأساسي
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('أو سجل الدخول باستخدام', style: TextStyle(color: textColor, fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // زر جوجل
                _buildSocialButton(
                  label: 'Google',
                  iconPath: 'assets/MersalImage/Googel_Logo.png',
                  onPressed: () {},
                  isDark: isGlobalDarkMode,
                ),
                
                const SizedBox(height: 10),
                
                // زر أبل
                _buildSocialButton(
                  label: 'Apple',
                  iconData: Icons.apple,
                  onPressed: () {},
                  isDark: isGlobalDarkMode,
                  isApple: true,
                ),
                
                const SizedBox(height: 20),
                
                // رابط إنشاء حساب
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ليس لديك حساب؟', style: TextStyle(color: textColor)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text('أنشئ حسابًا جديدًا', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء الحقول (Textfields)
  Widget _buildTextField({required String label, required String hint, bool isObscure = false, required Color textColor, required Color fillColor}) {
    return TextField(
      obscureText: isObscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // دالة مساعدة لبناء أزرار التواصل الاجتماعي
  Widget _buildSocialButton({required String label, String? iconPath, IconData? iconData, required VoidCallback onPressed, required bool isDark, bool isApple = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isApple ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        foregroundColor: isApple ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null) 
            Image.asset(iconPath, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 30))
          else 
            Icon(iconData, size: 24),
          const SizedBox(width: 10),
          Text('تسجيل الدخول باستخدام $label'),
        ],
      ),
    );
  }
}
