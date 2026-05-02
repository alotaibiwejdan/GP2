import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'dart:ui' as ui;

class EditAppointmentPage extends StatefulWidget {
  final String appointmentId;

  const EditAppointmentPage({
    super.key, 
    required this.appointmentId, 
  });

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final Color mersalPurple = const Color(0xFFBB86FC);
  final Color confirmRed = const Color(0xFFFF5A5A);

  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;

  // إضافات البحث عن الموقع (Nominatim)
  List<dynamic> _locationSuggestions = []; 
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCurrentData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // دالة جلب البيانات الحالية من الفايربيس
  Future<void> _fetchCurrentData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? "";
          _locationController.text = data['location_name'] ?? "";
          
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          if (data['time'] != null) {
            final format = DateFormat.jm(); 
            _selectedTime = TimeOfDay.fromDateTime(format.parse(data['time']));
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب بيانات التعديل: $e");
      setState(() => _isLoading = false);
    }
  }

  // دالة البحث عن الموقع (Autocomplete)
  void _onLocationChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _locationSuggestions = []);
        return;
      }

      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&limit=5');
        final response = await http.get(url, headers: {'User-Agent': 'Mersal_App_Project_V2'});

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _locationSuggestions = data;
            });
          }
        }
      } catch (e) {
        debugPrint("خطأ في جلب المواقع: $e");
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // دالة التحديث النهائي في قاعدة البيانات
  Future<void> _updateAppointment() async {
    if (widget.appointmentId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'title': _titleController.text,
        'location_name': _locationController.text, 
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': _selectedTime.format(context),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ التعديلات بنجاح ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء التحديث: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("تعديل الموعد",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("اسم الموعد"),
              _buildTextField(controller: _titleController, hint: "اسم الاجتماع", icon: Icons.title),
              
              const SizedBox(height: 20),
              _buildLabel("الموقع (العنوان)"),
              
              // حقل الموقع المطور مع البحث
              TextField(
                controller: _locationController,
                textAlign: TextAlign.right,
                onChanged: _onLocationChanged,
                decoration: InputDecoration(
                  hintText: "ابحث عن موقع...",
                  suffixIcon: Icon(Icons.location_on_outlined, color: mersalPurple),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),

              // قائمة الاقتراحات
              if (_locationSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _locationSuggestions.length,
                    itemBuilder: (context, index) {
                      final place = _locationSuggestions[index];
                      return ListTile(
                        title: Text(place['display_name'], style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _locationController.text = place['display_name'];
                            _locationSuggestions = []; 
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("التاريخ"),
                        _buildSelector(
                          DateFormat('yyyy-MM-dd').format(_selectedDate), 
                          Icons.calendar_month, 
                          _pickDate
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("الوقت"),
                        _buildSelector(
                          _selectedTime.format(context), 
                          Icons.access_time, 
                          _pickTime
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateAppointment,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: confirmRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("حفظ التعديلات",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets مساعدة للواجهة ---
  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: mersalPurple, fontWeight: FontWeight.bold)));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Icon(icon, color: mersalPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildSelector(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Icon(icon, color: mersalPurple, size: 20)
            ]),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import 'dart:ui' as ui;

class EditAppointmentPage extends StatefulWidget {
  final String appointmentId;

  const EditAppointmentPage({
    super.key, 
    required this.appointmentId, 
  });

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final Color mersalPurple = const Color(0xFFBB86FC);
  final Color confirmRed = const Color(0xFFFF5A5A);

  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;

  // إضافات البحث عن الموقع (Nominatim)
  List<dynamic> _locationSuggestions = []; 
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchCurrentData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // دالة جلب البيانات الحالية من الفايربيس
  Future<void> _fetchCurrentData() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();

      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _titleController.text = data['title'] ?? "";
          _locationController.text = data['location_name'] ?? "";
          
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          if (data['time'] != null) {
            final format = DateFormat.jm(); 
            _selectedTime = TimeOfDay.fromDateTime(format.parse(data['time']));
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب بيانات التعديل: $e");
      setState(() => _isLoading = false);
    }
  }

  // دالة البحث عن الموقع (Autocomplete)
  void _onLocationChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() => _locationSuggestions = []);
        return;
      }

      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(query)}&limit=5');
        final response = await http.get(url, headers: {'User-Agent': 'Mersal_App_Project_V2'});

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _locationSuggestions = data;
            });
          }
        }
      } catch (e) {
        debugPrint("خطأ في جلب المواقع: $e");
      }
    });
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // دالة التحديث النهائي في قاعدة البيانات
  Future<void> _updateAppointment() async {
    if (widget.appointmentId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'title': _titleController.text,
        'location_name': _locationController.text, 
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': _selectedTime.format(context),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حفظ التعديلات بنجاح ✅")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء التحديث: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("تعديل الموعد",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
        ),
        body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("اسم الموعد"),
              _buildTextField(controller: _titleController, hint: "اسم الاجتماع", icon: Icons.title),
              
              const SizedBox(height: 20),
              _buildLabel("الموقع (العنوان)"),
              
              // حقل الموقع المطور مع البحث
              TextField(
                controller: _locationController,
                textAlign: TextAlign.right,
                onChanged: _onLocationChanged,
                decoration: InputDecoration(
                  hintText: "ابحث عن موقع...",
                  suffixIcon: Icon(Icons.location_on_outlined, color: mersalPurple),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),

              // قائمة الاقتراحات
              if (_locationSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _locationSuggestions.length,
                    itemBuilder: (context, index) {
                      final place = _locationSuggestions[index];
                      return ListTile(
                        title: Text(place['display_name'], style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _locationController.text = place['display_name'];
                            _locationSuggestions = []; 
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("التاريخ"),
                        _buildSelector(
                          DateFormat('yyyy-MM-dd').format(_selectedDate), 
                          Icons.calendar_month, 
                          _pickDate
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("الوقت"),
                        _buildSelector(
                          _selectedTime.format(context), 
                          Icons.access_time, 
                          _pickTime
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateAppointment,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: confirmRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("حفظ التعديلات",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets مساعدة للواجهة ---
  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: mersalPurple, fontWeight: FontWeight.bold)));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Icon(icon, color: mersalPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildSelector(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              Icon(icon, color: mersalPurple, size: 20)
            ]),
      ),
    );
  }
}
