import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main.dart';

// المتغير العام للوضع الداكن
bool isGlobalDarkMode = false;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- المتغيرات المشتركة ---
  String currentLanguage = 'العربية';
  late String userName = "مستخدم مرسال";
  late String userEmail = "البريد غير متوفر";
  User? currentUser;
  bool pushNotify = true;

  String selectedAvatar = 'assets/images/user.png';
  final List<String> avatarOptions = [
    'assets/images/user.png',
    'assets/images/avatar1.jpg',
    'assets/images/avatar2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // تحميل بيانات المستخدم من Firebase
  void _loadUserData() {
    currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      userName = currentUser?.displayName ?? "مستخدم مرسال";
      userEmail = currentUser?.email ?? "البريد غير متوفر";
    });
  }

  // --- دوال النوافذ المنبثقة (الدمج النظيف) ---

  // 1. إدارة التنبيهات
  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إدارة التنبيهات', textAlign: TextAlign.center),
            content: SwitchListTile(
              title: const Text('تنبيهات التطبيق'),
              value: pushNotify,
              activeColor: Colors.purple,
              onChanged: (value) {
                setDialogState(() => pushNotify = value);
                setState(() => pushNotify = value);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))
            ],
          ),
        ),
      ),
    );
  }

  // 2. تعديل الملف الشخصي (الاسم والإيميل)
  void _showEditProfileDialog() {
    TextEditingController nameEdit = TextEditingController(text: userName);
    TextEditingController emailEdit = TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل البيانات الشخصية', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم الجديد')),
              const SizedBox(height: 10),
              TextField(controller: emailEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'البريد الإلكتروني الجديد')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                try {
                  // تحديث الاسم في Firebase
                  if (nameEdit.text != userName) {
                    await currentUser?.updateDisplayName(nameEdit.text);
                    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
                      'displayName': nameEdit.text,
                    }, SetOptions(merge: true));
                  }

                  // تحديث الإيميل (يتطلب تأكيد من البريد)
                  if (emailEdit.text != currentUser?.email) {
                    await currentUser?.verifyBeforeUpdateEmail(emailEdit.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط تأكيد للبريد الجديد')));
                    }
                  }

                  setState(() => userName = nameEdit.text);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. تغيير كلمة المرور
  void _showChangePasswordDialog() {
    TextEditingController oldPass = TextEditingController();
    TextEditingController newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
              TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                try {
                  AuthCredential cred = EmailAuthProvider.credential(email: currentUser!.email!, password: oldPass.text);
                  await currentUser!.reauthenticateWithCredential(cred);
                  await currentUser!.updatePassword(newPass.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث كلمة المرور')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور الحالية غير صحيحة')));
                }
              },
              child: const Text('تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  // 4. اختيار الصورة الشخصية
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: avatarOptions.map((path) => GestureDetector(
                  onTap: () { setState(() => selectedAvatar = path); Navigator.pop(context); },
                  child: CircleAvatar(radius: 35, backgroundImage: AssetImage(path))
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 5. مركز المساعدة وعن مرسال
  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('مركز المساعدة'),
          content: const Text('لأي استفسار تواصل معنا:\nEmail: support@mersal.com\nTel: 92000000'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
    Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
          title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
              const SizedBox(height: 30),
              
              // بطاقة المستخدم
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    GestureDetector(onTap: _showAvatarPicker, child: CircleAvatar(radius: 35, backgroundImage: AssetImage(selectedAvatar), backgroundColor: Colors.purple.withOpacity(0.1))),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13))])),
                    TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple)))
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionHeader('عام'),
              _buildSettingsBox([
                _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor),
                _buildListTile(Icons.language, 'اللغة', () => _showLanguageDialog(), textColor, trailingText: 'العربية'),
                _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true)
              ], cardColor),

              _buildSectionHeader('الحساب'),
              _buildSettingsBox([
                _buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor)
              ], cardColor),

              _buildSectionHeader('الدعم'),
              _buildSettingsBox([
                _buildListTile(Icons.help_outline, 'مركز المساعدة', _showHelpCenter, textColor),
                _buildListTile(Icons.info_outline, 'عن مرسال', () {
                  showDialog(context: context, builder: (context) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text('عن مرسال'), content: const Text('تطبيق مرسال يساعد على تنظيم الاجتماعات وتتبع وصول المشاركين.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً'))])));
                }, textColor)
              ], cardColor),

              const SizedBox(height: 30),
              // زر تسجيل الخروج
              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- عناصر واجهة المستخدم المساعدة ---
  Widget _buildSectionHeader(String title) => Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10, right: 5), child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
  
  Widget _buildSettingsBox(List<Widget> children, Color cardColor) => Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: Column(children: children));

  Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
      trailing: isSwitch 
        ? Switch(value: isGlobalDarkMode, onChanged: (v) { setState(() { isGlobalDarkMode = v; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple)
        : Row(mainAxisSize: MainAxisSize.min, children: [if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(15.0), child: Text("اللغة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ListTile(leading: const Icon(Icons.check_circle, color: Colors.purple), title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late String userName = "مستخدم مرسال";
  late String userEmail = "البريد غير متوفر";
  User? currentUser;
  bool pushNotify = true;

  String selectedAvatar = 'assets/images/user.png';
  final List<String> avatarOptions = [
    'assets/images/user.png',
    'assets/images/avatar1.jpg',
    'assets/images/avatar2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      userName = currentUser?.displayName ?? "مستخدم مرسال";
      userEmail = currentUser?.email ?? "البريد غير متوفر";
    });
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إدارة التنبيهات', textAlign: TextAlign.center),
            content: SwitchListTile(
              title: const Text('تنبيهات التطبيق'),
              value: pushNotify,
              activeColor: Colors.purple,
              onChanged: (value) {
                setDialogState(() => pushNotify = value);
                setState(() => pushNotify = value);
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))
            ],
          ),
        ),
      ),
    );
  }

  
  void _showEditProfileDialog() {
    TextEditingController nameEdit = TextEditingController(text: userName);
    TextEditingController emailEdit = TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل البيانات الشخصية', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم الجديد')),
              const SizedBox(height: 10),
              TextField(controller: emailEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'البريد الإلكتروني الجديد')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                try {
                  
                  if (nameEdit.text != userName) {
                    await currentUser?.updateDisplayName(nameEdit.text);
                    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
                      'displayName': nameEdit.text,
                    }, SetOptions(merge: true));
                  }

                  
                  if (emailEdit.text != currentUser?.email) {
                    await currentUser?.verifyBeforeUpdateEmail(emailEdit.text);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط تأكيد للبريد الجديد، يرجى الضغط عليه')));
                  }

                  setState(() {
                    userName = nameEdit.text;
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    TextEditingController oldPass = TextEditingController();
    TextEditingController newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
              TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                try {
                  AuthCredential cred = EmailAuthProvider.credential(email: currentUser!.email!, password: oldPass.text);
                  await currentUser!.reauthenticateWithCredential(cred);
                  await currentUser!.updatePassword(newPass.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث كلمة المرور')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور الحالية غير صحيحة')));
                }
              },
              child: const Text('تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(15.0), child: Text("اللغة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ListTile(leading: const Icon(Icons.check_circle, color: Colors.purple), title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: avatarOptions.map((path) => GestureDetector(onTap: () { setState(() => selectedAvatar = path); Navigator.pop(context); }, child: CircleAvatar(radius: 35, backgroundImage: AssetImage(path)))).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
    Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(backgroundColor: bgColor, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)), title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
              const SizedBox(height: 30),
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)), child: Row(children: [GestureDetector(onTap: _showAvatarPicker, child: CircleAvatar(radius: 35, backgroundImage: AssetImage(selectedAvatar), backgroundColor: Colors.purple.withOpacity(0.1))), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)), Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13))])), TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple)))])),
              const SizedBox(height: 30),
              _buildSectionHeader('عام'),
              _buildSettingsBox([_buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor), _buildListTile(Icons.language, 'اللغة', _showLanguageDialog, textColor, trailingText: 'العربية'), _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true)], cardColor),
              _buildSectionHeader('الحساب'),
              _buildSettingsBox([_buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor)], cardColor),
              _buildSectionHeader('الدعم'),
              _buildSettingsBox([_buildListTile(Icons.help_outline, 'مركز المساعدة', () { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('مركز المساعدة'), content: const Text('لأي استفسار تواصل معنا:\nEmail: support@mersal.com\nTel: 92000000'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))])); }, textColor), _buildListTile(Icons.info_outline, 'عن مرسال', () { showDialog(context: context, builder: (context) => AlertDialog(title: const Text('عن مرسال'), content: const Text('تطبيق مرسال هو تطبيق ذكي يساعد على تنظيم الاجتماعات وتتبع وصول المشاركين ومعرفة وقت الوصول المتوقع باستخدام الموقع والتنبيهات الذكية لتحسين التنسيق بين المستخدمين.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً'))])); }, textColor)], cardColor),
              const SizedBox(height: 30),
              TextButton.icon(onPressed: () async { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); }, icon: const Icon(Icons.logout, color: Colors.red), label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
  Widget _buildSettingsBox(List<Widget> children, Color cardColor) => Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: Column(children: children));
  Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
    return ListTile(onTap: onTap, leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)), title: Text(title, style: TextStyle(color: textColor, fontSize: 15)), trailing: isSwitch ? Switch(value: isGlobalDarkMode, onChanged: (v) { setState(() { isGlobalDarkMode = v; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple) : Row(mainAxisSize: MainAxisSize.min, children: [if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)]));
  }
}




//-----------------------------------------------------

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'login_screen.dart';
// import 'main.dart';

// bool isGlobalDarkMode = false;

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   String currentLanguage = 'العربية';
//   late String userName = "مستخدم مرسال";
//   late String userEmail = "البريد غير متوفر";
//   User? currentUser;
//   bool pushNotify = true; 

//   String selectedAvatar = 'assets/images/user.png';
//   final List<String> avatarOptions = [
//     'assets/images/user.png',
//     'assets/images/avatar1.jpg',
//     'assets/images/avatar2.jpg',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   void _loadUserData() {
//     currentUser = FirebaseAuth.instance.currentUser;
//     setState(() {
//       userName = currentUser?.displayName ?? "مستخدم مرسال";
//       userEmail = currentUser?.email ?? "البريد غير متوفر";
//     });
//   }

  
//   void _showNotificationsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => Directionality(
//           textDirection: TextDirection.rtl,
//           child: AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: const Text('إدارة التنبيهات', textAlign: TextAlign.center),
//             content: SwitchListTile(
//               title: const Text('تنبيهات التطبيق'),
//               value: pushNotify,
//               activeColor: Colors.purple,
//               onChanged: (value) {
//                 setDialogState(() => pushNotify = value);
//                 setState(() => pushNotify = value);
//               },
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('تم'),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }

  
//   void _showEditProfileDialog() {
//     TextEditingController nameEdit = TextEditingController(text: userName);
//     TextEditingController emailEdit = TextEditingController(text: userEmail);

//     showDialog(
//       context: context,
//       builder: (context) => Directionality(
//         textDirection: TextDirection.rtl,
//         child: AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Text('تعديل البيانات الشخصية', textAlign: TextAlign.center),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameEdit,
//                 textAlign: TextAlign.right,
//                 decoration: const InputDecoration(labelText: 'الاسم الجديد'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: emailEdit,
//                 textAlign: TextAlign.right,
//                 decoration: const InputDecoration(labelText: 'البريد الإلكتروني الجديد'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
//             TextButton(
//               onPressed: () async {
//                 try {
//                   await currentUser?.updateDisplayName(nameEdit.text);
//                   setState(() {
//                     userName = nameEdit.text;
//                     userEmail = emailEdit.text;
//                   });
//                   Navigator.pop(context);
//                 } catch (e) {
//                   print("Error updating profile: $e");
//                 }
//               },
//               child: const Text('حفظ التعديلات'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

  
//   void _showLanguageDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => Directionality(
//         textDirection: TextDirection.rtl,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Padding(
//               padding: EdgeInsets.all(15.0),
//               child: Text("اللغة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             ),
//             ListTile(
//               leading: const Icon(Icons.check_circle, color: Colors.purple),
//               title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.bold)),
//               onTap: () => Navigator.pop(context),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

 
//   void _showAvatarPicker() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
//       builder: (context) => Directionality(
//         textDirection: TextDirection.rtl,
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: avatarOptions.map((path) {
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() => selectedAvatar = path);
//                       Navigator.pop(context);
//                     },
//                     child: CircleAvatar(
//                       radius: 35,
//                       backgroundImage: AssetImage(path),
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
//     Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
//     Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: bgColor,
//         appBar: AppBar(
//           backgroundColor: bgColor,
//           elevation: 0,
//           leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
//           title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
//           centerTitle: true,
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),
//               Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
//               const SizedBox(height: 30),
              
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: _showAvatarPicker,
//                       child: CircleAvatar(
//                         radius: 35,
//                         backgroundImage: AssetImage(selectedAvatar),
//                         backgroundColor: Colors.purple.withOpacity(0.1),
//                       ),
//                     ),
//                     const SizedBox(width: 15),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//                           Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                         ],
//                       ),
//                     ),
//                     TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple))),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
              
//               _buildSectionHeader('عام'),
//               _buildSettingsBox([
//                 _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor),
//                 _buildListTile(Icons.language, 'اللغة', _showLanguageDialog, textColor, trailingText: 'العربية'),
//                 _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true),
//               ], cardColor),

//               _buildSectionHeader('الدعم'),
//               _buildSettingsBox([
//                 _buildListTile(Icons.help_outline, 'مركز المساعدة', () {
//                  showDialog(context: context, builder: (context) => AlertDialog(title: const Text('مركز المساعدة'), content: const Text('لأي استفسار تواصل معنا:\nEmail: support@mersal.com\nTel: 92000000'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]));
//                 }, textColor),
//                 _buildListTile(Icons.info_outline, 'عن مرسال', () {
//                     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('عن مرسال'), content: const Text('تطبيق مرسال هو تطبيق ذكي يساعد على تنظيم الاجتماعات وتتبع وصول المشاركين ومعرفة وقت الوصول المتوقع باستخدام الموقع والتنبيهات الذكية لتحسين التنسيق بين المستخدمين.',), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً'))]));
//                 }, textColor),
//               ], cardColor),

//               const SizedBox(height: 30),
//               TextButton.icon(
//                 onPressed: () async {
//                   await FirebaseAuth.instance.signOut();
//                   if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
//                 },
//                 icon: const Icon(Icons.logout, color: Colors.red),
//                 label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//               ),
//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
//   }

//   Widget _buildSettingsBox(List<Widget> children, Color cardColor) {
//     return Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)), child: Column(children: children));
//   }

//   Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
//     return ListTile(
//       onTap: onTap,
//       leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)),
//       title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
//       trailing: isSwitch 
//         ? Switch(value: isGlobalDarkMode, onChanged: (value) { setState(() { isGlobalDarkMode = value; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple)
//         : Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
//               const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
//             ],
//           ),
//     );
//   }
// }
// //كود وجدان
// /*import 'package:flutter/material.dart';
// import 'login_screen.dart';
// import 'main.dart'; 

// bool isGlobalDarkMode = false; 

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   String currentLanguage = 'العربية';
//   String userName = 'ساره احمد';
//   String userEmail = 'sara.ahmed@example.com';

//   // ✅ الجزء المضاف لاختيار الصورة (مع التأكد من الامتدادات)
//   String selectedAvatar = 'assets/images/user.png';
//   final List<String> avatarOptions = [
//     'assets/images/user.png',
//     'assets/images/avatar1.jpg',
//     'assets/images/avatar2.jpg',
//   ];

//   void _showAvatarPicker() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: avatarOptions.map((path) {
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() => selectedAvatar = path);
//                     Navigator.pop(context);
//                   },
//                   child: CircleAvatar(
//                     radius: 35,
//                     backgroundImage: AssetImage(path),
//                   ),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ دوالك الأصلية (محتويات الأزرار) كما هي بالضبط:
//   void _showEditProfileDialog() {
//     TextEditingController nameEdit = TextEditingController(text: userName);
//     TextEditingController emailEdit = TextEditingController(text: userEmail);
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('تعديل البيانات', textAlign: TextAlign.center),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(controller: nameEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم')),
//             TextField(controller: emailEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الايميل')),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
//           TextButton(onPressed: () {
//             setState(() { userName = nameEdit.text; userEmail = emailEdit.text; });
//             Navigator.pop(context);
//           }, child: const Text('حفظ')),
//         ],
//       ),
//     );
//   }

//   void _showChangePasswordDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('تغيير كلمة المرور', textAlign: TextAlign.center),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('أدخل الكود المكون من 4 أرقام الذي أرسلناه إلى بريدك الإلكتروني', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
//             const SizedBox(height: 20),
//             TextField(keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 4, decoration: InputDecoration(hintText: '0 0 0 0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
//           TextButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحقق من الكود بنجاح'))); }, child: const Text('تحقق')),
//         ],
//       ),
//     );
//   }

//   void _showNotificationsDialog() {
//     bool pushNotify = true;
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('إدارة التنبيهات', textAlign: TextAlign.center),
//           content: SwitchListTile(title: const Text('تنبيهات التطبيق'), value: pushNotify, activeColor: Colors.purple, onChanged: (value) => setDialogState(() => pushNotify = value)),
//           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
//         ),
//       ),
//     );
//   }

//   void _showLanguageDialog() {
//     showModalBottomSheet(
//       context: context, 
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
//       builder: (context) => Column(
//         mainAxisSize: MainAxisSize.min, 
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(15.0),
//             child: Text("اختر اللغة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//           ),
//           ListTile(
//             title: const Text('العربية', textAlign: TextAlign.center, style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), 
//             onTap: () { 
//               setState(() => currentLanguage = 'العربية'); 
//               Navigator.pop(context); 
//             }
//           ),
//           const SizedBox(height: 10),
//         ]
//       )
//     );
//   }

//   void _showHelpCenter() {
//     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('مركز المساعدة'), content: const Text('لأي استفسار تواصل معنا:\nEmail: support@mersal.com\nTel: 92000000'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]));
//   }

//   void _showAboutMersal() {
//     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('عن مرسال'), content: const Text('تطبيق مرسال هو تطبيق ذكي يساعد على تنظيم الاجتماعات وتتبع وصول المشاركين ومعرفة وقت الوصول المتوقع باستخدام الموقع والتنبيهات الذكية لتحسين التنسيق بين المستخدمين.',), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً'))]));
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
//     Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
//     Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: bgColor, elevation: 0,
//         leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
//         title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             const SizedBox(height: 10),
//             Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
//             const SizedBox(height: 30),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
//               child: Row(
//                 children: [
//                   TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple))),
//                   const Spacer(),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
//                       Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                     ],
//                   ),
//                   const SizedBox(width: 15),
//                   // ✅ ربط الصورة بـ _showAvatarPicker
//                   GestureDetector(
//                     onTap: _showAvatarPicker,
//                     child: CircleAvatar(
//                       radius: 35, 
//                       backgroundImage: AssetImage(selectedAvatar),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             _buildSectionHeader('عام'),
//             _buildSettingsBox([
//               _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor),
//               _buildListTile(Icons.language, 'اللغة', _showLanguageDialog, textColor, trailingText: currentLanguage),
//               _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true),
//             ], cardColor),
//             _buildSectionHeader('الحساب'),
//             _buildSettingsBox([
//               _buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor),
//             ], cardColor),
//             _buildSectionHeader('الدعم'),
//             _buildSettingsBox([
//               _buildListTile(Icons.help_outline, 'مركز المساعدة', _showHelpCenter, textColor),
//               _buildListTile(Icons.info_outline, 'عن مرسال', _showAboutMersal, textColor),
//             ], cardColor),
//             const SizedBox(height: 30),
//             TextButton.icon(
//               onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
//               icon: const Icon(Icons.logout, color: Colors.red),
//               label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // الدوال المساعدة الأصلية حقتك
//   Widget _buildSectionHeader(String title) { return Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10), child: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey))); }
//   Widget _buildSettingsBox(List<Widget> children, Color color) { return Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: children)); }
//   Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
//     return ListTile(
//       onTap: onTap,
//       leading: isSwitch 
//         ? Switch(value: isGlobalDarkMode, onChanged: (value) { setState(() { isGlobalDarkMode = value; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple)
//         : const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
//       title: Text(title, textAlign: TextAlign.right, style: TextStyle(color: textColor)),
//       trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)),
//       subtitle: trailingText != null ? Text(trailingText, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey)) : null,
//     );
//   }
// }*/


// // import 'package:flutter/material.dart';
// // import 'login_screen.dart';
// // import 'main.dart'; 

// // bool isGlobalDarkMode = false; 

// // class SettingsPage extends StatefulWidget {
// //   const SettingsPage({super.key});

// //   @override
// //   State<SettingsPage> createState() => _SettingsPageState();
// // }

// // class _SettingsPageState extends State<SettingsPage> {
// //   String currentLanguage = 'العربية';
// //   String userName = 'ساره احمد';
// //   String userEmail = 'sara.ahmed@example.com';

// //   // ✅ الجزء المضاف لاختيار الصورة (مع التأكد من الامتدادات)
// //   String selectedAvatar = 'assets/images/user.png';
// //   final List<String> avatarOptions = [
// //     'assets/images/user.png',
// //     'assets/images/avatar1.jpg',
// //     'assets/images/avatar2.jpg',
// //   ];

// //   void _showAvatarPicker() {
// //     showModalBottomSheet(
// //       context: context,
// //       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
// //       builder: (context) => Container(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text("اختر صورتك المفضلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// //             const SizedBox(height: 20),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceAround,
// //               children: avatarOptions.map((path) {
// //                 return GestureDetector(
// //                   onTap: () {
// //                     setState(() => selectedAvatar = path);
// //                     Navigator.pop(context);
// //                   },
// //                   child: CircleAvatar(
// //                     radius: 35,
// //                     backgroundImage: AssetImage(path),
// //                   ),
// //                 );
// //               }).toList(),
// //             ),
// //             const SizedBox(height: 20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ✅ دوالك الأصلية (محتويات الأزرار) كما هي بالضبط:
// //   void _showEditProfileDialog() {
// //     TextEditingController nameEdit = TextEditingController(text: userName);
// //     TextEditingController emailEdit = TextEditingController(text: userEmail);
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         title: const Text('تعديل البيانات', textAlign: TextAlign.center),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             TextField(controller: nameEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الاسم')),
// //             TextField(controller: emailEdit, textAlign: TextAlign.right, decoration: const InputDecoration(labelText: 'الايميل')),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
// //           TextButton(onPressed: () {
// //             setState(() { userName = nameEdit.text; userEmail = emailEdit.text; });
// //             Navigator.pop(context);
// //           }, child: const Text('حفظ')),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showChangePasswordDialog() {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //         title: const Text('تغيير كلمة المرور', textAlign: TextAlign.center),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Text('أدخل الكود المكون من 4 أرقام الذي أرسلناه إلى بريدك الإلكتروني', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
// //             const SizedBox(height: 20),
// //             TextField(keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 4, decoration: InputDecoration(hintText: '0 0 0 0', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
// //           TextButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحقق من الكود بنجاح'))); }, child: const Text('تحقق')),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showNotificationsDialog() {
// //     bool pushNotify = true;
// //     showDialog(
// //       context: context,
// //       builder: (context) => StatefulBuilder(
// //         builder: (context, setDialogState) => AlertDialog(
// //           title: const Text('إدارة التنبيهات', textAlign: TextAlign.center),
// //           content: SwitchListTile(title: const Text('تنبيهات التطبيق'), value: pushNotify, activeColor: Colors.purple, onChanged: (value) => setDialogState(() => pushNotify = value)),
// //           actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
// //         ),
// //       ),
// //     );
// //   }

// //   void _showLanguageDialog() {
// //     showModalBottomSheet(
// //       context: context, 
// //       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), 
// //       builder: (context) => Column(
// //         mainAxisSize: MainAxisSize.min, 
// //         children: [
// //           const Padding(
// //             padding: EdgeInsets.all(15.0),
// //             child: Text("اختر اللغة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
// //           ),
// //           ListTile(
// //             title: const Text('العربية', textAlign: TextAlign.center, style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)), 
// //             onTap: () { 
// //               setState(() => currentLanguage = 'العربية'); 
// //               Navigator.pop(context); 
// //             }
// //           ),
// //           const SizedBox(height: 10),
// //         ]
// //       )
// //     );
// //   }

// //   void _showHelpCenter() {
// //     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('مركز المساعدة'), content: const Text('لأي استفسار تواصل معنا:\nEmail: support@mersal.com\nTel: 92000000'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))]));
// //   }

// //   void _showAboutMersal() {
// //     showDialog(context: context, builder: (context) => AlertDialog(title: const Text('عن مرسال'), content: const Text('تطبيق مرسال هو تطبيق ذكي يساعد على تنظيم الاجتماعات وتتبع وصول المشاركين ومعرفة وقت الوصول المتوقع باستخدام الموقع والتنبيهات الذكية لتحسين التنسيق بين المستخدمين.',), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً'))]));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     Color bgColor = isGlobalDarkMode ? const Color(0xFF121212) : Colors.white;
// //     Color textColor = isGlobalDarkMode ? Colors.white : Colors.black;
// //     Color cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF9F9F9);

// //     return Scaffold(
// //       backgroundColor: bgColor,
// //       appBar: AppBar(
// //         backgroundColor: bgColor, elevation: 0,
// //         leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
// //         title: Text('حسابي', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
// //         centerTitle: true,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.symmetric(horizontal: 20),
// //         child: Column(
// //           children: [
// //             const SizedBox(height: 10),
// //             Center(child: Image.asset('assets/images/logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.campaign, size: 80, color: Colors.purple))),
// //             const SizedBox(height: 30),
// //             Container(
// //               padding: const EdgeInsets.all(20),
// //               decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
// //               child: Row(
// //                 children: [
// //                   TextButton(onPressed: _showEditProfileDialog, child: const Text('تعديل', style: TextStyle(color: Colors.purple))),
// //                   const Spacer(),
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.end,
// //                     children: [
// //                       Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
// //                       Text(userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
// //                     ],
// //                   ),
// //                   const SizedBox(width: 15),
// //                   // ✅ ربط الصورة بـ _showAvatarPicker
// //                   GestureDetector(
// //                     onTap: _showAvatarPicker,
// //                     child: CircleAvatar(
// //                       radius: 35, 
// //                       backgroundImage: AssetImage(selectedAvatar),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(height: 30),
// //             _buildSectionHeader('عام'),
// //             _buildSettingsBox([
// //               _buildListTile(Icons.notifications_none, 'إدارة التنبيهات', _showNotificationsDialog, textColor),
// //               _buildListTile(Icons.language, 'اللغة', _showLanguageDialog, textColor, trailingText: currentLanguage),
// //               _buildListTile(Icons.dark_mode_outlined, 'الوضع الداكن', null, textColor, isSwitch: true),
// //             ], cardColor),
// //             _buildSectionHeader('الحساب'),
// //             _buildSettingsBox([
// //               _buildListTile(Icons.lock_outline, 'تغيير كلمة المرور', _showChangePasswordDialog, textColor),
// //             ], cardColor),
// //             _buildSectionHeader('الدعم'),
// //             _buildSettingsBox([
// //               _buildListTile(Icons.help_outline, 'مركز المساعدة', _showHelpCenter, textColor),
// //               _buildListTile(Icons.info_outline, 'عن مرسال', _showAboutMersal, textColor),
// //             ], cardColor),
// //             const SizedBox(height: 30),
// //             TextButton.icon(
// //               onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
// //               icon: const Icon(Icons.logout, color: Colors.red),
// //               label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // الدوال المساعدة الأصلية حقتك
// //   Widget _buildSectionHeader(String title) { return Container(width: double.infinity, padding: const EdgeInsets.only(bottom: 10), child: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey))); }
// //   Widget _buildSettingsBox(List<Widget> children, Color color) { return Container(margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withOpacity(0.1))), child: Column(children: children)); }
// //   Widget _buildListTile(IconData icon, String title, VoidCallback? onTap, Color textColor, {String? trailingText, bool isSwitch = false}) {
// //     return ListTile(
// //       onTap: onTap,
// //       leading: isSwitch 
// //         ? Switch(value: isGlobalDarkMode, onChanged: (value) { setState(() { isGlobalDarkMode = value; }); MyApp.of(context)?.changeTheme(); }, activeColor: Colors.purple)
// //         : const Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey),
// //       title: Text(title, textAlign: TextAlign.right, style: TextStyle(color: textColor)),
// //       trailing: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.purple, size: 22)),
// //       subtitle: trailingText != null ? Text(trailingText, textAlign: TextAlign.right, style: const TextStyle(color: Colors.grey)) : null,
// //     );
// //   }
// // }
