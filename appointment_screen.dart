import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 1. أضفنا هذا
import 'appointment_page.dart'; 
import 'appointment_details_page.dart'; 
import 'settings_page.dart'; 
import 'notifications_page.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;
  
  // تعريف بلجن الإشعارات المحلية
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  @override
  void initState() {
    super.initState();
    
    // إعداد الإشعارات وحفظ التوكن
    _setupNotifications();
    saveDeviceToken();
  }

  // ✅ دالة الإعداد الجديدة عشان تظهر الإشعارات "صدق"
  Future<void> _setupNotifications() async {
    // طلب الإذن
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // إعداد القناة لأندرويد
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // الاستماع للإشعارات والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // 1. إظهار SnackBar (مثل ما كنتِ تبغين)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${message.notification!.title}: ${message.notification!.body}"),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 4),
          ),
        );

        // 2. إظهار إشعار علوي (غصب عن النظام)
        // إظهار إشعار النظام العلوي بشكل صحيح
       _localNotifications.show(
          id: message.notification.hashCode, // حددنا إن هذا الـ id
          title: message.notification!.title, 
          body: message.notification!.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon', 
            ),
          ),
        );
      }
    });
  }

  Future<void> saveDeviceToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && userId != null) {
        await FirebaseFirestore.instance
            .collection('users') 
            .doc(userId)
            .set({
              'fcmToken': token, 
            }, SetOptions(merge: true));
        print("✅ تم حفظ التوكن في الفايرستور: $token");
      }
    } catch (e) {
      print("❌ خطأ في جلب التوكن: $e");
    }
  }

  void _openAddPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppointmentPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('is_read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.red,
                child: Icon(Icons.notifications_none, 
                  color: isDarkMode ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            );
          },
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: isDarkMode ? Colors.white : Colors.black), 
            onPressed: pickDate
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.person_outline, "الحساب", () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                setState(() {});
              }, isDarkMode, false),

              _buildBottomNavItem(Icons.groups_outlined, "المجموعات", () {
                setState(() => showGroupOnly = true);
              }, isDarkMode, showGroupOnly),

              _buildBottomNavItem(Icons.add_circle, "إضافة", _openAddPage, isDarkMode, false, isSpecial: true),

              _buildBottomNavItem(Icons.calendar_today_outlined, "مواعيدي", () {
                setState(() => showGroupOnly = false);
              }, isDarkMode, !showGroupOnly),
            ],
          ),
        ),
      ),

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(showGroupOnly ? "مجموعاتي" : "مواعيدي", 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isDarkMode ? Colors.white : Colors.black
                    )
                  ),
                  Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('participants', arrayContains: currentUserEmail)
                    .where('date', isEqualTo: dbDate) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  var docs = snapshot.hasData ? snapshot.data!.docs : [];
                  
                  if (showGroupOnly) {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
                  } else {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] != true).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(child: Text("لا توجد مواعيد لهذا اليوم"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildCard(data, docs[index].id, index == 0, isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap, bool isDarkMode, bool isActive, {bool isSpecial = false}) {
    Color activeColor = const Color(0xFFD65A4A);
    Color idleColor = isDarkMode ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSpecial ? activeColor : (isActive ? activeColor : idleColor), size: isSpecial ? 32 : 26),
          Text(label, style: TextStyle(color: isSpecial ? activeColor : (isActive ? activeColor : idleColor), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId, appointmentData: data))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFirst ? null : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? '', style: TextStyle(color: (isFirst || isDarkMode) ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(data['location_name'] ?? '', style: TextStyle(color: isFirst ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
            Text(data['time'] ?? '', style: TextStyle(color: isFirst ? Colors.white : const Color(0xFFD65A4A), fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_page.dart'; 
import 'appointment_details_page.dart'; 
import 'settings_page.dart'; 
import 'notifications_page.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false; // التحكم في نوع المواعيد المعروضة

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  void _openAddPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppointmentPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('is_read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.red,
                child: Icon(Icons.notifications_none, 
                  color: isDarkMode ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            );
          },
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: isDarkMode ? Colors.white : Colors.black), 
            onPressed: pickDate
          ),
        ],
      ),

      // الـ Bottom Navigation Bar الجديد بـ 4 خيارات
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 5.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // خيار البروفايل
              _buildBottomNavItem(Icons.person_outline, "الحساب", () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                setState(() {});
              }, isDarkMode, false),

              // خيار المجموعات
              _buildBottomNavItem(Icons.groups_outlined, "المجموعات", () {
                setState(() => showGroupOnly = true);
              }, isDarkMode, showGroupOnly),

              // زر الإضافة (في المنتصف)
              _buildBottomNavItem(Icons.add_circle, "إضافة", _openAddPage, isDarkMode, false, isSpecial: true),

              // خيار المواعيد الفردية
              _buildBottomNavItem(Icons.calendar_today_outlined, "مواعيدي", () {
                setState(() => showGroupOnly = false);
              }, isDarkMode, !showGroupOnly),
            ],
          ),
        ),
      ),

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(showGroupOnly ? "مواعيدي " : "مواعيدي ", 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isDarkMode ? Colors.white : Colors.black
                    )
                  ),
                  Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('participants', arrayContains: currentUserEmail)
                    .where('date', isEqualTo: dbDate) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate", 
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));
                  }
                  
                  var docs = snapshot.data!.docs;
                  
                  // الفلترة بناءً على الخيار المختار تحت
                  if (showGroupOnly) {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
                  } else {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] != true).toList();
                  }
                  
                  if (docs.isEmpty) {
                    return Center(child: Text(showGroupOnly ? "لا توجد مواعيد " : "لا توجد مواعيد ", 
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildCard(data, docs[index].id, index == 0, isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ودجت بناء عناصر القائمة السفلية
  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap, bool isDarkMode, bool isActive, {bool isSpecial = false}) {
    Color activeColor = const Color(0xFFD65A4A);
    Color idleColor = isDarkMode ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSpecial ? activeColor : (isActive ? activeColor : idleColor), size: isSpecial ? 32 : 26),
          Text(label, style: TextStyle(color: isSpecial ? activeColor : (isActive ? activeColor : idleColor), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId, appointmentData: const {},))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFirst ? null : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '', 
                    style: TextStyle(
                      color: (isFirst || isDarkMode) ? Colors.white : Colors.black, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['location_name'] ?? '', 
                    style: TextStyle(
                      color: isFirst ? Colors.white70 : (isDarkMode ? Colors.white60 : Colors.grey)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              data['time'] ?? '', 
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFFD65A4A), 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_page.dart'; 
import 'appointment_details_page.dart'; 
import 'settings_page.dart'; 
import 'notifications_page.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  
  void _openAddPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppointmentPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  
  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
   
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
    
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('is_read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.red,
                child: Icon(Icons.notifications_none, 
                  color: isDarkMode ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            );
          },
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: isDarkMode ? Colors.white : Colors.black), 
            onPressed: pickDate
          ),
          IconButton(
            icon: Icon(Icons.groups_outlined, 
              color: showGroupOnly ? Colors.red : (isDarkMode ? Colors.white : Colors.black)),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),
      
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [
              IconButton(
                icon: Icon(Icons.person_outline, size: 30, 
                  color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () async {
                 
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                  setState(() {}); 
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: _openAddPage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("مواعيدي", 
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold, 
                      color: isDarkMode ? Colors.white : Colors.black
                    )
                  ),
                  Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('participants', arrayContains: currentUserEmail)
                    .where('date', isEqualTo: dbDate) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate", 
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));
                  }
                  
                  var docs = snapshot.data!.docs;
                  if (showGroupOnly) {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
                  }
                  
                  if (docs.isEmpty) return Center(child: Text("لا توجد مواعيد مجموعة لهذا التاريخ", 
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildCard(data, docs[index].id, index == 0, isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId, appointmentData: const {},))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          
          color: isFirst ? null : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '', 
                    style: TextStyle(
                      color: (isFirst || isDarkMode) ? Colors.white : Colors.black, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['location_name'] ?? '', 
                    style: TextStyle(
                      color: isFirst ? Colors.white70 : (isDarkMode ? Colors.white60 : Colors.grey)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              data['time'] ?? '', 
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFFD65A4A), 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_page.dart'; 
import 'appointment_details_page.dart'; 
import 'settings_page.dart'; 
import 'notifications_page.dart'; 

// ❌ قمنا بحذف تعريف bool isGlobalDarkMode من هنا لأنه يسبب تعارض (Error)
// سيتم التعرف عليه تلقائياً إذا كان معرفاً في ملف SettingsPage أو ملف مستقل

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;

  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  void _openAddPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppointmentPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ نستخدم المتغير العالمي مباشرة كما كان في كودك السابق
    bool isDarkMode = isGlobalDarkMode; 

    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('is_read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.red,
                child: Icon(Icons.notifications_none, color: isDarkMode ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            );
          },
        ),
title: Image.asset(
          'images/logo.png',
          height: 60, // يمكنك التحكم في الحجم من هنا
          fit: BoxFit.contain,
        ),        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.filter_list, color: isDarkMode ? Colors.white : Colors.black), onPressed: pickDate),
          IconButton(
            icon: Icon(Icons.groups_outlined, color: showGroupOnly ? Colors.red : (isDarkMode ? Colors.white : Colors.black)),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),
      
      bottomNavigationBar: BottomAppBar(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [
              IconButton(
                icon: Icon(Icons.person_outline, size: 30, color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                  setState(() {}); 
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: _openAddPage,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("مواعيدي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                  Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('participants', arrayContains: currentUserEmail)
                    .where('date', isEqualTo: dbDate) 
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));
                  }
                  
                  var docs = snapshot.data!.docs;
                  
                  if (showGroupOnly) {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
                  }
                  
                  if (docs.isEmpty) return Center(child: Text("لا توجد مواعيد مجموعة لهذا التاريخ", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildCard(data, docs[index].id, index == 0, isDarkMode);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFirst ? null : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '', 
                    style: TextStyle(
                      color: (isFirst || isDarkMode) ? Colors.white : Colors.black, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['location_name'] ?? '', 
                    style: TextStyle(
                      color: isFirst ? Colors.white70 : (isDarkMode ? Colors.white60 : Colors.grey)
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              data['time'] ?? '', 
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFFD65A4A), 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}
