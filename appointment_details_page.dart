import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for database access
import 'edit_appointment_page.dart';

class AppointmentDetailsPage extends StatefulWidget {
  
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  final LatLng location = const LatLng(24.7136, 46.6753);

  // Design Colors
  final Color mersalPurple = const Color(0xFFBB86FC);
  final Color mersalGreyBG = const Color(0xFFFAFBFD);
  final Color deleteIconRed = const Color(0xFFFF6B6B);

  
  Future<void> _deleteFromFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments') 
          .doc(widget.appointmentId)
          .delete();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حذف الموعد بنجاح")),
        );
        // Go back to the previous screen (Appointments List)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء الحذف: $e")),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("تنبيه", style: TextStyle(fontFamily: 'Tajawal')),
            content: const Text("هل أنت متأكد؟", 
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Close pop-up
                child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deleteIconRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close pop-up
                  _deleteFromFirebase(); // Execute delete
                },
                child: const Text("حذف", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "تم التأكيد بنجاح",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF8EAC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
              // Suggested Departure Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                      child: const Icon(Icons.directions_car, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الوقت المقترح للمغادرة",
                              style: TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("غادر بحلول الساعة 3:45 مساءً",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Map Section
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: location, initialZoom: 13),
                    children: [
                      TileLayer(
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                      MarkerLayer(markers: [
                        Marker(
                            point: location,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40))
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Tile
              _buildMersalTile(
                  icon: Icons.location_on_outlined,
                  content: const Text("123 طريق الملك فهد، العليا، الرياض",
                      style: TextStyle(fontWeight: FontWeight.w500))),

              const SizedBox(height: 15),

              // Notes Tile
              _buildMersalTile(
                icon: Icons.sticky_note_2_outlined,
                content: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ملاحظات", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("لا توجد ملاحظات إضافية",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 35),

             
              Row(
                children: [
                  
                  GestureDetector(
                    onTap: _showDeleteDialog, 
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: deleteIconRed.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: deleteIconRed, size: 26),
                    ),
                  ),
                  const SizedBox(width: 10),

                  
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditAppointmentPage()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                            child: Text("تعديل",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => _showConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFFB6A1), Color(0xFFFF8EAC)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFFF8EAC).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                            child: Text("تأكيد الحضور",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ),
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

  Widget _buildMersalTile({required IconData icon, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
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






// before in the github:

// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'edit_appointment_page.dart'; 

// class AppointmentDetailsPage extends StatefulWidget {
//   const AppointmentDetailsPage({super.key});

//   @override
//   State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
// }

// class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
//   final LatLng location = const LatLng(24.7136, 46.6753);

//   // الألوان الهادية المعتمدة من تصميمك
//   final Color mersalPurple = const Color(0xFFBB86FC); 
//   final Color mersalGreyBG = const Color(0xFFFAFBFD);
//   final Color deleteIconRed = const Color(0xFFFF6B6B);

//   // دالة لإظهار رسالة التأكيد
//   void _showConfirmation(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text(
//           "تم التأكيد بنجاح",
//           textAlign: TextAlign.center,
//           style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFFFF8EAC), // لون وردي متناسق مع الزر
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: mersalGreyBG,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: const Text("تفاصيل الموعد", 
//             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//           centerTitle: true,
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//           child: Column(
//             children: [
//               // كرت وقت المغادرة المقترح
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF7F7), 
//                   borderRadius: BorderRadius.circular(20)
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
//                       child: const Icon(Icons.directions_car, color: Colors.white),
//                     ),
//                     const SizedBox(width: 15),
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("الوقت المقترح للمغادرة", 
//                             style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.bold)),
//                           SizedBox(height: 4),
//                           Text("غادر بحلول الساعة 3:45 مساءً", 
//                             style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // الخريطة
//               SizedBox(
//                 height: 220,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(25),
//                   child: FlutterMap(
//                     options: MapOptions(initialCenter: location, initialZoom: 13),
//                     children: [
//                       TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
//                       MarkerLayer(markers: [
//                         Marker(point: location, child: const Icon(Icons.location_pin, color: Colors.red, size: 40))
//                       ]),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // خانة الموقع - الأيقونة على اليمين
//               _buildMersalTile(
//                 icon: Icons.location_on_outlined, 
//                 content: const Text("123 طريق الملك فهد، العليا، الرياض",
//                     style: TextStyle(fontWeight: FontWeight.w500))
//               ),
              
//               const SizedBox(height: 15),

//               // خانة الملاحظات
//               _buildMersalTile(
//                 icon: Icons.sticky_note_2_outlined,
//                 content: const Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("ملاحظات", style: TextStyle(fontWeight: FontWeight.bold)),
//                     SizedBox(height: 4),
//                     Text("لا توجد ملاحظات إضافية", 
//                       style: TextStyle(color: Colors.grey, fontSize: 13)),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 35),

//               // الأزرار السفلية: حذف - تعديل - تأكيد حضور
//               Row(
//                 children: [
//                   // زر الحذف
//                   GestureDetector(
//                     onTap: () {},
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(15),
//                         border: Border.all(color: deleteIconRed.withOpacity(0.2)),
//                       ),
//                       child: Icon(Icons.delete_outline, color: deleteIconRed, size: 26),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
                  
//                   // زر تعديل
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAppointmentPage()));
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(15),
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                         child: const Center(child: Text("تعديل", style: TextStyle(fontWeight: FontWeight.bold))),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
                  
//                   // زر تأكيد الحضور المفعّل
//                   Expanded(
//                     flex: 2,
//                     child: GestureDetector(
//                       onTap: () => _showConfirmation(context), // هنا استدعاء الدالة
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(colors: [Color(0xFFFFB6A1), Color(0xFFFF8EAC)]),
//                           borderRadius: BorderRadius.circular(30),
//                           boxShadow: [
//                             BoxShadow(color: const Color(0xFFFF8EAC).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
//                           ],
//                         ),
//                         child: const Center(
//                           child: Text("تأكيد الحضور", 
//                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // الودجت الموحد للخانات مع أيقونة بنفسجية على اليمين
//   Widget _buildMersalTile({required IconData icon, required Widget content}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white, 
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: mersalPurple, size: 24),
//           const SizedBox(width: 15),
//           Expanded(child: content),
//         ],
//       ),
//     );
//   }
// }
