import 'package:flutter/material.dart';

class EditAppointmentPage extends StatefulWidget {
  const EditAppointmentPage({super.key});

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final Color primaryOrange = const Color.fromARGB(255, 221, 138, 246);

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
            "تعديل الموعد",
            style: TextStyle(
              color: Color.fromARGB(255, 222, 139, 250),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
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

                      
                      _buildLabel("اسم الموعد"),
                      _buildTextField(
                        controller: titleController,
                        hint: "اكتب اسم الموعد",
                        icon: Icons.title,
                      ),

                      const SizedBox(height: 16),

                      
                      _buildLabel("الموقع"),
                      _buildTextField(
                        controller: locationController,
                        hint: "أدخل موقع الموعد",
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 16),

                      
                      Row(
                        children: [

                          /// التاريخ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("التاريخ"),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: _buildSelector(
                                    selectedDate == null
                                        ? "اختر تاريخًا"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                    Icons.calendar_month,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("الوقت"),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: _buildSelector(
                                    selectedTime == null
                                        ? "اختر وقتًا"
                                        : selectedTime!.format(context),
                                    Icons.
                                    access_time,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),

              
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                height: 85,
                child: ElevatedButton(
                  onPressed: () {
                    
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "حفظ التعديلات",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,

        prefixIcon: Icon(icon, color: primaryOrange),

        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  
  Widget _buildSelector(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  
  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  
  Future<void> _pickTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }
}