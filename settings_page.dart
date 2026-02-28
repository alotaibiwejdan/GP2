import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  String currentLanguage = 'العربية';
  String userName = 'ساره احمد';
  String userEmail = 'sara.ahmed@example.com';

  // --- هذا هو الكود المسؤول عن نافذة تغيير كلمة المرور ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تغيير كلمة المرور', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل الكود المكون من 4 أرقام الذي أرسلناه إلى بريدك الإلكتروني',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              decoration: InputDecoration(
                hintText: '0 0 0 0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // يغلق النافذة
              // رسالة تأكيد تظهر أسفل الشاشة
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم التحقق من الكود بنجاح')),
              );
            },
            child: const Text('تحقق'),
          ),
        ],
      ),
    );
  }

  // --- دالة تعديل الحساب ---
  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(text: userName);
    TextEditingController emailController = TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الحساب', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'الايميل')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
                userEmail = emailController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.campaign, size: 50, color: Colors.purple),
              ),
            ),
            const SizedBox(height: 30),

            // كرت معلومات المستخدم
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _showEditProfileDialog,
                    child: const Text('تعديل', style: TextStyle(color: Colors.purple)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(width: 15),
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: const AssetImage('assets/images/user.png'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            _buildSectionHeader('عام'),
            _buildSettingsBox([
              _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', () {}, textColor),
              _buildListTile(Icons.language, 'اللغة', () {}, textColor, trailingText: currentLanguage),
              _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true),
            ], cardColor),

            _buildSectionHeader('الحساب'),
            _buildSettingsBox([
              // هنا ربطنا الزر بالدالة اللي كتبناها فوق
              _buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor),
            ], cardColor),

            _buildSectionHeader('الدعم'),
            _buildSettingsBox([
              _buildListTile(Icons.help_outline, 'مركز المساعدة', () {}, textColor),
              _buildListTile(Icons.info_outline, 'عن مرسال', () {}, textColor),
            ], cardColor),

            const SizedBox(height: 30),
            TextButton.icon(
              onPressed: () => print("Logout"),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildSettingsBox(List<Widget> children, Color color) {
    return Container(
      margin: const EdgeInsets.only (bottom:20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
    return ListTile(
      onTap: onTap, // هذا السطر ضروري جداً لتفعيل الضغط
      leading: isSwitch 
        ? Switch(
            value: isDarkMode, 
            onChanged: (value) => setState(() => isDarkMode = value), 
            activeColor: Colors.purple
          )
        : const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
      title: Text(title, textAlign: TextAlign.right, style: TextStyle(color: textColor)),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.purple, size: 22),
      ),
      subtitle: trailingText != null ? Text(trailingText, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey)) : null,
    );
  }
}