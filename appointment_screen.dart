import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/appointment_page.dart'; 
import 'package:flutter_application_1/settings_page.dart'; 
import 'package:flutter_application_1/group_meeting_page.dart'; 
import 'package:flutter_application_1/appointment_details_page.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;

  final List<Map<String, dynamic>> staticAppointments = [
    {
      "id": "1",
      "title": "موعد طبيب الأسنان",
      "place": "عيادة الحكمة الحديثة",
      "time": "02:30",
      "date": DateTime(2025, 12, 25),
      "isGroup": false,
    },
    {
      "id": "2",
      "title": "اجتماع فريق التصميم",
      "place": "مكتب رقم 204",
      "time": "10:00",
      "date": DateTime(2025, 12, 25),
      "isGroup": true,
    },
  ];

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
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
          onPressed: () {},
        ),
        title: Image.asset(
          'assets/images/logo.png', // ✅ تم تصحيح المسار هنا (حذفت assets المكررة)
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Text("مرسال", 
            style: TextStyle(color: Color(0xFFD65A4A), fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black), 
            onPressed: pickDate,
          ),
          IconButton(
            icon: Icon(Icons.groups_outlined, color: showGroupOnly ? Colors.red : Colors.black),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentPage())).then((_) => setState(() {})),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, size: 32),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 32, color: Color(0xFFD65A4A)), 
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("مواعيدي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('date', isEqualTo: dbDate) 
                  .snapshots(),
              builder: (context, snapshot) {
                List<Widget> listItems = [];

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (showGroupOnly && data['isGroup'] != true) continue;
                    listItems.add(_buildCard(data, listItems.isEmpty, isDark));
                  }
                }

                for (var app in staticAppointments) {
                   DateTime appDate = app['date'];
                   if (appDate.year == selectedDate.year && 
                       appDate.month == selectedDate.month &&
                       appDate.day == selectedDate.day) {
                     if (showGroupOnly && app['isGroup'] != true) continue;
                     listItems.add(_buildCard(app, listItems.isEmpty, isDark));
                   }
                }

                if (listItems.isEmpty) return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate"));

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

  Widget _buildCard(Map<String, dynamic> data, bool isFirst, bool isDark) {
    bool isGroup = data['isGroup'] ?? false;

    return GestureDetector(
      onTap: () {
        if (isGroup) {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const GroupMeetingPage())
          );
        } else {
          // ✅ شلت كلمة const من هنا لأن الصفحة صارت StatelessWidget أو عشان تتفادي خطأ الـ Reload
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => AppointmentDetailsPage())
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFirst ? null : Colors.white,
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                      color: isFirst ? Colors.white : Colors.black, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text(
                    data['place'] ?? '', 
                    style: TextStyle(color: isFirst ? Colors.white70 : Colors.grey, fontSize: 14)
                  ),
                  if (isGroup) ...[
                    const SizedBox(height: 8),
                    const Text(
                      "موعد جماعي - اضغط للتفاصيل",
                      style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
            ),
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
