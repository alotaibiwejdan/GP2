
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/appointment_screen.dart';
//import 'package:flutter_application_1/login_screen.dart';
import 'package:flutter_application_1/settings_page.dart'; // لاستخدام isGlobalDarkMode

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ✅ دالة التسجيل مع التحقق من الشروط
  Future<void> registration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم إنشاء الحساب بنجاح!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppointmentScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "حدث خطأ أثناء التسجيل";
      if (e.code == 'weak-password') {
        message = "كلمة المرور ضعيفة جداً";
      } else if (e.code == 'email-already-in-use') {
        message = "هذا البريد مسجل مسبقاً";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ التحقق من الاسم: إنجليزي فقط + طول محدد
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال الاسم';
    // RegExp للتأكد من أن الحروف إنجليزية فقط
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) return 'الاسم يجب أن يكون باللغة الإنجليزية فقط';
    if (value.length < 3) return 'الاسم قصير جداً';
    return null;
  }

  // ✅ التحقق من البريد: نقطة واحدة فقط قبل النطاق (com/net/etc)
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    // RegExp يضمن وجود نص @ نص . ثم حروف النطاق بدون نقاط مكررة قبلها
    final emailRegex = RegExp(r'^[^@.]+@[^@.]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'صيغة البريد غير صحيحة (مثال: user@mail.com)';
    return null;
  }

  // ✅ التحقق من كلمة المرور: 8 خانات على الأقل
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 خانات على الأقل';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isGlobalDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // الشعار
                  Image.asset(
                    'assets/images/Mersalblack.png', // تأكدي من المسار الصحيح
                    height: 100,
                    color: isDark ? Colors.white : null,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.campaign, size: 80, color: Colors.purple),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 30),

                  // حقل الاسم
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: textColor),
                    maxLength: 30, // ✅ تحديد طول معين (30 حرف)
                    inputFormatters: [
                      // ✅ منع كتابة أي شيء غير الحروف الإنجليزية والمسافات
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'الاسم الكامل (English)',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 10),

                  // حقل البريد
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // حقل كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور (8 خانات فأكثر)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 32),

                  // زر التسجيل
                  _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFFD65A4A))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD65A4A),
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: registration,
                          child: const Text(
                            'تسجيل',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 20),

                  // رابط العودة لتسجيل الدخول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب بالفعل؟ ', style: TextStyle(color: textColor)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                        ),
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
}
