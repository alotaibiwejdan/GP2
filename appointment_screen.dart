import 'package:flutter/material.dart';
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
    String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        
        // --- القسم المحدث: زر الجرس مع التنبيه الأحمر والرقم ---
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('is_read', isEqualTo: false) // نجلب فقط غير المقروء
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }

            return IconButton(
              icon: Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0, // تظهر الدائرة فقط إذا فيه إشعارات
                backgroundColor: Colors.red,
                child: const Icon(Icons.notifications_none, color: Colors.black),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                );
              },
            );
          },
        ),
        // --------------------------------------------------

        title: const Text("مرسال", style: TextStyle(color: Color(0xFFD65A4A), fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: Colors.black), onPressed: pickDate),
          IconButton(
            icon: Icon(Icons.groups_outlined, color: showGroupOnly ? Colors.red : Colors.black),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),
      
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, size: 30, color: Colors.black),
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const SettingsPage())
                ),
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
                  const Text("مواعيدي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate"));
                  }
                  
                  var docs = snapshot.data!.docs;
                  if (showGroupOnly) {
                    docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
                  }
                  
                  if (docs.isEmpty) return Center(child: Text("لا توجد مواعيد مجموعة لهذا التاريخ"));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildCard(data, docs[index].id, index == 0);
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

  Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId))
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isFirst ? null : Colors.white,
          gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
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
                      color: isFirst ? Colors.white : Colors.black, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['location_name'] ?? '', 
                    style: TextStyle(
                      color: isFirst ? Colors.white70 : Colors.grey
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
