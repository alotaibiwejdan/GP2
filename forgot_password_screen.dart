import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
 
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  
  Future<void> _sendResetEmail() async {
    String email = _emailController.text.trim();


    if (email.isEmpty || !email.contains('@')) {
      _showMessage("الرجاء إدخال بريد إلكتروني صحيح");
      return;
    }

    setState(() => _isLoading = true);

    try {
      
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      
      _showMessage("تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني بنجاح");
      
      
      if (mounted) Navigator.pop(context);
      
    } on FirebaseAuthException catch (e) {
      
      String message = "حدث خطأ ما";
      if (e.code == 'user-not-found') {
        message = "لا يوجد حساب مسجل بهذا البريد الإلكتروني";
      } else if (e.code == 'invalid-email') {
        message = "صيغة البريد الإلكتروني غير صحيحة";
      }
      _showMessage(message);
    } catch (e) {
      _showMessage("حدث خطأ غير متوقع: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
              const SizedBox(height: 50),
              
              Center(
                child: Image.asset(
                  'assets/Images/Mersalblack.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'استعادة كلمة المرور',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),

              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  hintText: 'أدخل بريدك الإلكتروني',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              _isLoading 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    onPressed: _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD65A4A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إرسال الرابط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('تذكرت كلمة المرور؟'),
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
    );
  }
}





// import 'package:flutter/material.dart';

// /* ================= FORGOT PASSWORD SCREEN ================= */
// class ForgotPasswordScreen extends StatelessWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // شعار التطبيق
//               Center(
//                 child: Image.asset(
//                   'assets/MersalImage/Mersalblack.png',
//                   height: 100,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'استعادة كلمة المرور',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور',
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 40),

//               // حقل البريد الإلكتروني
//               TextField(
//                 decoration: InputDecoration(
//                   labelText: 'البريد الإلكتروني',
//                   hintText: 'أدخل بريدك الإلكتروني',
//                   contentPadding:
//                       const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 25),

//               // زر إرسال رابط إعادة التعيين
//               ElevatedButton(
//                 onPressed: () {
//                   // هنا تضيف عملية إرسال رابط إعادة التعيين
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFD65A4A),
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   'إرسال الرابط',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // رابط للعودة لتسجيل الدخول
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text('تذكرت كلمة المرور؟'),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Text(
//                       'تسجيل الدخول',
//                       style: TextStyle(
//                           color: Colors.pink, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
