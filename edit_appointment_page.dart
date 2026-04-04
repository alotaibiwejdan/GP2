import 'package:flutter/material.dart';

class EditAppointmentPage extends StatefulWidget {
  const EditAppointmentPage({super.key});

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final Color mersalPurple = const Color(0xFFBB86FC);
  final Color confirmRed = const Color(0xFFFF5A5A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("تعديل الموعد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("اسم الموعد"),
              _buildTextField(hint: "اجتماع فريق التسويق الأسبوعي", icon: Icons.title),
              const SizedBox(height: 20),
              _buildLabel("الموقع"),
              _buildTextField(hint: "مبنى innovations، الطابق السابع", icon: Icons.location_on_outlined),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("التاريخ"), _buildSelector("25 أكتوبر 2024", Icons.calendar_month)])),
                  const SizedBox(width: 15),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("الوقت"), _buildSelector("10:30 صباحاً", Icons.access_time)])),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: confirmRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("حفظ التعديلات", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(color: mersalPurple, fontWeight: FontWeight.bold)));

  Widget _buildTextField({required String hint, required IconData icon}) {
    return TextField(
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Icon(icon, color: mersalPurple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildSelector(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: const TextStyle(color: Colors.black54)), Icon(icon, color: mersalPurple)]),
    );
  }
}
