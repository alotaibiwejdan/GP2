import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'settings_page.dart';
import 'edit_appointment_page.dart';

// ملاحظة لـ وجدان: الكود يدعم الوضع الليلي والنهاري وحساب تأخير الطقس بالنسبة المئوية
class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  LatLng _appointmentLocation = const LatLng(24.7136, 46.6753);
  LatLng? _myLocation;
  String _addressTitle = "جاري التحميل...";
  String _notes = "";
  String _creatorId = "";
  String _appointmentTimeStr = "";
  List<Map<String, dynamic>> _participantsData = [];
  String _exactDepartureTime = "--:--";
  String _weatherAndDuration = "جاري الحساب...";

  // متغير عام للثيم (تأكدي من تعريفه في مشروعك أو استبداله بـ Theme.of(context))
  bool get isGlobalDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _determinePosition();
    await _fetchAppointmentDetails();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        _calculateDeparture();
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _fetchAppointmentDetails() async {
    var doc = await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).get();
    if (doc.exists && mounted) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _addressTitle = data['location_name'] ?? "";
        _notes = data['notes'] ?? "";
        _creatorId = data['userId'] ?? "";
        _appointmentTimeStr = data['time'] ?? "04:00 PM";
      });
      _fetchParticipants(data['participants'] ?? []);
      _updateMapCenter(_addressTitle);
    }
  }

  // --- دالة تنبيه المطر (اطلع بدري) ---
  void _showWeatherAlert(int weatherCode) {
    if (weatherCode >= 51) {
      String msg = (weatherCode <= 67) 
          ? "تنبيه: فيه مطر خفيف جاي، يفضل تطلع بدري عشان الزحمة! 🌧️"
          : "تنبيه قوي: فيه مطر غزير، اطلعي بدري جداً وانتبهي من الطريق! ⛈️";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _calculateDeparture() async {
    if (_myLocation == null) return;

    // 1. حساب المسافة والوقت الأساسي (دقيقة ونصف لكل كيلو متر + 5 دقائق احتياط)
    double distanceInMeters = Geolocator.distanceBetween(
        _myLocation!.latitude, _myLocation!.longitude,
        _appointmentLocation.latitude, _appointmentLocation.longitude
    );
    int baseTravelMinutes = ((distanceInMeters / 1000) * 1.5).round() + 5;

    // 2. جلب حالة الطقس وتحديد نسبة التأخير
    double delayFactor = 0.10; // 10% تأخير افتراضي للزحام العادي
    String weatherStatus = "صافي";

    try {
      final res = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${_appointmentLocation.latitude}&longitude=${_appointmentLocation.longitude}&current_weather=true'));

      if (res.statusCode == 200) {
        final wData = json.decode(res.body);
        int code = wData['current_weather']['weathercode'];
        
        _showWeatherAlert(code); // استدعاء التنبيه

        if (code >= 51 && code <= 67) {
          delayFactor = 0.30; // زيادة 30% للمطر
          weatherStatus = "ممطر";
        } else if (code > 67) {
          delayFactor = 0.50; // زيادة 50% للظروف الصعبة
          weatherStatus = "ظروف جوية صعبة";
        }
      }
    } catch (e) {
      delayFactor = 0.15; 
    }

    // 3. تطبيق النسبة وحساب وقت المغادرة
    int totalTravelTime = (baseTravelMinutes * (1 + delayFactor)).round();

    try {
      int hour = int.parse(_appointmentTimeStr.split(':')[0]);
      int minute = int.parse(_appointmentTimeStr.split(':')[1].split(' ')[0]);
      if (_appointmentTimeStr.contains('PM') && hour != 12) hour += 12;
      if (_appointmentTimeStr.contains('AM') && hour == 12) hour = 0;

      DateTime now = DateTime.now();
      DateTime appTime = DateTime(now.year, now.month, now.day, hour, minute);
      DateTime departTime = appTime.subtract(Duration(minutes: totalTravelTime));

      if (mounted) {
        setState(() {
          _exactDepartureTime = "${departTime.hour % 12 == 0 ? 12 : departTime.hour % 12}:${departTime.minute.toString().padLeft(2, '0')} ${departTime.hour >= 12 ? 'PM' : 'AM'}";
          _weatherAndDuration = "الطقس: $weatherStatus | زيادة ${(delayFactor * 100).round()}% بسبب الظروف";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exactDepartureTime = "خطأ في الوقت");
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف هذا الموعد؟", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = isGlobalDarkMode;
    String myId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> confirmed = [];
        List participants = [];
        bool isCreator = false;
        bool isGroup = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          confirmed = d['confirmedParticipants'] ?? [];
          participants = d['participants'] ?? [];
          isCreator = (myId == (d['userId'] ?? ""));
          isGroup = participants.length > 1;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFBFD),
            appBar: AppBar(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              title: Text("تفاصيل الموعد", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _buildDepartureCard(isDarkMode),
                const SizedBox(height: 20),
                _buildMapSection(),
                const SizedBox(height: 20),
                _buildTile(Icons.location_on_outlined, _addressTitle, isDarkMode),
                const SizedBox(height: 15),
                if (isGroup) ...[
                  GestureDetector(
                    onTap: () => _showParticipantsStatus(confirmed, isDarkMode),
                    child: _buildParticipantsTile(confirmed, isDarkMode),
                  ),
                  const SizedBox(height: 15),
                ],
                _buildTile(Icons.sticky_note_2_outlined, _notes.isEmpty ? "لا توجد ملاحظات" : _notes, isDarkMode),
                const SizedBox(height: 35),
                _buildDynamicActionButtons(isCreator, isGroup, confirmed, isDarkMode),
              ]),
            ),
          ),
        );
      },
    );
  }

  // --- دوال بناء الواجهة (UI Widgets) ---

  Widget _buildDepartureCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C1A1A) : const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.directions_car, color: Colors.redAccent)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("الوقت المقترح للمغادرة", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          Text("غادر بحلول الساعة $_exactDepartureTime", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 5),
          Text(_weatherAndDuration, style: const TextStyle(fontSize: 10, color: Colors.red)),
        ]))
      ]),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(height: 220, child: FlutterMap(
            options: MapOptions(initialCenter: _appointmentLocation, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.example.flutter_application_1'),
              MarkerLayer(markers: [
                Marker(point: _appointmentLocation, child: const Icon(Icons.location_pin, color: Colors.red, size: 45)),
                if (_myLocation != null)
                  Marker(point: _myLocation!, child: const Icon(Icons.circle, color: Colors.blue, size: 18)),
              ]),
            ],
          )),
        ),
        Positioned(bottom: 10, left: 10, child: FloatingActionButton.small(backgroundColor: Colors.white, onPressed: _launchGoogleMaps, child: const Icon(Icons.directions, color: Colors.blue))),
      ],
    );
  }

  Widget _buildTile(IconData i, String t, bool isDarkMode) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02), blurRadius: 10)]),
    child: Row(children: [Icon(i, color: Colors.purpleAccent), const SizedBox(width: 15), Expanded(child: Text(t, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))]),
  );

  Widget _buildParticipantsTile(List<dynamic> confirmed, bool isDarkMode) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Text("المشاركون (${_participantsData.length})", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
      const Spacer(),
      SizedBox(height: 35, width: 80, child: Stack(children: List.generate(_participantsData.length > 3 ? 3 : _participantsData.length, (i) {
        return Positioned(right: i * 18.0, child: CircleAvatar(radius: 17, backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white, child: CircleAvatar(radius: 15, backgroundColor: Colors.grey[300], child: Text(_participantsData[i]['name'][0].toUpperCase(), style: const TextStyle(fontSize: 10)))));
      }))),
      Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.white60 : Colors.grey),
    ]),
  );

  Widget _buildDynamicActionButtons(bool isCreator, bool isGroup, List<dynamic> confirmed, bool isDarkMode) {
    if (!isGroup || isCreator) {
      return Row(children: [
        Expanded(flex: 4, child: _gradBtn("تعديل الموعد", () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => EditAppointmentPage(appointmentId: widget.appointmentId)));
          _loadAllData();
        })),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _deleteIconButton()),
      ]);
    } else {
      bool isMeIn = confirmed.contains(FirebaseAuth.instance.currentUser?.email);
      return Row(children: [
        Expanded(flex: 4, child: _gradBtn(isMeIn ? "تم تأكيد الحضور" : "تأكيد الحضور", () async {
          if (!isMeIn) {
            await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
              'confirmedParticipants': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.email])
            });
          }
        }, isGreen: isMeIn)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _deleteIconButton()),
      ]);
    }
  }

  Widget _gradBtn(String t, VoidCallback o, {bool isGreen = false}) => Container(
    width: double.infinity, height: 50,
    decoration: BoxDecoration(gradient: LinearGradient(colors: isGreen ? [Colors.green, Colors.greenAccent] : [const Color(0xFFFFB6A1), const Color(0xFFFF8EAC)]), borderRadius: BorderRadius.circular(15)),
    child: ElevatedButton(onPressed: o, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );

  Widget _deleteIconButton() => Container(
    height: 50, decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(15)),
    child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _confirmDelete),
  );

  void _showParticipantsStatus(List<dynamic> confirmed, bool isDarkMode) {
    showModalBottomSheet(context: context, backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("قائمة الحضور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), const Divider(), ..._participantsData.map((u) { bool arrived = confirmed.contains(u['email']); return ListTile(leading: CircleAvatar(child: Text(u['name'][0].toUpperCase())), title: Text(u['name'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)), trailing: Text(arrived ? "تم الوصول" : "في الطريق", style: TextStyle(color: arrived ? Colors.green : Colors.orange))); }).toList()])));
  }

  Future<void> _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
  }

  Future<void> _fetchParticipants(List<dynamic> emails) async {
    List<Map<String, dynamic>> temp = [];
    for (var e in emails) { 
      var s = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: e).get();
      temp.add({'name': s.docs.isNotEmpty ? s.docs.first['name'] : e, 'email': e}); 
    }
    if (mounted) setState(() => _participantsData = temp);
  }

  Future<void> _updateMapCenter(String addr) async {
    try {
      final res = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$addr'));
      if (res.statusCode == 200) { 
        final d = json.decode(res.body); 
        if (d.isNotEmpty && mounted) { 
          setState(() => _appointmentLocation = LatLng(double.parse(d[0]['lat']), double.parse(d[0]['lon'])));
          _calculateDeparture(); 
        } 
      }
    } catch (e) { debugPrint("Map error"); }
  }
}
/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'settings_page.dart';
import 'edit_appointment_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  // أضفت تمرير البيانات لضمان سرعة التحميل ومعرفة نوع الموعد
  final Map<String, dynamic> appointmentData; 

  const AppointmentDetailsPage({
    super.key, 
    required this.appointmentId, 
    required this.appointmentData, required Map<dynamic, dynamic> Date
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  LatLng _appointmentLocation = const LatLng(24.7136, 46.6753);
  LatLng? _myLocation;
  String _addressTitle = "جاري التحميل...";
  String _notes = "";
  String _creatorId = "";
  String _appointmentTimeStr = "";
  List<Map<String, dynamic>> _participantsData = [];
  String _exactDepartureTime = "--:--";
  String _weatherAndDuration = "جاري الحساب...";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _determinePosition();
    await _fetchAppointmentDetails();
  }

  // --- جميع دوال الحساب والطقس والموقع من كودك الأصلي بدون تغيير ---
  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        _calculateDeparture();
      }
    } catch (e) {
      debugPrint("Location error");
    }
  }

  Future<void> _fetchAppointmentDetails() async {
    var doc = await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).get();
    if (doc.exists && mounted) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _addressTitle = data['location_name'] ?? "";
        _notes = data['notes'] ?? "";
        _creatorId = data['userId'] ?? "";
        _appointmentTimeStr = data['time'] ?? "04:00 PM";
      });
      _fetchParticipants(data['participants'] ?? []);
      _updateMapCenter(_addressTitle);
    }
  }

  Future<void> _calculateDeparture() async {
    if (_myLocation == null) return;
    double distanceInMeters = Geolocator.distanceBetween(
        _myLocation!.latitude, _myLocation!.longitude,
        _appointmentLocation.latitude, _appointmentLocation.longitude
    );

    int baseTravelMinutes = ((distanceInMeters / 1000) * 1.5).round() + 5;
    String weatherInfo = "الطقس غير متاح";
    int weatherExtraMinutes = 0;
    try {
      final res = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${_appointmentLocation.latitude}&longitude=${_appointmentLocation.longitude}&current_weather=true'));

      if (res.statusCode == 200) {
        final wData = json.decode(res.body);
        int code = wData['current_weather']['weathercode'];
        double temp = wData['current_weather']['temperature'];

        if (code >= 51 && code <= 67) {
          weatherExtraMinutes = (baseTravelMinutes * 0.30).round();
        } else if (code > 67) {
          weatherExtraMinutes = (baseTravelMinutes * 0.50).round();
        }
        weatherInfo = "الطقس: ${temp.round()}C ${_getWeatherDesc(code)}";
      }
    } catch (e) {
      debugPrint("Weather error");
    }
    int totalTravelTime = baseTravelMinutes + weatherExtraMinutes;
    try {
      int hour = int.parse(_appointmentTimeStr.split(':')[0]);
      int minute = int.parse(_appointmentTimeStr.split(':')[1].split(' ')[0]);
      if (_appointmentTimeStr.contains('PM') && hour != 12) hour += 12;
      if (_appointmentTimeStr.contains('AM') && hour == 12) hour = 0;
      DateTime now = DateTime.now();
      DateTime appTime = DateTime(now.year, now.month, now.day, hour, minute);
      DateTime departTime = appTime.subtract(Duration(minutes: totalTravelTime));
      if (mounted) {
        setState(() {
          _exactDepartureTime = "${departTime.hour % 12 == 0 ? 12 : departTime.hour % 12}:${departTime.minute.toString().padLeft(2, '0')} ${departTime.hour >= 12 ? 'PM' : 'AM'}";
          String rainNote = weatherExtraMinutes > 0 ? " (إضافة $weatherExtraMinutes د للطقس)" : "";
          _weatherAndDuration = "$weatherInfo | الطريق: $totalTravelTime دقيقة$rainNote";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exactDepartureTime = "غير متاح");
    }
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return "صافي";
    if (code <= 3) return "غائم جزئياً";
    if (code <= 48) return "ضباب";
    if (code <= 67) return "ممطر";
    return "مشمس";
  }

  // --- دالة الحذف الجديدة ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف هذا الموعد؟", textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  // 🔥 فقط هذا الجزء تغيّر (داخل build)

@override
Widget build(BuildContext context) {
  bool isDarkMode = isGlobalDarkMode;
  String myId = FirebaseAuth.instance.currentUser?.uid ?? "";

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .snapshots(),
    builder: (context, snapshot) {

      List<dynamic> confirmed = [];
      List participants = [];
      bool isCreator = false;
      bool isGroup = false;

      if (snapshot.hasData && snapshot.data!.exists) {
        var d = snapshot.data!.data() as Map<String, dynamic>;

        confirmed = d['confirmedParticipants'] ?? [];
        participants = d['participants'] ?? [];

        // ✅ تحديد المنظم
        isCreator = (myId == (d['userId'] ?? ""));

        // ✅ تحديد جماعي أو فردي
        isGroup = participants.length > 1;
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor:
              isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFBFD),
          appBar: AppBar(
            backgroundColor:
                isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            title: Text("تفاصيل الموعد",
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              _buildDepartureCard(isDarkMode),
              const SizedBox(height: 20),
              _buildMapSection(),
              const SizedBox(height: 20),
              _buildTile(Icons.location_on_outlined, _addressTitle, isDarkMode),
              const SizedBox(height: 15),

              // 👥 المشاركين (فقط لو جماعي)
              if (isGroup) ...[
                GestureDetector(
                  onTap: () =>
                      _showParticipantsStatus(confirmed, isDarkMode),
                  child: _buildParticipantsTile(confirmed, isDarkMode),
                ),
                const SizedBox(height: 15),
              ],

              _buildTile(
                  Icons.sticky_note_2_outlined,
                  _notes.isEmpty ? "لا توجد ملاحظات" : _notes,
                  isDarkMode),

              const SizedBox(height: 35),

              // 🔥 الأزرار حسب الحالة
              _buildDynamicActionButtons(
                  isCreator, isGroup, confirmed, isDarkMode),
            ]),
          ),
        ),
      );
    },
  );
}
  Widget _buildDynamicActionButtons(bool isCreator, bool isGroup, List<dynamic> confirmed, bool isDarkMode) {
    if (!isGroup) {
      return Row(
        children: [
          Expanded(flex: 4, child: _gradBtn("تعديل الموعد", () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditAppointmentPage(
        appointmentId: widget.appointmentId,
      ),
    ),
  );

  _loadAllData(); // 🔥 تحديث بعد الرجوع
}),),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: _deleteIconButton()),
        ],
      );
    } else {
      if (isCreator) {
        return Column(
          children: [
            _gradBtn("إرسال تذكير للمشاركين", _sendReminder, colorSet: [const Color(0xFFD8B4FE), const Color(0xFFFBC2EB)]),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 4, child: _gradBtn("تعديل الموعد", () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditAppointmentPage(
        appointmentId: widget.appointmentId,
      ),
    ),
  );

  _loadAllData(); // 🔥 تحديث بعد الرجوع
}),),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _deleteIconButton()),
              ],
            ),
          ],
        );
      } else {
        // إذا كان مدعو: تأكيد الحضور وزبالة
        bool isMeIn = confirmed.contains(FirebaseAuth.instance.currentUser?.email);
        return Row(
          children: [
            Expanded(
              flex: 4,
              child: _gradBtn(isMeIn ? "تم تأكيد الحضور" : "تأكيد الحضور", () async {
                if (!isMeIn) {
                  await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
                    'confirmedParticipants': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.email])
                  });
                }
              }, isGreen: isMeIn),
            ),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _deleteIconButton()),
          ],
        );
      }
    }
  }

  Widget _deleteIconButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: _confirmDelete,
      ),
    );
  }

  Widget _gradBtn(String t, VoidCallback o, {bool isGreen = false, List<Color>? colorSet}) => Container(
    width: double.infinity, height: 50,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colorSet ?? (isGreen ? [Colors.green, Colors.greenAccent] : [const Color(0xFFFFB6A1), const Color(0xFFFF8EAC)])
      ), 
      borderRadius: BorderRadius.circular(15)
    ),
    child: ElevatedButton(onPressed: o, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );

  Widget _buildDepartureCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C1A1A) : const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.directions_car, color: Colors.redAccent)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("الوقت المقترح للمغادرة", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          Text("غادر بحلول الساعة $_exactDepartureTime", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 5),
          Text(_weatherAndDuration, style: const TextStyle(fontSize: 10, color: Colors.red)),
        ]))
      ]),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(height: 220, child: FlutterMap(
            options: MapOptions(initialCenter: _appointmentLocation, initialZoom: 14),
            children: [
             TileLayer(
  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  userAgentPackageName: 'com.example.flutter_application_1ٌ',
),
              MarkerLayer(markers: [
                Marker(point: _appointmentLocation, child: const Icon(Icons.location_pin, color: Colors.red, size: 45)),
                if (_myLocation != null)
                  Marker(point: _myLocation!, child: const Icon(Icons.circle, color: Colors.blue, size: 18)),
              ]),
            ],
          )),
        ),
        Positioned(bottom: 10, left: 10, child: FloatingActionButton.small(backgroundColor: Colors.white, onPressed: _launchGoogleMaps, child: const Icon(Icons.directions, color: Colors.blue))),
      ],
    );
  }

  Future<void> _sendReminder() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري إرسال التنبيهات للمشاركين")));
    for (var p in _participantsData) {
      var userSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: p['email']).get();
      if (userSnap.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': userSnap.docs.first.id,
          'title': 'تذكير بموعد',
          'body': 'إشعار بخصوص الموعد في: $_addressTitle',
          'is_read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال التنبيهات بنجاح")));
  }

  Widget _buildTile(IconData i, String t, bool isDarkMode) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02), blurRadius: 10)]),
    child: Row(children: [Icon(i, color: Colors.purpleAccent), const SizedBox(width: 15), Expanded(child: Text(t, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))]),
  );

  Widget _buildParticipantsTile(List<dynamic> confirmed, bool isDarkMode) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Text("المشاركون (${_participantsData.length})", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
      const Spacer(),
      SizedBox(height: 35, width: 80, child: Stack(children: List.generate(_participantsData.length > 3 ? 3 : _participantsData.length, (i) {
        return Positioned(right: i * 18.0, child: CircleAvatar(radius: 17, backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white, child: CircleAvatar(radius: 15, backgroundColor: Colors.grey[300], child: Text(_participantsData[i]['name'][0].toUpperCase(), style: const TextStyle(fontSize: 10)))));
      }))),
      Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.white60 : Colors.grey),
    ]),
  );

  void _showParticipantsStatus(List<dynamic> confirmed, bool isDarkMode) {
    showModalBottomSheet(context: context, backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("قائمة الحضور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), const Divider(), ..._participantsData.map((u) { bool arrived = confirmed.contains(u['email']); return ListTile(leading: CircleAvatar(child: Text(u['name'][0].toUpperCase())), title: Text(u['name'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)), trailing: Text(arrived ? "تم الوصول" : "في الطريق", style: TextStyle(color: arrived ? Colors.green : Colors.orange))); }).toList()])));
  }

  Future<void> _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
  }

  Future<void> _fetchParticipants(List<dynamic> emails) async {
    List<Map<String, dynamic>> temp = [];
    for (var e in emails) { 
      var s = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: e).get();
      temp.add({'name': s.docs.isNotEmpty ? s.docs.first['name'] : e, 'email': e}); 
    }
    if (mounted) setState(() => _participantsData = temp);
  }

  Future<void> _updateMapCenter(String addr) async {
    try {
      final res = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$addr'));
      if (res.statusCode == 200) { 
        final d = json.decode(res.body); 
        if (d.isNotEmpty && mounted) { 
          setState(() => _appointmentLocation = LatLng(double.parse(d[0]['lat']), double.parse(d[0]['lon'])));
          _calculateDeparture(); 
        } 
      }
    } catch (e) { debugPrint("Map error"); }
  }
}
/*import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'settings_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  LatLng _appointmentLocation = const LatLng(24.7136, 46.6753);
  LatLng? _myLocation;
  String _addressTitle = "جاري التحميل...";
  String _notes = "";
  String _creatorId = "";
  String _appointmentTimeStr = ""; 
  List<Map<String, dynamic>> _participantsData = [];
  String _exactDepartureTime = "--:--";
  String _weatherAndDuration = "جاري الحساب...";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _determinePosition();
    await _fetchAppointmentDetails();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        _calculateDeparture(); 
      }
    } catch (e) {
      debugPrint("Location error");
    }
  }

  Future<void> _fetchAppointmentDetails() async {
    var doc = await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).get();
    if (doc.exists && mounted) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _addressTitle = data['location_name'] ?? "";
        _notes = data['notes'] ?? "";
        _creatorId = data['userId'] ?? "";
        _appointmentTimeStr = data['time'] ?? "04:00 PM";
      });
      _fetchParticipants(data['participants'] ?? []);
      _updateMapCenter(_addressTitle);
    }
  }

  Future<void> _calculateDeparture() async {
    if (_myLocation == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
      _myLocation!.latitude, _myLocation!.longitude,
      _appointmentLocation.latitude, _appointmentLocation.longitude
    );
    
    int baseTravelMinutes = ((distanceInMeters / 1000) * 1.5).round() + 5;
    String weatherInfo = "الطقس غير متاح";
    int weatherExtraMinutes = 0; 

    try {
      final res = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${_appointmentLocation.latitude}&longitude=${_appointmentLocation.longitude}&current_weather=true'));
      
      if (res.statusCode == 200) {
        final wData = json.decode(res.body);
        int code = wData['current_weather']['weathercode'];
        double temp = wData['current_weather']['temperature'];
        
        if (code >= 51 && code <= 67) { 
          weatherExtraMinutes = (baseTravelMinutes * 0.30).round();
        } else if (code > 67) { 
          weatherExtraMinutes = (baseTravelMinutes * 0.50).round();
        }
        weatherInfo = "الطقس: ${temp.round()}C ${_getWeatherDesc(code)}";
      }
    } catch (e) {
      debugPrint("Weather error");
    }

    int totalTravelTime = baseTravelMinutes + weatherExtraMinutes;

    try {
      int hour = int.parse(_appointmentTimeStr.split(':')[0]);
      int minute = int.parse(_appointmentTimeStr.split(':')[1].split(' ')[0]);
      if (_appointmentTimeStr.contains('PM') && hour != 12) hour += 12;
      if (_appointmentTimeStr.contains('AM') && hour == 12) hour = 0;

      DateTime now = DateTime.now();
      DateTime appTime = DateTime(now.year, now.month, now.day, hour, minute);
      DateTime departTime = appTime.subtract(Duration(minutes: totalTravelTime));

      if (mounted) {
        setState(() {
          _exactDepartureTime = "${departTime.hour % 12 == 0 ? 12 : departTime.hour % 12}:${departTime.minute.toString().padLeft(2, '0')} ${departTime.hour >= 12 ? 'PM' : 'AM'}";
          String rainNote = weatherExtraMinutes > 0 ? " (إضافة $weatherExtraMinutes د للطقس)" : "";
          _weatherAndDuration = "$weatherInfo | الطريق: $totalTravelTime دقيقة$rainNote";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exactDepartureTime = "غير متاح");
    }
  }

  String _getWeatherDesc(int code) {
    if (code == 0) return "صافي";
    if (code <= 3) return "غائم جزئياً";
    if (code <= 48) return "ضباب";
    if (code <= 67) return "ممطر";
    return "مشمس";
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = isGlobalDarkMode; 
    String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    bool isCreator = (myId == _creatorId);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> confirmed = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          confirmed = d.containsKey('confirmedParticipants') ? d['confirmedParticipants'] : [];
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFBFD),
            appBar: AppBar(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              title: Text("تفاصيل الموعد", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
              leading: IconButton(icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _buildDepartureCard(isDarkMode),
                const SizedBox(height: 20),
                _buildMapSection(),
                const SizedBox(height: 20),
                _buildTile(Icons.location_on_outlined, _addressTitle, isDarkMode),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _showParticipantsStatus(confirmed, isDarkMode),
                  child: _buildParticipantsTile(confirmed, isDarkMode),
                ),
                const SizedBox(height: 15),
                _buildTile(Icons.sticky_note_2_outlined, _notes.isEmpty ? "لا توجد ملاحظات" : _notes, isDarkMode),
                const SizedBox(height: 35),
                _buildActionButtons(isCreator, confirmed, isDarkMode),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartureCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C1A1A) : const Color(0xFFFFF7F7), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.directions_car, color: Colors.redAccent)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("الوقت المقترح للمغادرة", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          Text("غادر بحلول الساعة $_exactDepartureTime", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 5),
          Text(_weatherAndDuration, style: const TextStyle(fontSize: 10, color: Colors.red)),
        ]))
      ]),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: SizedBox(height: 220, child: FlutterMap(
            options: MapOptions(initialCenter: _appointmentLocation, initialZoom: 14),
            children: [
              TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
              MarkerLayer(markers: [
                Marker(point: _appointmentLocation, child: const Icon(Icons.location_pin, color: Colors.red, size: 45)),
                if (_myLocation != null)
                  Marker(point: _myLocation!, child: const Icon(Icons.circle, color: Colors.blue, size: 18)),
              ]),
            ],
          )),
        ),
        Positioned(bottom: 10, left: 10, child: FloatingActionButton.small(backgroundColor: Colors.white, onPressed: _launchGoogleMaps, child: const Icon(Icons.directions, color: Colors.blue))),
      ],
    );
  }

  Widget _buildActionButtons(bool isCreator, List<dynamic> confirmed, bool isDarkMode) {
    if (isCreator) {
      return _gradBtn("إرسال تذكير للمشاركين", _sendReminder);
    } else {
      bool isMeIn = confirmed.contains(FirebaseAuth.instance.currentUser?.email);
      return _gradBtn(isMeIn ? "تم تأكيد الحضور" : "تأكيد الحضور", () async {
        if (!isMeIn) {
          await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
            'confirmedParticipants': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.email])
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تأكيد حضورك بنجاح")));
          }
        }
      }, isGreen: isMeIn);
    }
  }

  Future<void> _sendReminder() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري إرسال التنبيهات للمشاركين")));
    for (var p in _participantsData) {
      var userSnap = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: p['email']).get();
      if (userSnap.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'user_id': userSnap.docs.first.id,
          'title': 'تذكير بموعد',
          'body': 'إشعار بخصوص الموعد في: $_addressTitle',
          'is_read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال التنبيهات بنجاح")));
    }
  }

  Widget _gradBtn(String t, VoidCallback o, {bool isGreen = false}) => Container(
    width: double.infinity, height: 50,
    decoration: BoxDecoration(gradient: LinearGradient(colors: isGreen ? [Colors.green, Colors.greenAccent] : [const Color(0xFFFFB6A1), const Color(0xFFFF8EAC)]), borderRadius: BorderRadius.circular(30)),
    child: ElevatedButton(onPressed: o, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );

  Widget _buildTile(IconData i, String t, bool isDarkMode) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02), blurRadius: 10)]),
    child: Row(children: [Icon(i, color: Colors.purpleAccent), const SizedBox(width: 15), Expanded(child: Text(t, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))]),
  );

  Widget _buildParticipantsTile(List<dynamic> confirmed, bool isDarkMode) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Text("المشاركون (${_participantsData.length})", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
      const Spacer(),
      SizedBox(height: 35, width: 80, child: Stack(children: List.generate(_participantsData.length > 3 ? 3 : _participantsData.length, (i) {
        return Positioned(right: i * 18.0, child: CircleAvatar(radius: 17, backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white, child: CircleAvatar(radius: 15, backgroundColor: Colors.grey[300], child: Text(_participantsData[i]['name'][0].toUpperCase(), style: const TextStyle(fontSize: 10)))));
      }))),
      Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.white60 : Colors.grey),
    ]),
  );

  void _showParticipantsStatus(List<dynamic> confirmed, bool isDarkMode) {
    showModalBottomSheet(context: context, backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("قائمة الحضور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), const Divider(), ..._participantsData.map((u) { bool arrived = confirmed.contains(u['email']); return ListTile(leading: CircleAvatar(child: Text(u['name'][0].toUpperCase())), title: Text(u['name'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)), trailing: Text(arrived ? "تم الوصول" : "في الطريق", style: TextStyle(color: arrived ? Colors.green : Colors.orange))); }).toList()])));
  }

  Future<void> _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
  }

  Future<void> _fetchParticipants(List<dynamic> emails) async {
    List<Map<String, dynamic>> temp = [];
    for (var e in emails) { var s = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: e).get(); temp.add({'name': s.docs.isNotEmpty ? s.docs.first['name'] : e, 'email': e}); }
    if (mounted) setState(() => _participantsData = temp);
  }

  Future<void> _updateMapCenter(String addr) async {
    try {
      final res = await http.get(Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$addr'));
      if (res.statusCode == 200) { final d = json.decode(res.body); if (d.isNotEmpty && mounted) { setState(() => _appointmentLocation = LatLng(double.parse(d[0]['lat']), double.parse(d[0]['lon']))); _calculateDeparture(); } }
    } catch (e) { debugPrint("Map error"); }
  }
}
