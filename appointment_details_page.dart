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
  String _exactDepartureTime = "--:--";
  String _weatherAndDuration = "جاري الحساب...";

  bool get isGlobalDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _determinePosition();
    await _fetchInitialDetails();
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

  Future<void> _fetchInitialDetails() async {
    var doc = await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).get();
    if (doc.exists && mounted) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        _addressTitle = data['location_name'] ?? "";
        _notes = data['notes'] ?? "";
        _creatorId = data['userId'] ?? "";
        _appointmentTimeStr = data['time'] ?? "04:00 PM";
      });
      _updateMapCenter(_addressTitle);
    }
  }

  Future<void> _calculateDeparture() async {
    if (_myLocation == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
        _myLocation!.latitude, _myLocation!.longitude,
        _appointmentLocation.latitude, _appointmentLocation.longitude
    );
    double distanceInKm = distanceInMeters / 1000;
    int baseTravelMinutes = (distanceInKm * 1.5).round() + 5; 

    double weatherDelayPercent = 0.0;
    double trafficDelayPercent = 0.15; 
    String reason = "الزحام المعتاد";

    try {
      final res = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${_appointmentLocation.latitude}&longitude=${_appointmentLocation.longitude}&current_weather=true'));

      if (res.statusCode == 200) {
        final wData = json.decode(res.body);
        int code = wData['current_weather']['weathercode'];
        if (code >= 51 && code <= 67) {
          weatherDelayPercent = 0.25;
          reason = "الأمطار والزحام ";
        } else if (code > 67) {
          weatherDelayPercent = 0.50;
          reason = "ظروف جوية صعبة ";
        }
      }
    } catch (e) {
      weatherDelayPercent = 0.05;
    }

    int extraMinutes = (baseTravelMinutes * (trafficDelayPercent + weatherDelayPercent)).round();
    int totalDuration = baseTravelMinutes + extraMinutes;

    try {
      int hour = int.parse(_appointmentTimeStr.split(':')[0]);
      int minute = int.parse(_appointmentTimeStr.split(':')[1].split(' ')[0]);
      if (_appointmentTimeStr.contains('PM') && hour != 12) hour += 12;
      if (_appointmentTimeStr.contains('AM') && hour == 12) hour = 0;

      DateTime appTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
      DateTime departTime = appTime.subtract(Duration(minutes: totalDuration));

      if (mounted) {
        setState(() {
          _exactDepartureTime = "${departTime.hour % 12 == 0 ? 12 : departTime.hour % 12}:${departTime.minute.toString().padLeft(2, '0')} ${departTime.hour >= 12 ? 'PM' : 'AM'}";
          _weatherAndDuration = "يستغرق الطريق $totalDuration دقيقة تقريباً بسبب $reason";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exactDepartureTime = "خطأ في الوقت");
    }
  }

  Future<void> _sendReminderToBellOnly(List<dynamic> participantEmails) async {
    String appointmentTitle = widget.appointmentData['title'] ?? 'الموعد';
    String myName = FirebaseAuth.instance.currentUser?.displayName ?? "منظم الموعد";

    for (String email in participantEmails) {
      try {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase().trim())
            .get();

        if (userQuery.docs.isNotEmpty) {
          String targetUserId = userQuery.docs.first.id;

          await FirebaseFirestore.instance.collection('notifications').add({
            'user_id': targetUserId,
            'title': 'تذكير بموعد ',
            'body': 'يُذكرك $myName بحضور موعد "$appointmentTitle" المقرّر اليوم.',
            'type': 'traffic',
            'is_read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("خطأ في إرسال التنبيه إلى الجرس للإيميل $email: $e");
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" تم إرسال التذكير إلى جرس المشاركين بنجاح"), backgroundColor: Color(0xFF9575CD)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = isGlobalDarkMode;
    String myId = FirebaseAuth.instance.currentUser?.uid ?? "";
    String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).snapshots(),
      builder: (context, snapshot) {
        List<dynamic> confirmed = [];
        List<dynamic> participants = [];
        bool isCreator = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          var d = snapshot.data!.data() as Map<String, dynamic>;
          confirmed = d['confirmedParticipants'] ?? [];
          List<dynamic> rawParticipants = d['participants'] ?? [];
          String dbCreatorId = d['userId'] ?? "";
          isCreator = (myId == dbCreatorId);
          
          participants = rawParticipants.where((email) => email != myEmail || !isCreator).toList();
        }

        bool hasParticipants = participants.isNotEmpty;

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
                if (hasParticipants) ...[
                  GestureDetector(
                    onTap: () => _showParticipantsStatus(participants, confirmed, isDarkMode),
                    child: _buildParticipantsTile(participants, isDarkMode),
                  ),
                  const SizedBox(height: 15),
                ],
                _buildTile(Icons.sticky_note_2_outlined, _notes.isEmpty ? "لا توجد ملاحظات" : _notes, isDarkMode),
                const SizedBox(height: 35),
                _buildDynamicActionButtons(isCreator, hasParticipants, participants, confirmed, isDarkMode),
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

  Widget _buildParticipantsTile(List<dynamic> emails, bool isDarkMode) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Text("المشاركون (${emails.length})", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
      const Spacer(),
      SizedBox(height: 35, width: 80, child: Stack(children: List.generate(emails.length > 3 ? 3 : emails.length, (i) {
        return Positioned(right: i * 18.0, child: CircleAvatar(radius: 17, backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white, child: CircleAvatar(radius: 15, backgroundColor: Colors.purple[50], child: Text(emails[i][0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.purple)))));
      }))),
      Icon(Icons.arrow_forward_ios, size: 14, color: isDarkMode ? Colors.white60 : Colors.grey),
    ]),
  );

  Widget _buildDynamicActionButtons(bool isCreator, bool hasParticipants, List<dynamic> participants, List<dynamic> confirmed, bool isDarkMode) {
    String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    if (isCreator) {
      return Column(children: [
        if (hasParticipants) ...[
          _gradBtn("إرسال تذكير للمشاركين ", () {
            _sendReminderToBellOnly(participants);
          }, isReminder: true),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Expanded(flex: 4, child: _gradBtn("تعديل الموعد", () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => EditAppointmentPage(appointmentId: widget.appointmentId)));
            _loadInitialData();
          })),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: _deleteIconButton()),
        ]),
      ]);
    } else {
      bool isMeIn = confirmed.contains(myEmail);
      return Row(children: [
        Expanded(flex: 4, child: _gradBtn(isMeIn ? "تم تأكيد حضورك " : "تأكيد الحضور", () async {
          if (!isMeIn) {
            await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
              'confirmedParticipants': FieldValue.arrayUnion([myEmail])
            });
          }
        }, isGreen: isMeIn)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _deleteIconButton()),
      ]);
    }
  }

  Widget _gradBtn(String t, VoidCallback? o, {bool isGreen = false, bool isReminder = false}) {
    List<Color> colors = [const Color(0xFFFFB6A1), const Color(0xFFFF8EAC)]; 
    if (isGreen) colors = [const Color(0xFF81C784), const Color(0xFF4CAF50)]; 
    if (isReminder) colors = [const Color(0xFFD1C4E9), const Color(0xFF9575CD)]; 

    return Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: o, 
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent, 
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ), 
        child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
      ),
    );
  }

  Widget _deleteIconButton() => Container(
    height: 50, decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(15)),
    child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _confirmDelete),
  );

  void _confirmDelete() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
      content: const Text("هل أنت متأكد من حذف هذا الموعد؟", textAlign: TextAlign.right),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        TextButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
          Navigator.pop(context); Navigator.pop(context);
        }, child: const Text("حذف", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showParticipantsStatus(List<dynamic> emails, List<dynamic> confirmed, bool isDarkMode) {
    showModalBottomSheet(
      context: context, 
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), 
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text("قائمة الحضور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), 
            const Divider(), 
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  String email = emails[index];
                  bool arrived = confirmed.contains(email);
                  
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('email', isEqualTo: email)
                        .get(),
                    builder: (context, snapshot) {
                      String displayName = email.split('@')[0];

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>?;
                        if (data != null && data.containsKey('name') && data['name'] != null) {
                          displayName = data['name'].toString();
                        }
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : "?", 
                            style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)
                          ),
                        ), 
                        title: Text(displayName, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)), 
                        subtitle: Text(email, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: arrived ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            arrived ? "تم التأكيد " : "لم يؤكد بعد ", 
                            style: TextStyle(color: arrived ? Colors.green : Colors.orange, fontSize: 12)
                          ),
                        ),
                      );
                    }
                  );
                }
              ),
            )
          ]
        )
      )
    );
  }

  Future<void> _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_appointmentLocation.latitude},${_appointmentLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
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
}/*import 'package:flutter/material.dart';
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

  Future<void> _calculateDeparture() async {
    if (_myLocation == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
        _myLocation!.latitude, _myLocation!.longitude,
        _appointmentLocation.latitude, _appointmentLocation.longitude
    );
    double distanceInKm = distanceInMeters / 1000;
    int baseTravelMinutes = (distanceInKm * 1.5).round() + 5; 

    double weatherDelayPercent = 0.0;
    double trafficDelayPercent = 0.15; 
    String reason = "الزحام المعتاد";

    try {
      final res = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${_appointmentLocation.latitude}&longitude=${_appointmentLocation.longitude}&current_weather=true'));

      if (res.statusCode == 200) {
        final wData = json.decode(res.body);
        int code = wData['current_weather']['weathercode'];
        if (code >= 51 && code <= 67) {
          weatherDelayPercent = 0.25;
          reason = "الأمطار والزحام 🌧️";
        } else if (code > 67) {
          weatherDelayPercent = 0.50;
          reason = "ظروف جوية صعبة ⚠️";
        }
      }
    } catch (e) {
      weatherDelayPercent = 0.05;
    }

    int extraMinutes = (baseTravelMinutes * (trafficDelayPercent + weatherDelayPercent)).round();
    int totalDuration = baseTravelMinutes + extraMinutes;

    try {
      int hour = int.parse(_appointmentTimeStr.split(':')[0]);
      int minute = int.parse(_appointmentTimeStr.split(':')[1].split(' ')[0]);
      if (_appointmentTimeStr.contains('PM') && hour != 12) hour += 12;
      if (_appointmentTimeStr.contains('AM') && hour == 12) hour = 0;

      DateTime appTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
      DateTime departTime = appTime.subtract(Duration(minutes: totalDuration));

      if (mounted) {
        setState(() {
          _exactDepartureTime = "${departTime.hour % 12 == 0 ? 12 : departTime.hour % 12}:${departTime.minute.toString().padLeft(2, '0')} ${departTime.hour >= 12 ? 'PM' : 'AM'}";
          _weatherAndDuration = "يستغرق الطريق $totalDuration دقيقة تقريباً بسبب $reason";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _exactDepartureTime = "خطأ في الوقت");
    }
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
    String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    if (isCreator) {
      return Column(children: [
        if (isGroup) ...[
          _gradBtn("إرسال تذكير للمشاركين 🔔", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إرسال تذكير للجميع"), backgroundColor: Color(0xFF9575CD)));
          }, isReminder: true),
          const SizedBox(height: 12),
        ],
        Row(children: [
          Expanded(flex: 4, child: _gradBtn("تعديل الموعد", () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => EditAppointmentPage(appointmentId: widget.appointmentId)));
            _loadAllData();
          })),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: _deleteIconButton()),
        ]),
      ]);
    } else if (isGroup) {
      bool isMeIn = confirmed.contains(myEmail);
      return Row(children: [
        Expanded(flex: 4, child: _gradBtn(isMeIn ? "تم تأكيد حضورك ✅" : "تأكيد الحضور", () async {
          if (!isMeIn) {
            await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
              'confirmedParticipants': FieldValue.arrayUnion([myEmail])
            });
          }
        }, isGreen: isMeIn)),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: _deleteIconButton()),
      ]);
    }
    return _deleteIconButton();
  }

  Widget _gradBtn(String t, VoidCallback o, {bool isGreen = false, bool isReminder = false}) {
    List<Color> colors = [const Color(0xFFFFB6A1), const Color(0xFFFF8EAC)]; // الوردي الأساسي
    if (isGreen) colors = [const Color(0xFF81C784), const Color(0xFF4CAF50)]; // الأخضر للتأكيد
    if (isReminder) colors = [const Color(0xFFD1C4E9), const Color(0xFF9575CD)]; // البنفسجي للتذكير

    return Container(
      width: double.infinity, height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(onPressed: o, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _deleteIconButton() => Container(
    height: 50, decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(15)),
    child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _confirmDelete),
  );

  void _confirmDelete() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
      content: const Text("هل أنت متأكد من حذف هذا الموعد؟", textAlign: TextAlign.right),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        TextButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).delete();
          Navigator.pop(context); Navigator.pop(context);
        }, child: const Text("حذف", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showParticipantsStatus(List<dynamic> confirmed, bool isDarkMode) {
    showModalBottomSheet(context: context, backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [Text("قائمة الحضور", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), const Divider(), ..._participantsData.map((u) { bool arrived = confirmed.contains(u['email']); return ListTile(leading: CircleAvatar(child: Text(u['name'][0].toUpperCase())), title: Text(u['name'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)), trailing: Text(arrived ? "تم التأكيد" : "لم يؤكد بعد", style: TextStyle(color: arrived ? Colors.green : Colors.orange))); }).toList()])));
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
