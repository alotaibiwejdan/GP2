import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'group_meeting_page.dart';
//import 'settings_page.dart';
import 'appointment_page.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // ✅ 1. جعل التاريخ الافتراضي هو "الآن" لحظة فتح التطبيق
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;

  // المواعيد الثابتة (للتجربة)
  final List<dynamic> staticAppointments = [
    {
      "title": "موعد طبيب الأسنان",
      "place": "عيادة الحكمة الحديثة",
      "time": "02:30 م",
      "date": DateTime(2025, 12, 25),
      "isGroup": false,
    },
  ];

  // ✅ 2. دالة اختيار التاريخ مع تحديث الحالة
  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFD65A4A)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    // ✅ 3. الحل الجوهري: تكوين نص التاريخ داخل الـ Build لضمان التحديث
    // نستخدم padLeft لضمان صيغة 01, 02 الخ لتطابق الفايربيس تماماً
    String formattedDate = 
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("مرسال", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: pickDate),
          IconButton(
            icon: Icon(Icons.groups, color: showGroupOnly ? Colors.red : null),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentPage())).then((_) => setState(() {})),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          // ✅ عرض التاريخ المختار في أعلى الصفحة
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("مواعيدي", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD65A4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "اليوم: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                    style: const TextStyle(color: Color(0xFFD65A4A), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ 4. هذا الاستعلام سيعيد تشغيل نفسه فوراً عند تغير formattedDate
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('date', isEqualTo: formattedDate) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Widget> listItems = [];

                // أ- إضافة المواعيد من Firebase
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (showGroupOnly && data['isGroup'] != true) continue;
                    
                    listItems.add(_buildCard(data, listItems.isEmpty, isDark));
                  }
                }

                // ب- إضافة المواعيد الثابتة (إذا طابق التاريخ)
                for (var app in staticAppointments) {
                  DateTime appDate = app['date'];
                  if (appDate.year == selectedDate.year &&
                      appDate.month == selectedDate.month &&
                      appDate.day == selectedDate.day) {
                    if (showGroupOnly && app['isGroup'] != true) continue;
                    listItems.add(_buildCard(app, listItems.isEmpty, isDark));
                  }
                }

                if (listItems.isEmpty) {
                  return Center(
                    child: Text("لا توجد مواعيد بتاريخ $formattedDate"),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: listItems,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء الكرت الموحدة
  Widget _buildCard(Map<String, dynamic> data, bool isFirst, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFirst ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['title'] ?? '', style: TextStyle(color: isFirst ? Colors.white : null, fontWeight: FontWeight.bold)),
              Text(data['location'] ?? data['place'] ?? '', style: TextStyle(color: isFirst ? Colors.white70 : Colors.grey)),
            ],
          ),
          Text(data['time'] ?? '', style: TextStyle(color: isFirst ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
