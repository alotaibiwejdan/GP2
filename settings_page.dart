import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart'; 

bool isGlobalDarkMode = false; 

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String currentLanguage = 'العربية';
  String userName = 'ساره احمد';
  String userEmail = 'sara.ahmed@example.com';

  // ✅ 1. قائمة الصور البسيطة (تأكدي من وجود الصور في مجلد assets)
  String selectedAvatar = 'assets/images/user.png';
  final List<String> avatarOptions = [
    'assets/images/user.png',
    'assets/images/avatar1.jpg',
    'assets/images/avatar2.jpg',
  ];

  // ✅ 2. دالة تفتح لك قائمة الصور تحت عشان تختارين منها
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: avatarOptions.map((path) {
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedAvatar = path);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage(path),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    TextEditingController nameEdit = TextEditingController(text: userName);
    TextEditingController emailEdit = TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تعديل البيانات', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: emailEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الايميل')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() {
                userName = nameEdit.text;
                userEmail = emailEdit.text;
              });
              Navigator.pop(context);
            }, 
            child: const Text('حفظ')
          ),
        ],
      ),
    );
  }

  // دوالك الأصلية (ما لمستها)
  void _showChangePasswordDialog() { /* كودك */ }
  void _showNotificationsDialog() { /* كودك */ }
  void _showLanguageDialog() { /* كودك */ }
  void _showHelpCenter() { /* كودك */ }
  void _showAboutMersal() { /* كودك */ }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
    Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // لوجو مرسال حقك
            Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple))),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(width: 15),
                  
                  // ✅ 3. ربط الصورة بالدالة السهلة (لما تضغطين تفتح القائمة)
                  GestureDetector(
                    onTap: _showAvatarPicker, 
                    child: CircleAvatar(
                      radius: 35, 
                      backgroundImage: AssetImage(selectedAvatar),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader('عام'),
            _buildSettingsBox([
              _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor),
              _buildListTile(Icons.language, 'اللغة', _showLanguageDialog, textColor, trailingText: currentLanguage),
              _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true),
            ], cardColor),
            _buildSectionHeader('الحساب'),
            _buildSettingsBox([
              _buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor),
            ], cardColor),
            _buildSectionHeader('الدعم'),
            _buildSettingsBox([
              _buildListTile(Icons.help_outline, 'مركز المساعدة', _showHelpCenter, textColor),
              _buildListTile(Icons.info_outline, 'عن مرسال', _showAboutMersal, textColor),
            ], cardColor),
            const SizedBox(height: 30),
            TextButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // دوالك المساعدة (نفس ما هي بالضبط)
  Widget _buildSectionHeader(String title) { return Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10), child: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey))); }
  Widget _buildSettingsBox(List<Widget> children, Color color) { return Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: children)); }
  Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
    return ListTile(
      onTap: onTap,
      leading: isSwitch 
        ? Switch(value: isGlobalDarkMode, onChanged: (value) { setState(() { isGlobalDarkMode = value; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple)
        : const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
      title: Text(title, textAlign: TextAlign.right, style: TextStyle(color: textColor)),
      trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)),
      subtitle: trailingText != null ? Text(trailingText, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey)) : null,
    );
  }
}
