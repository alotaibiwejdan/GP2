import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_appointment_page.dart'; // تأكدي من استيراد صفحة التعديل

class GroupMeetingPage extends StatefulWidget {
  final String appointmentId; 
  const GroupMeetingPage({super.key, this.appointmentId = ""});

  @override
  State<GroupMeetingPage> createState() => _GroupMeetingPageState();
}

class _GroupMeetingPageState extends State<GroupMeetingPage> {
  final TextEditingController _emailController = TextEditingController();

  final List<Map<String, dynamic>> staticRecipients = [
    {"email": "ahmed.h@gmail.com", "status": "وصل", "color": Colors.green, "arrived": true},
    {"email": "fatimah.a@gmail.com", "status": "لم يصل", "color": Colors.purple, "arrived": false},
    {"email": "yousef.m@gmail.com", "status": "وصل", "color": Colors.green, "arrived": true},
  ];

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.google.com/maps');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الخريطة حالياً');
    }
  }

  // دالة حذف الموعد مع رسالة تأكيد
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("حذف الموعد", textAlign: TextAlign.right),
        content: const Text("هل أنتِ متأكدة من حذف هذا الموعد؟ لا يمكن التراجع عن هذا الإجراء.", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (widget.appointmentId.isNotEmpty) {
                await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
              }
              Navigator.pop(context); // إغلاق الدايلوج
              Navigator.pop(context); // العودة للقائمة الرئيسية
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف الموعد بنجاح")));
            },
            child: const Text("حذف", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addNewPerson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة مستلم جديد', textAlign: TextAlign.center),
        content: TextField(
          controller: _emailController,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'أدخل البريد الإلكتروني', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                if (widget.appointmentId.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
                    'participants': FieldValue.arrayUnion([_emailController.text.trim()])
                  });
                }
                _emailController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.appointmentId.isEmpty) {
      return _buildMainUI(
        title: "اجتماع فريق التصميم",
        dateInfo: "الاثنين، ٢٥ ديسمبر - ١٠:٠٠ صباحاً",
        locationInfo: "مكتب رقم ٢٠٤",
        participants: staticRecipients.map((e) => e['email'].toString()).toList(),
        isStatic: true,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: Text("الموعد غير موجود")));

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List<String> participants = (data?['participants'] is List) ? List<String>.from(data?['participants']) : [];

        return _buildMainUI(
          title: data?['title'] ?? "موعد جماعي",
          dateInfo: "${data?['date'] ?? ''} - ${data?['time'] ?? ''}",
          locationInfo: data?['location'] ?? "لم يحدد الموقع",
          participants: participants,
          isStatic: false,
        );
      },
    );
  }

  Widget _buildMainUI({required String title, required String dateInfo, required String locationInfo, required List<String> participants, required bool isStatic}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAppointmentPage()));
              } else if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 10), Text("تعديل موعد")])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text("حذف موعد", style: TextStyle(color: Colors.red))])),
            ],
          ),
          title: Image.asset('assets/images/logo.png', height: 40, errorBuilder: (context, error, stackTrace) => const Text("مرسال", style: TextStyle(color: Color(0xFFC875A8), fontWeight: FontWeight.bold))),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.grey), onPressed: () => Navigator.pop(context))],
        ),
        body: Column(
          children: [
            GestureDetector(
              onTap: _openGoogleMaps,
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(image: NetworkImage('https://static.maps.2gis.com/1.0/staticmap?c=24.7136,46.6753&z=13&size=600,300'), fit: BoxFit.cover),
                ),
                child: Center(child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.location_on, color: Color(0xFFC875A8), size: 30))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today_outlined, dateInfo),
                  _buildInfoRow(Icons.location_on_outlined, locationInfo),
                  const SizedBox(height: 15),
                  Text("(${participants.length}) المستلمون", style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  String email = participants[index];
                  bool arrived = isStatic ? staticRecipients[index]['arrived'] : false;
                  String status = isStatic ? staticRecipients[index]['status'] : "لم يصل";
                  Color statusColor = isStatic ? staticRecipients[index]['color'] : Colors.purple;
                  return _buildUserCard(email, status, statusColor, arrived);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionArea(),
      ),
    );
  }

  // الدوال المساعدة (نفس ستايلك الأصلي)
  Widget _buildInfoRow(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13))]));

  Widget _buildUserCard(String email, String status, Color color, bool arrived) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
    child: ListTile(
      leading: const Icon(Icons.more_vert, color: Colors.grey),
      title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      trailing: Stack(alignment: Alignment.center, children: [const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF5F6F8), child: Icon(Icons.person, color: Colors.grey)), if (arrived) const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 8, backgroundColor: Colors.green, child: Icon(Icons.check, size: 10, color: Colors.white)))]),
    ),
  );

  Widget _buildBottomActionArea() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        InkWell(onTap: _addNewPerson, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.person_add_alt_1, color: Color(0xFFC875A8)))),
        const SizedBox(width: 12),
        Expanded(child: InkWell(onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال تذكير للمستلمين'))), child: Container(height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC875A8), Color(0xFFF86C5E)]), borderRadius: BorderRadius.circular(30)), child: const Center(child: Text("إرسال تذكير للجميع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
      ],
    ),
  );
}
