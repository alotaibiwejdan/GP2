import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; // هذا السطر هو الحل السحري

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  // الكنترولرز
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _participantController = TextEditingController();
  
  // قائمة المشاركين
  List<String> participantsList = [];

  bool isSwitched = true;
  String? selectedReminder;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  // دالة التحقق من وجود المستخدم وإضافته
  Future<void> _checkAndAddParticipant() async {
    String email = _participantController.text.trim();

    if (email.isEmpty) return;

    if (participantsList.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("هذا المشارك مضاف مسبقاً")),
      );
      return;
    }

    // إظهار مؤشر تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF857A6))),
    );

    try {
      // البحث في كولكشن المستخدمين
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (!mounted) return;
      Navigator.pop(context); // إغلاق التحميل

      if (userQuery.docs.isNotEmpty) {
        setState(() {
          participantsList.add(email);
          _participantController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم العثور على المستخدم وإضافته ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("عذراً، هذا الإيميل غير مسجل في مرسال ❌")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء التحقق: $e")),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _timeController.text = picked.format(context));
  }

  Future<void> _saveAppointment() async {
    if (_titleController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرجاء إكمال البيانات الأساسية والتاريخ")));
      return;
    }
    try {
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()));
      
      await FirebaseFirestore.instance.collection('appointments').add({
        'title': _titleController.text,
        'location_nameS': _locationController.text,
        'time': _timeController.text,
        'date': _dateController.text,
        'notes': _notesController.text,
        'participants': participantsList, 
        'smartNotifications': isSwitched,
        'reminderTime': selectedReminder ?? "لم يتم التحديد",
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isGroup': participantsList.isNotEmpty,
      });
      
      if (!mounted) return;
      Navigator.pop(context); // إغلاق التحميل
      Navigator.pop(context); // العودة للخلف
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ الموعد بنجاح! ✅")));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ أثناء الحفظ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("إضافة موعد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl, // أضفنا ui. قبل الكلمة
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("عنوان الموعد", Icons.edit),
              TextField(controller: _titleController, textAlign: TextAlign.right, decoration: _inputStyle("مثل: اجتماع مشروع", Icons.calendar_today)),
              
              const SizedBox(height: 20),
              _buildLabel("الموقع", Icons.location_on),
              TextField(controller: _locationController, textAlign: TextAlign.right, decoration: _inputStyle("مثل: جامعة الملك سعود", Icons.map)),

              const SizedBox(height: 20),
              
              _buildLabel("إضافة مشاركين", Icons.person_add_alt_1),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _participantController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputStyle("أدخل إيميل المشارك", Icons.add_circle_outline_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFFF857A6), size: 35),
                    onPressed: _checkAndAddParticipant,
                  ),
                ],
              ),
              
              if (participantsList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: participantsList.map((email) => Chip(
                      label: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFFF857A6))),
                      backgroundColor: const Color(0xFFFFE4F1),
                      onDeleted: () => setState(() => participantsList.remove(email)),
                      deleteIconColor: const Color(0xFFF857A6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )).toList(),
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(children: [
                      _buildLabel("الوقت", Icons.access_time),
                      TextField(controller: _timeController, readOnly: true, onTap: _selectTime, textAlign: TextAlign.right, decoration: _inputStyle("09:00 ص", Icons.timer)),
                    ]),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(children: [
                      _buildLabel("التاريخ", Icons.date_range),
                      TextField(controller: _dateController, readOnly: true, onTap: _selectDate, textAlign: TextAlign.right, decoration: _inputStyle("YYYY-MM-DD", Icons.today)),
                    ]),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [Icon(Icons.notifications_active, color: Color(0xFFFF5858)), SizedBox(width: 8), Text("التنبيهات الذكية", style: TextStyle(fontWeight: FontWeight.bold))]),
                        Switch(value: isSwitched, activeColor: const Color(0xFFF857A6), onChanged: (v) => setState(() => isSwitched = v)),
                      ],
                    ),
                    if (isSwitched)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedReminder,
                        hint: const Text("التذكير قبل الموعد بـ"),
                        decoration: _inputStyle("", Icons.alarm),
                        items: ['15 دقيقة', '30 دقيقة', 'ساعة واحدة', 'يوم واحد'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedReminder = v),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("ملاحظات", Icons.description),
              TextField(controller: _notesController, maxLines: 2, textAlign: TextAlign.right, decoration: _inputStyle("أضف ملاحظاتك هنا...", Icons.notes)),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15), 
                        gradient: const LinearGradient(colors: [Color(0xFFF857A6), Color(0xFFFF5858)])
                      ),
                      child: ElevatedButton(
                        onPressed: _saveAppointment,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text("حفظ الموعد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      suffixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFF857A6))),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Row(children: [Icon(icon, size: 16, color: const Color(0xFFF857A6)), const SizedBox(width: 8), Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))]),
    );
  }
}
