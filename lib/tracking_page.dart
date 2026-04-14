import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  // الدالة التي تفتح تطبيق قوقل ماب الحقيقي
  Future<void> _launchGoogleMaps() async {
    // إحداثيات موقع في الرياض (كمثال)
    const String lat = "24.7136";
    const String lng = "46.6753";
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. الخريطة (صورة من ملفات المشروع)
            Positioned.fill(
              child: GestureDetector(
                onTap: _launchGoogleMaps, // عند الضغط يفتح قوقل ماب الحقيقي
                child: Image.asset(
                  'assets/images/map.png', // تأكدي من وجود الصورة بهذا الاسم في مجلد assets
                  fit: BoxFit.cover,
                  // في حال نسيتي تحطين الصورة، بيطلع لون رمادي بدال الشاشة الحمراء
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: Text("اضغطي هنا لفتح قوقل ماب")),
                  ),
                ),
              ),
            ),

            // 2. شريط البحث العلوي (للزينة فقط مثل الفيجما)
            Positioned(
              top: 50, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 10),
                    Text("البحث عن موقع", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            // 3. البطاقة السفلية البيضاء
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الوقت والمسافة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("الوقت المتوقع", "12 دقيقة", Colors.redAccent),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        _buildStat("المسافة المتبقية", "5 كم", Colors.black87),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // معلومات الاجتماع
                    const Column(
                      children: [
                        Text("اجتماع مع فريق التسويق", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text("حي العليا، طريق الملك فهد، الرياض", 
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // الأزرار
                    Row(
                      children: [
                        _buildIconButton(Icons.share_outlined),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFE9E9),
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("إنهاء التتبع", 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعدة لعرض الأرقام
  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  // ويدجت مساعدة لزر المشاركة
  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: const Color(0xFFC875A8)),
    );
  }
}