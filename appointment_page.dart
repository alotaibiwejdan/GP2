import 'package:flutter/material.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool smartReminder = false;
  String reminderValue = "30 دقيقة";

  List<String> participants = [];
  TextEditingController participantController = TextEditingController();

  final Color primaryOrange = const Color(0xFFFF8C42);
  final Color lightOrange = const Color(0xFFFFE5D0);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "مرسال",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _buildLabelWithIcon("عنوان الموعد", Icons.calendar_today),
                      _buildTextField("اجتماع"),

                      const SizedBox(height: 16),

                      _buildLabelWithIcon("الموقع", Icons.location_on),
                      _buildTextField("طريق الملك عبدالله الرياض "),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabelWithIcon("التاريخ", Icons.calendar_today),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: _buildSelector(
                                    selectedDate == null
                                        ? "اختر تاريخ"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabelWithIcon("الوقت", Icons.access_time),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: _buildSelector(
                                    selectedTime == null
                                        ? "اختر وقت"
                                        : selectedTime!.format(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildLabelWithIcon(
                          "المشاركون (${participants.length})", Icons.group),

                      Row(
                        children: [

                         
                          Expanded(
                            child: TextField(
                              controller: participantController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: "أدخل اسم المشارك",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          
                          GestureDetector(
                            onTap: () {
                              if (participantController.text.isNotEmpty) {
                                setState(() {
                                  participants.add(participantController.text);
                                  participantController.clear();
                                });
                              }
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink.shade200,
                                    Colors.orange.shade200
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      
                      Wrap(
                        spacing: 8,
                        children: participants
                            .map((p) => Chip(label: Text(p)))
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: lightOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.notifications_active,
                                    color: primaryOrange),
                              ),
                              const SizedBox(width: 12),
                              const Text("التنبيهات الذكية",
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          Switch(
                            value: smartReminder,
                            activeColor: primaryOrange,
                            onChanged: (value) {
                              setState(() {
                                smartReminder = value;
                              });
                            },
                          )
                        ],
                      ),

                      if (smartReminder) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryOrange),
                          ),
                          child: DropdownButton<String>(
                            value: reminderValue,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: "15 دقيقة", child: Text("15 دقيقة")),
                              DropdownMenuItem(value: "30 دقيقة", child: Text("30 دقيقة")),
                              DropdownMenuItem(value: "ساعة", child: Text("ساعة")),
                              DropdownMenuItem(value: "ساعتين", child: Text("ساعتين")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                reminderValue = value!;
                              });
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      _buildLabelWithIcon("ملاحظات(اختياري)", Icons.note),
                      TextField(
                        maxLines: 3,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: "أضف اي ملاحظات اضافية عن الموعد",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

             
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [

                    
                    
                    Expanded(
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade200,
                              Colors.orange.shade200
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text(
                            "حفظ الموعد",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("إلغاء"),
                      ),
                    ),

                    const SizedBox(width: 10),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelWithIcon(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSelector(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> _pickTime() async {
    TimeOfDay? time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) setState(() => selectedTime = time);
  }
}