import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/forgot_password_screen.dart';
import 'appointment_screen.dart';
import 'register_screen.dart';
import 'settings_page.dart';

// حولناه لـ StatefulWidget عشان نقدر نستخدم الـ Controllers
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. تعريف المتحكمات لقراءة الإيميل والباسورد
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // دالة تسجيل الدخول
  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // إذا نجح الدخول، ننتقل لصفحة المواعيد
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "حدث خطأ ما";
      
      // التعديل هنا: أضفنا الأكواد الجديدة اللي صار يرسلها فايربيس
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        message = "المستخدم غير موجود";
      } 
      else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "كلمة المرور غير صحيحة";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'حدث خطأ أثناء تسجيل الدخول بجوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تسجيل الدخول بجوجل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    final bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
    final inputFillColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/MersalImage/Mersalblack.png',
                    height: 90,
                    color: isGlobalDarkMode ? Colors.white : null,
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

                // حقل البريد الإلكتروني (أضفنا الـ controller)
                _buildTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  hint: 'أدخل بريدك الإلكتروني',
                  textColor: textColor,
                  fillColor: inputFillColor,
                ),
                
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

                // حقل كلمة المرور (أضفنا الـ controller)
                _buildTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  hint: 'أدخل كلمة المرور',
                  isObscure: true,
                  textColor: textColor,
                  fillColor: inputFillColor,
                ),
                
                const SizedBox(height: 25),

                // زر تسجيل الدخول (نادينا دالة الـ _signIn)
                ElevatedButton(
onPressed: () {
  _signIn();
},                  style: ElevatedButton.styleFrom(
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

                _buildSocialButton(
                  label: 'Google',
                  iconPath: 'assets/MersalImage/Googel_Logo.png',
                  onPressed: _signInWithGoogle,
                  isDark: isGlobalDarkMode,
                ),
                const SizedBox(height: 10),
                _buildSocialButton(
                  label: 'Apple',
                  iconData: Icons.apple,
                  onPressed: () {},
                  isDark: isGlobalDarkMode,
                  isApple: true,
                ),
                const SizedBox(height: 20),
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

  // عدلنا الدالة المساعدة لاستقبال الـ controller
  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required String hint, 
    bool isObscure = false, 
    required Color textColor, 
    required Color fillColor
  }) {
    return TextField(
      controller: controller,
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
