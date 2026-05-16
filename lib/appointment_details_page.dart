import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// تأكدي من وجود هذا الملف في مشروعك
import 'edit_appointment_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  LatLng _appointmentLocation = const LatLng(24.7136, 46.6753);
  LatLng? _myLocation;
  String _addressTitle = "جاري تحميل العنوان...";
  bool _isMapLoading = true;

  final Color mersalPurple = const Color(0xFFBB86FC);
  final Color mersalGreyBG = const Color(0xFFFAFBFD);
  final Color deleteIconRed = const Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _determinePosition();
    try {
      var doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      // تم تعديل المسمى هنا من location إلى location_name ليطابق الفايربيس عندك
      if (doc.exists && doc.data()?['location_name'] != null) {
        String actualAddress = doc.data()?['location_name'];
        setState(() {
          _addressTitle = actualAddress;
        });
        await _updateMapFromAddress(actualAddress);
      } else {
        await _updateMapFromAddress("Riyadh");
      }
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
      setState(() => _addressTitle = "تعذر تحميل العنوان");
    }
  }

  // دالة البحث المحسنة لتجنب مشاكل الويب (CORS)
  Future<void> _updateMapFromAddress(String address) async {
    if (address.isEmpty) return;
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(address)}&limit=1');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mersal_App_University_Project',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);
          
          if (mounted) {
            setState(() {
              _appointmentLocation = LatLng(lat, lon);
              _isMapLoading = false;
            });
          }
        } else {
           setState(() => _isMapLoading = false);
        }
      }
    } catch (e) {
      debugPrint("خطأ في تحديث الخريطة: $e");
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("لم يتم تحديد موقع المستخدم: $e");
    }
  }

  void _launchGoogleMaps() async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: mersalGreyBG,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("تفاصيل الموعد", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              _buildDepartureCard(),
              const SizedBox(height: 20),

              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: _isMapLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8EAC)))
                          : FlutterMap(
                              options: MapOptions(
                                initialCenter: _appointmentLocation,
                                initialZoom: 14,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  userAgentPackageName: 'com.mersal.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _appointmentLocation,
                                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                    ),
                                    if (_myLocation != null)
                                      Marker(
                                        point: _myLocation!,
                                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: ElevatedButton.icon(
                      onPressed: _launchGoogleMaps,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text("فتح في قوقل ماب"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildMersalTile(
                icon: Icons.location_on_outlined,
                content: Text(_addressTitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ),
              const SizedBox(height: 15),
              _buildMersalTile(
                icon: Icons.sticky_note_2_outlined,
                content: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ملاحظات", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("لا توجد ملاحظات إضافية", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // البيلدرز (نفس اللي في كودك بدون تغيير لتعديل الشكل)
  Widget _buildDepartureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
            child: const Icon(Icons.directions_car, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("الوقت المقترح للمغادرة", 
                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("غادر بحلول الساعة 3:45 مساءً", 
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            // كود الحذف
            await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: deleteIconRed.withOpacity(0.2)),
            ),
            child: Icon(Icons.delete_outline, color: deleteIconRed, size: 26),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
// شلنا كلمة const وأضفنا الـ appointmentId اللي الصفحة محتاجته
onTap: () => Navigator.push(
  context, 
  MaterialPageRoute(
    builder: (context) => EditAppointmentPage(appointmentId: widget.appointmentId),
  ),
),            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(child: Text("تعديل", style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تأكيد الحضور")));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB6A1), Color(0xFFFF8EAC)]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF8EAC).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              child: const Center(child: Text("تأكيد الحضور", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMersalTile({required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: mersalPurple, size: 24),
          const SizedBox(width: 15),
          Expanded(child: content),
        ],
      ),
    );
  }
}
