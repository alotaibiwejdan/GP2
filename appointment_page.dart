import 'package:flutter/material.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  bool isSwitched = true;
  String selectedReminder = '30 دقيقة';

  BoxDecoration _gradientDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: const LinearGradient(
        colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  // تعديل: النص يبدأ من اليمين والأيقونة في اليسار (suffix)
  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      suffixIcon: Icon(icon, color: Colors.grey[400]), // الأيقونة صارت يسار
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFF857A6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // سهم العودة لليمين (لأن التطبيق عربي)
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        leading: const SizedBox(), // إخفاء السهم التلقائي من اليسار
        title: Image.asset(
          'assets/images/logo.png', 
          height: 45,
          errorBuilder: (context, error, stackTrace) => const Text(
            "مرسال",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // توجيه الصفحة كاملة لليمين
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // يبدأ من يمين الصفحة
            children: [
              _buildLabel("عنوان الموعد", Icons.calendar_today),
              TextField(textAlign: TextAlign.right, decoration: _inputStyle("اجتماع", Icons.edit)),
              
              const SizedBox(height: 20),
              _buildLabel("الموقع", Icons.location_on),
              TextField(textAlign: TextAlign.right, decoration: _inputStyle("طريق الملك عبدالله، الرياض", Icons.map)),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("الوقت", Icons.access_time),
                        TextField(textAlign: TextAlign.right, decoration: _inputStyle("11:30 AM", Icons.timer)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("التاريخ", Icons.date_range),
                        TextField(textAlign: TextAlign.right, decoration: _inputStyle("02/08/2026", Icons.today)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildLabel("المشاركون (0)", Icons.groups),
              Row(
                children: [
                  Expanded(child: TextField(textAlign: TextAlign.right, decoration: _inputStyle("أدخل اسم المشارك ", Icons.person_add))),
                  const SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: _gradientDecoration(),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active, color: Color(0xFFFF5858)),
                            SizedBox(width: 8),
                            Text("التنبيهات الذكية", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                          ],
                        ),
                        Switch(
                          value: isSwitched,
                          activeColor: const Color(0xFFF857A6),
                          onChanged: (value) => setState(() => isSwitched = value),
                        ),
                      ],
                    ),
                    if (isSwitched)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        alignment: Alignment.centerRight,
                        value: selectedReminder,
                        decoration: _inputStyle("التذكير قبل الموعد بـ", Icons.alarm),
                        items: ['15 دقيقة', '30 دقيقة', 'ساعة واحدة']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e, textAlign: TextAlign.right)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedReminder = val!),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildLabel("ملاحظات (اختياري)", Icons.description),
              TextField(
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: _inputStyle("أضف أي ملاحظات إضافية عن الموعد...", Icons.notes),
              ),

              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: _gradientDecoration().copyWith(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF857A6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ]
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("حفظ الموعد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("إلغاء", style: TextStyle(color: Colors.grey, fontFamily: 'Tajawal')),
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

  Widget _buildLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // التسميات تبدأ من اليمين
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF857A6)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }
}
