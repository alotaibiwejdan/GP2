import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_meeting_page.dart';
import 'settings_page.dart';
import 'appointment_page.dart';

class Appointment {
  final String id;
  final String title;
  final String place;
  final String time;
  final DateTime date;
  final bool isGroup;
  final String notes;
  final bool smartNotifications;

  Appointment({
    required this.id,
    required this.title,
    required this.place,
    required this.time,
    required this.date,
    this.isGroup = false,
    this.notes = '',
    this.smartNotifications = false,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      title: data['title'] ?? '',
      place: data['location'] ?? '',
      time: data['time'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      isGroup: data['isGroup'] ?? false,
      notes: data['notes'] ?? '',
      smartNotifications: data['smartNotifications'] ?? false,
    );
  }
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime.now();
  bool showGroupOnly = false;

  final List<Appointment> staticAppointments = [
    Appointment(
      id: 'static_1',
      title: "موعد طبيب الأسنان",
      place: "عيادة الحكمة الحديثة",
      time: "02:30 م",
      date: DateTime(2025, 12, 25),
      isGroup: false,
    ),
    Appointment(
      id: 'static_2',
      title: "اجتماع فريق التصميم",
      place: "مكتب رقم 204",
      time: "10:00 ص",
      date: DateTime(2025, 12, 25),
      isGroup: true,
    ),
  ];

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Stream<List<Appointment>> _getFirebaseAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: formattedDate)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Appointment.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final formattedDateStr = "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
            "مرسال",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        leading: IconButton(
          icon: Icon(Icons.notifications_none, color: textColor),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: textColor),
            onPressed: pickDate,
          ),
          IconButton(
            icon: Icon(
              Icons.group,
              color: showGroupOnly ? const Color(0xFFD65A4A) : textColor,
            ),
            onPressed: () => setState(() => showGroupOnly = !showGroupOnly),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentPage()),
          ).then((_) => setState(() {}));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: appBarColor,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.person_outline, size: 28),
                color: textColor,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 26),
                color: textColor,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "مواعيدي",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  "التاريخ: $formattedDateStr",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Appointment>>(
                stream: _getFirebaseAppointments(),
                builder: (context, firebaseSnapshot) {
                  // ✅ 1. فحص حالة التحميل لمنع الخطأ عند أول تشغيل
                  if (firebaseSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ✅ 2. تصفية المواعيد الثابتة
                  final filteredStatic = staticAppointments.where((app) {
                    final sameDate = app.date.year == selectedDate.year &&
                        app.date.month == selectedDate.month &&
                        app.date.day == selectedDate.day;
                    final groupFilter = showGroupOnly ? app.isGroup : true;
                    return sameDate && groupFilter;
                  }).toList();

                  // ✅ 3. دمج القوائم بأمان (نتأكد أن بيانات Firebase ليست Null)
                  final List<Appointment> firebaseData = firebaseSnapshot.data ?? [];
                  final allAppointments = [...filteredStatic, ...firebaseData];

                  if (allAppointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: textColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "لا توجد مواعيد لهذا اليوم",
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor.withOpacity(0.6),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "اضغط + لإضافة موعد جديد",
                            style: TextStyle(
                              color: textColor.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: allAppointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final appointment = allAppointments[index];
                      final isFirst = index == 0;

                      return _buildAppointmentItem(
                        appointment: appointment,
                        isFirst: isFirst,
                        cardColor: cardColor,
                        textColor: textColor,
                      );
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

  Widget _buildAppointmentItem({
    required Appointment appointment,
    required bool isFirst,
    required Color cardColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: appointment.isGroup
          ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupMeetingPage()),
              )
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isFirst
              ? const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)])
              : null,
          color: isFirst ? null : cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (appointment.isGroup)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, color: Colors.green, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.title,
                    style: TextStyle(
                      color: isFirst ? Colors.white : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.place,
                    style: TextStyle(
                      color: isFirst ? Colors.white70 : Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (appointment.smartNotifications && !isFirst)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            "تنبيه ذكي مفعّل",
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              appointment.time,
              style: TextStyle(
                color: isFirst ? Colors.white : const Color(0xFFD65A4A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
