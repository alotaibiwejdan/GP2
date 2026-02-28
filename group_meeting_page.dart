import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupMeetingPage extends StatefulWidget {
  const GroupMeetingPage({super.key});

  @override
  State<GroupMeetingPage> createState() => _GroupMeetingPageState();
}

class _GroupMeetingPageState extends State<GroupMeetingPage> {
  // قائمة المستلمين الأساسية
  List<Map<String, dynamic>> recipients = [
    {"name": "أحمد حسن", "status": "وصل", "color": Colors.green, "arrived": true},
    {"name": "فاطمة العلي", "status": "لم يصل", "color": Colors.purple, "arrived": false},
    {"name": "يوسف محمد", "status": "وصل", "color": Colors.green, "arrived": true},
  ];

  final TextEditingController _nameController = TextEditingController();

  // دالة فتح قوقل ماب
  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=24.7136,46.6753');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الخريطة حالياً');
    }
  }

  // دالة إضافة شخص جديد للقائمة فعلياً
  void _addNewPerson() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة مستلم جديد', textAlign: TextAlign.center),
        content: TextField(
          controller: _nameController,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'أدخل اسم الشخص',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  // إضافة العضو الجديد للقائمة
                  recipients.add({
                    "name": _nameController.text,
                    "status": "لم يصل",
                    "color": Colors.purple,
                    "arrived": false
                  });
                });
                _nameController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة المستلم بنجاح')),
                );
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const Icon(Icons.more_vert, color: Colors.grey),
          title: Image.asset(
            'assets/images/logo.png', 
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.send, color: Color(0xFFC875A8)),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // الخريطة
            GestureDetector(
              onTap: _openGoogleMaps,
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage('https://static.maps.2gis.com/1.0/staticmap?c=24.7136,46.6753&z=13&size=600,300'), 
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: Color(0xFFC875A8), size: 30),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("اجتماع فريق التسويق الأسبوعي", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildInfo(Icons.calendar_today_outlined, "الاثنين، ٢٥ ديسمبر - ٠٢:٠٠ مساءً"),
                  _buildInfo(Icons.location_on_outlined, "مكتب الشركة، قاعة الاجتماعات ٣"),
                  const SizedBox(height: 15),
                  // تعديل عداد المستلمين ليكون ديناميكي (عدد القائمة الحقيقي / 10)
                 Text(
  "(${recipients.length} / ∞) المستلمون", 
  style: const TextStyle(
    color: Colors.grey, 
    fontSize: 13, 
    fontWeight: FontWeight.bold,
  ),
),
                ],
              ),
            ),

            // قائمة الحضور الديناميكية
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipients.length,
                itemBuilder: (context, index) {
                  final person = recipients[index];
                  return _buildUserTile(
                    person['name'], 
                    person['status'], 
                    person['color'], 
                    person['arrived']
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildUserTile(String name, String status, Color color, bool arrived) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: const Icon(Icons.more_vert, color: Colors.grey),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        trailing: Stack(
          alignment: Alignment.center,
          children: [
            const CircleAvatar(
              radius: 24, 
              backgroundColor: Color(0xFFF5F6F8), 
              child: Icon(Icons.person, color: Colors.grey)
            ),
            if (arrived) 
              const Positioned(
                bottom: 0, 
                right: 0, 
                child: CircleAvatar(
                  radius: 8, 
                  backgroundColor: Colors.green, 
                  child: Icon(Icons.check, size: 10, color: Colors.white)
                )
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // زر إضافة أشخاص - الآن يضيف فعلياً
          InkWell(
            onTap: _addNewPerson,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.person_add_alt_1, color: Color(0xFFC875A8)),
            ),
          ),
          const SizedBox(width: 12),
          // زر إرسال التذكير
          Expanded(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال تذكير للجميع')),
                );
              },
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFC875A8), Color(0xFFF86C5E)]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text("إرسال تذكير للجميع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}