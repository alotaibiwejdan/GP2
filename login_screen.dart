import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_1/forgot_password_screen.dart';
import 'appointment_screen.dart';
import 'register_screen.dart';
import 'settings_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AppointmentScreen()));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("البريد الإلكتروني أو كلمة المرور غير صحيحة"), backgroundColor: Colors.red),
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
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AppointmentScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول بجوجل'), backgroundColor: Colors.red));
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
            child: Form(
              key: _formKey, 
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/Images/Mersalblack.png', height: 90, color: isGlobalDarkMode ? Colors.white : null),
                  const SizedBox(height: 20),
                  Text('سجل الدخول لمتابعة مواعيدك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 30),

                  _buildTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    hint: 'example@email.com',
                    textColor: textColor,
                    fillColor: inputFillColor,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]'))],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                      if (!_isValidEmail(value)) return 'صيغة البريد الإلكتروني غير صحيحة';
                      return null;
                    },
                  ),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    hint: 'أدخل كلمة المرور',
                    isObscure: !_isPasswordVisible,
                    textColor: textColor,
                    fillColor: inputFillColor,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9!@#$%^&*(),.?":{}|<>]'))],
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) { 
                        _signIn();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD65A4A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSocialButton(label: 'Google', iconPath: 'assets/Images/Googel_Logo.png', onPressed: _signInWithGoogle, isDark: isGlobalDarkMode),
                  const SizedBox(height: 10),
                  _buildSocialButton(label: 'Apple', iconData: Icons.apple, onPressed: () {}, isDark: isGlobalDarkMode, isApple: true),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ليس لديك حساب؟', style: TextStyle(color: textColor)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text('أنشئ حسابًا جديدًا', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, bool isObscure = false, required Color textColor, required Color fillColor, Widget? suffixIcon, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      inputFormatters: inputFormatters,
      validator: validator, // إضافة الـ validator
      textAlign: TextAlign.left,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        filled: true,
        fillColor: fillColor,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSocialButton({required String label, String? iconPath, IconData? iconData, required VoidCallback onPressed, required bool isDark, bool isApple = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: isApple ? (isDark ? Colors.white : Colors.black) : (isDark ? const Color(0xFF1E1E1E) : Colors.white), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (iconPath != null) Image.asset(iconPath, height: 20) else Icon(iconData, size: 24),
        const SizedBox(width: 10),
        Text('تسجيل الدخول باستخدام $label'),
      ]),
    );
  }
}
