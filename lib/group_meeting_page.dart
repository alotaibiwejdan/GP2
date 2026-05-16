import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:osm_nominatim/osm_nominatim.dart'; 
import 'package:geolocator/geolocator.dart';      
import 'package:latlong2/latlong.dart';          
import 'package:flutter/foundation.dart' show kIsWeb; 

// تأكدي من استيراد صفحة التعديل الموجودة في مشروعك
import 'edit_appointment_page.dart';

class GroupMeetingPage extends StatefulWidget {
  final String appointmentId; 
  const GroupMeetingPage({super.key, this.appointmentId = ""});

  @override
  State<GroupMeetingPage> createState() => _GroupMeetingPageState();
}

class _GroupMeetingPageState extends State<GroupMeetingPage> {
  final TextEditingController _emailController = TextEditingController();
  
  LatLng _appointmentLocation = const LatLng(24.7136, 46.6753); 
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _determinePosition(); 
  }

  // تحويل العنوان لإحداثيات (تستخدم location_name من الفايربيس)
  Future<void> _updateMapFromAddress(String address) async {
    if (address.isEmpty || address == "جاري التحميل...") return;
    try {
      final nominatim = Nominatim(userAgent: 'MersalApp'); 
      final List<Place> searchResult = await nominatim.searchByName(query: address);
      
      if (searchResult.isNotEmpty) {
        LatLng newLoc = LatLng(searchResult.first.lat, searchResult.first.lon);
        if (mounted && newLoc.latitude != _appointmentLocation.latitude) {
          setState(() {
            _appointmentLocation = newLoc;
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في تحديث الخريطة: $e");
    }
  }

  // جلب موقع المستخدم (متوافق مع ويب وجوال)
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("لم يتم الحصول على الموقع: $e");
    }
  }

  // فتح الخرائط (رابط عالمي يعمل في المتصفح وتطبيقات الجوال)
  Future<void> _openGoogleMaps() async {
    final String urlString = kIsWeb 
        ? "https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}"
        : "google.navigation:q=${_appointmentLocation.latitude},${_appointmentLocation.longitude}";
    
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
                await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
                  'participants': FieldValue.arrayUnion([_emailController.text.trim().toLowerCase()])
                });
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.hasData || !snapshot.data!.exists) return const Scaffold(body: Center(child: Text("الموعد غير موجود")));

        var data = snapshot.data!.data() as Map<String, dynamic>?;

        // جلب قائمة المشاركين الحقيقية من الداتابيز
        List<String> participants = [];
        if (data?['participants'] != null) {
          participants = List<String>.from(data?['participants']);
        }

        // استخدام 'location_name' ليطابق قاعدة البيانات عندك
        String addr = data?['location_name'] ?? "لا يوجد عنوان";
        _updateMapFromAddress(addr);

        return _buildMainUI(
          title: data?['title'] ?? "موعد جماعي",
          dateInfo: "${data?['date'] ?? ''} - ${data?['time'] ?? ''}",
          locationInfo: addr,
          participants: participants,
        );
      },
    );
  }

  Widget _buildMainUI({required String title, required String dateInfo, required String locationInfo, required List<String> participants}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("مرسال", style: TextStyle(color: Color(0xFFC875A8), fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [IconButton(icon: const Icon(Icons.arrow_forward, color: Colors.grey), onPressed: () => Navigator.pop(context))],
        ),
        body: Column(
          children: [
            // الخريطة
            GestureDetector(
              onTap: _openGoogleMaps,
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 160,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: _appointmentLocation, initialZoom: 13),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                      MarkerLayer(
                        markers: [
                          Marker(point: _appointmentLocation, child: const Icon(Icons.location_on, color: Color(0xFFC875A8), size: 35)),
                          if (_myLocation != null) Marker(point: _myLocation!, child: const Icon(Icons.my_location, color: Colors.blue, size: 25)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // تفاصيل الموعد
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
            // قائمة المشاركين
            Expanded(
              child: participants.isEmpty 
                ? const Center(child: Text("لا يوجد مشاركون مضافون"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) => _buildUserCard(participants[index]),
                  ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomActionArea(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13))]));

  Widget _buildUserCard(String email) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
    child: ListTile(
      title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: const Text("لم يصل", style: TextStyle(color: Colors.purple, fontSize: 12)),
      trailing: const CircleAvatar(radius: 20, backgroundColor: Color(0xFFF5F6F8), child: Icon(Icons.person, color: Colors.grey)),
    ),
  );

  Widget _buildBottomActionArea() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        InkWell(onTap: _addNewPerson, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.person_add_alt_1, color: Color(0xFFC875A8)))),
        const SizedBox(width: 12),
        Expanded(child: InkWell(onTap: () {}, child: Container(height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC875A8), Color(0xFFF86C5E)]), borderRadius: BorderRadius.circular(30)), child: const Center(child: Text("إرسال تذكير للجميع", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
      ],
    ),
  );
}
