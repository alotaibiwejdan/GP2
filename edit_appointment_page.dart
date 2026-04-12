import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCurrentData(); // جلب البيانات من السيرفر لضمان المرونة
  }

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
          _locationController.text = data['location_name'] ?? ""; // تعديل المسمى هنا
          
          // محاولة قراءة التاريخ القديم إذا وجد
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          // محاولة قراءة الوقت القديم
          if (data['time'] != null) {
            // تحويل النص (مثلاً 3:30 PM) إلى TimeOfDay
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

  Future<void> _updateAppointment() async {
    if (widget.appointmentId.isEmpty) return;

    try {
      // نستخدم update لتعديل الحقول المحددة فقط
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'title': _titleController.text,
        'location_name': _locationController.text, // المسمى الصحيح
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
        : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("اسم الموعد"),
              _buildTextField(controller: _titleController, hint: "اسم الاجتماع", icon: Icons.title),
              const SizedBox(height: 20),
              _buildLabel("الموقع (العنوان)"),
              _buildTextField(controller: _locationController, hint: "المكان", icon: Icons.location_on_outlined),
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
                      ])),
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
                      ])),
                ],
              ),
              const Spacer(),
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
