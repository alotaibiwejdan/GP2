import 'package:flutter/material.dart';
import 'group_meeting_page.dart';
import 'settings_page.dart';
import 'appointment_page.dart';

class Appointment {
  final String title;
  final String place;
  final String time;
  final DateTime date;
  final bool isGroup;

  Appointment({
    required this.title,
    required this.place,
    required this.time,
    required this.date,
    this.isGroup = false,
  });
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime selectedDate = DateTime(2025, 12, 25);
  bool showGroupOnly = false;

  final List<Appointment> allAppointments = [
    Appointment(
      title: "موعد طبيب الأسنان",
      place: "عيادة الحكمة الحديثة",
      time: "02:30",
      date: DateTime(2025, 12, 25),
    ),
    Appointment(
      title: "اجتماع فريق التصميم",
      place: "مكتب رقم 204",
      time: "10:00",
      date: DateTime(2025, 12, 25),
      isGroup: true,
    ),
    Appointment(
      title: "ورشة عمل",
      place: "قاعة الاجتماعات",
      time: "09:15",
      date: DateTime(2025, 12, 26),
    ),
  ];

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // الاعتماد على المتغير العام اللي في كودك (isGlobalDarkMode)
    final bgColor = isGlobalDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isGlobalDarkMode ? Colors.white : Colors.black;
    final appBarColor = isGlobalDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final filteredAppointments = allAppointments.where((appointment) {
      final sameDate = appointment.date.year == selectedDate.year &&
          appointment.date.month == selectedDate.month &&
          appointment.date.day == selectedDate.day;
      final groupFilter = showGroupOnly ? appointment.isGroup : true;
      return sameDate && groupFilter;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        // اللوقو في المنتصف بدال العنوان القديم
        title: Image.asset(
          'assets/images/logo.png', 
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Text("مرسال"),
        ),
        leading: IconButton(
          icon: const Icon(Icons.notifications_none),
          color: textColor,
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: textColor,
            onPressed: pickDate,
          ),
          IconButton(
            icon: Icon(
              Icons.groups,
              color: showGroupOnly ? const Color(0xFFD65A4A) : textColor,
            ),
            onPressed: () {
              setState(() {
                showGroupOnly = !showGroupOnly;
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD65A4A),
        onPressed: () {
          // ربط زر الزائد بصفحة الإضافة
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: appBarColor,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.person_outline, size: 28, color: textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((_) => setState(() {}));
                },
              ),
              IconButton(
                icon: Icon(Icons.grid_view_rounded, size: 26, color: textColor),
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
            // "مواعيدي" يمين والتاريخ مقابلها
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
                  "التاريخ: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (filteredAppointments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text("لا توجد مواعيد لهذا اليوم", style: TextStyle(color: textColor)),
                      ),
                    ),
                  ...filteredAppointments.map((appointment) {
                    final isFirstCard = appointment == filteredAppointments.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          if (appointment.isGroup) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GroupMeetingPage()),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: isFirstCard
                                ? const LinearGradient(colors: [Color(0xfff857a6), Color(0xffff5858)])
                                : null,
                            color: isFirstCard ? null : cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (isGlobalDarkMode || isFirstCard)
                                ? []
                                : [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.title,
                                    style: TextStyle(
                                      color: isFirstCard ? Colors.white : textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    appointment.place,
                                    style: TextStyle(
                                      color: isFirstCard ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                  if (appointment.isGroup)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        "موعد جماعي - اضغط للتفاصيل",
                                        style: TextStyle(
                                          color: isFirstCard ? Colors.white : Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                appointment.time,
                                style: TextStyle(
                                  color: isFirstCard ? Colors.white : const Color(0xFFD65A4A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
