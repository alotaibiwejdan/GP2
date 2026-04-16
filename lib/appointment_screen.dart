import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_page.dart'; 
import 'appointment_details_page.dart'; 
import 'settings_page.dart'; 

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now(); 
  bool showGroupOnly = false;

  // Custom Navigation Logic
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
        
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("لا توجد تنبيهات جديدة"))
            );
          },
        ),
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
            mainAxisAlignment: MainAxisAlignment.start, // Keeps profile on the left
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
            Column(
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
                  data['location_name'] ?? '', 
                  style: TextStyle(
                    color: isFirst ? Colors.white70 : Colors.grey
                  )
                ),
              ],
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





// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'appointment_page.dart'; 
// import 'appointment_details_page.dart'; 

// class AppointmentScreen extends StatefulWidget {
//   const AppointmentScreen({super.key});

//   @override
//   State<AppointmentScreen> createState() => _AppointmentScreenState();
// }

// class _AppointmentScreenState extends State<AppointmentScreen> {
//   DateTime selectedDate = DateTime.now(); 
//   bool showGroupOnly = false;

//   // FIX: Custom Slide Transition
//   void _openAddPage() {
//     Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => const AppointmentPage(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.easeInOutQuart;
//           var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//           return SlideTransition(position: animation.drive(tween), child: child);
//         },
//       ),
//     );
//   }

//   Future<void> pickDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
//   }

//   @override
//   Widget build(BuildContext context) {
//     String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
//     String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text("مرسال", style: TextStyle(color: Color(0xFFD65A4A), fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         actions: [
//           IconButton(icon: const Icon(Icons.filter_list, color: Colors.black), onPressed: pickDate),
//           IconButton(
//             icon: Icon(Icons.groups_outlined, color: showGroupOnly ? Colors.red : Colors.black),
//             onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFFD65A4A),
//         onPressed: _openAddPage,
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: Directionality(
//         textDirection: TextDirection.rtl,
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text("مواعيدي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//                   Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('appointments')
//                     .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
//                     .where('date', isEqualTo: dbDate) 
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//                   var docs = snapshot.data!.docs;
//                   if (showGroupOnly) docs = docs.where((d) => (d.data() as Map)['isGroup'] == true).toList();
//                   if (docs.isEmpty) return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate"));

//                   return ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     itemCount: docs.length,
//                     itemBuilder: (context, index) {
//                       var data = docs[index].data() as Map<String, dynamic>;
//                       return _buildCard(data, docs[index].id, index == 0);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(Map<String, dynamic> data, String docId, bool isFirst) {
//     return GestureDetector(
//       onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailsPage(appointmentId: docId))),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 15),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: isFirst ? null : Colors.white,
//           gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(data['title'] ?? '', style: TextStyle(color: isFirst ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
//                 Text(data['location_name'] ?? '', style: TextStyle(color: isFirst ? Colors.white70 : Colors.grey)),
//               ],
//             ),
//             Text(data['time'] ?? '', style: TextStyle(color: isFirst ? Colors.white : const Color(0xFFD65A4A), fontSize: 22, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
// }
















// // what was in github: 
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter_application_1/appointment_page.dart'; 
// // import 'package:flutter_application_1/settings_page.dart'; 
// // import 'package:flutter_application_1/group_meeting_page.dart'; 
// // import 'package:flutter_application_1/appointment_details_page.dart'; 

// // class AppointmentScreen extends StatefulWidget {
// //   const AppointmentScreen({super.key});

// //   @override
// //   State<AppointmentScreen> createState() => _AppointmentScreenState();
// // }

// // class _AppointmentScreenState extends State<AppointmentScreen> {
// //   DateTime selectedDate = DateTime.now(); 
// //   bool showGroupOnly = false;

// //   final List<Map<String, dynamic>> staticAppointments = [
// //     {
// //       "id": "1",
// //       "title": "موعد طبيب الأسنان",
// //       "place": "عيادة الحكمة الحديثة",
// //       "time": "02:30",
// //       "date": DateTime(2025, 12, 25),
// //       "isGroup": false,
// //     },
// //     {
// //       "id": "2",
// //       "title": "اجتماع فريق التصميم",
// //       "place": "مكتب رقم 204",
// //       "time": "10:00",
// //       "date": DateTime(2025, 12, 25),
// //       "isGroup": true,
// //     },
// //   ];

// //   Future<void> pickDate() async {
// //     final DateTime? picked = await showDatePicker(
// //       context: context,
// //       initialDate: selectedDate,
// //       firstDate: DateTime(2020),
// //       lastDate: DateTime(2030),
// //       builder: (context, child) {
// //         return Theme(
// //           data: Theme.of(context).copyWith(
// //             colorScheme: const ColorScheme.light(primary: Color(0xFFD65A4A)),
// //           ),
// //           child: child!,
// //         );
// //       },
// //     );

// //     if (picked != null && picked != selectedDate) {
// //       setState(() {
// //         selectedDate = picked;
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

// //     String dbDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
// //     String displayDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

// //     return Scaffold(
// //       backgroundColor: bgColor,
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
// //           onPressed: () {},
// //         ),
// //         title: Image.asset(
// //           'assets/images/.png', 
// //           height: 40,
// //           errorBuilder: (context, error, stackTrace) => const Text("مرسال", 
// //             style: TextStyle(color: Color(0xFFD65A4A), fontWeight: FontWeight.bold)),
// //         ),
// //         centerTitle: true,
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.filter_list, color: Colors.black), 
// //             onPressed: pickDate,
// //           ),
// //           IconButton(
// //             icon: Icon(Icons.groups_outlined, color: showGroupOnly ? Colors.red : Colors.black),
// //             onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
// //           ),
// //         ],
// //       ),

// //       floatingActionButton: FloatingActionButton(
// //         backgroundColor: const Color(0xFFD65A4A),
// //         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentPage())).then((_) => setState(() {})),
// //         child: const Icon(Icons.add, color: Colors.white, size: 30),
// //       ),
// //       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

// //       bottomNavigationBar: BottomAppBar(
// //         shape: const CircularNotchedRectangle(),
// //         notchMargin: 8.0,
// //         child: SizedBox(
// //           height: 60,
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceAround,
// //             children: [
// //               IconButton(
// //                 icon: const Icon(Icons.person_outline, size: 32),
// //                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
// //               ),
// //               const SizedBox(width: 40),
// //               IconButton(
// //                 icon: const Icon(Icons.grid_view_rounded, size: 32, color: Color(0xFFD65A4A)), 
// //                 onPressed: () {},
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),

// //       body: Column(
// //         children: [
// //           Padding(
// //             padding: const EdgeInsets.all(20),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 const Text("مواعيدي", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
// //                 Text("التاريخ: $displayDate", style: const TextStyle(color: Colors.grey, fontSize: 16)),
// //               ],
// //             ),
// //           ),

// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('appointments')
// //                   .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
// //                   .where('date', isEqualTo: dbDate) 
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 List<Widget> listItems = [];

// //                 // 1. معالجة بيانات فايربيس (الديناميكية)
// //                 if (snapshot.hasData) {
// //                   for (var doc in snapshot.data!.docs) {
// //                     var data = doc.data() as Map<String, dynamic>;
// //                     data['id'] = doc.id; // حفظ الـ ID الحقيقي للربط
// //                     if (showGroupOnly && data['isGroup'] != true) continue;
// //                     listItems.add(_buildCard(data, listItems.isEmpty, isDark));
// //                   }
// //                 }

// //                 // 2. معالجة البيانات الثابتة (الستاتيك)
// //                 for (var app in staticAppointments) {
// //                    DateTime appDate = app['date'];
// //                    if (appDate.year == selectedDate.year && 
// //                        appDate.month == selectedDate.month &&
// //                        appDate.day == selectedDate.day) {
// //                      if (showGroupOnly && app['isGroup'] != true) continue;
// //                      listItems.add(_buildCard(app, listItems.isEmpty, isDark));
// //                    }
// //                 }

// //                 if (listItems.isEmpty) return Center(child: Text("لا توجد مواعيد بتاريخ $displayDate"));

// //                 return ListView(
// //                   padding: const EdgeInsets.symmetric(horizontal: 16),
// //                   children: listItems,
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildCard(Map<String, dynamic> data, bool isFirst, bool isDark) {
// //     bool isGroup = data['isGroup'] ?? false;
// //     String? appointmentId = data['id']; // نجيب الـ ID سواء كان ستاتيك أو فايربيس

// //     return GestureDetector(
// //       onTap: () {
// //         if (isGroup) {
// //           // إذا كان الموعد ستاتيك (1 أو 2)، نرسل نصاً فارغاً ليعرض التصميم الثابت
// //           if (appointmentId == "1" || appointmentId == "2" || appointmentId == null) {
// //             Navigator.push(
// //               context, 
// //               MaterialPageRoute(builder: (context) => const GroupMeetingPage(appointmentId: ""))
// //             );
// //           } else {
// //             // إذا كان موعداً جديداً، نرسل الـ ID ليعرض المشاركين الجدد من فايربيس
// //             Navigator.push(
// //               context, 
// //               MaterialPageRoute(builder: (context) => GroupMeetingPage(appointmentId: appointmentId))
// //             );
// //           }
// //         } else {
// //           Navigator.push(
// //             context, 
// //             MaterialPageRoute(builder: (context) => const AppointmentDetailsPage())
// //           );
// //         }
// //       },
// //       child: Container(
// //         margin: const EdgeInsets.only(bottom: 15),
// //         padding: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           color: isFirst ? null : Colors.white,
// //           gradient: isFirst ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)]) : null,
// //           borderRadius: BorderRadius.circular(25),
// //           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     data['title'] ?? '', 
// //                     style: TextStyle(
// //                       color: isFirst ? Colors.white : Colors.black, 
// //                       fontSize: 18, 
// //                       fontWeight: FontWeight.bold
// //                     )
// //                   ),
// //                   Text(
// //                     data['place'] ?? data['location'] ?? '', 
// //                     style: TextStyle(color: isFirst ? Colors.white70 : Colors.grey, fontSize: 14)
// //                   ),
// //                   if (isGroup) ...[
// //                     const SizedBox(height: 8),
// //                     const Text(
// //                       "موعد جماعي - اضغط للتفاصيل",
// //                       style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold),
// //                     ),
// //                   ]
// //                 ],
// //               ),
// //             ),
// //             Text(
// //               data['time'] ?? '', 
// //               style: TextStyle(
// //                 color: isFirst ? Colors.white : const Color(0xFFD65A4A), 
// //                 fontSize: 22, 
// //                 fontWeight: FontWeight.bold
// //               )
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
