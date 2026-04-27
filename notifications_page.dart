import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart'; // تأكدي من استيراد الملف الذي يحتوي على isGlobalDarkMode

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  
  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false) 
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'is_read': true});
      }
    } catch (e) {
      debugPrint("خطأ في التحديث: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = isGlobalDarkMode; // ✅ تفعيل الدارك مود

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // ✅ لون الخلفية يتغير حسب الثيم
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          title: Text("التنبيهات", 
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text("لا توجد تنبيهات حالياً", 
                  style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildNotificationCard(data, isDarkMode);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, bool isDarkMode) {
    IconData iconData;
    Color iconColor;
    
    // تحديد الأيقونة بناءً على النوع
    switch (data['type']) {
      case 'traffic':
        iconData = Icons.traffic;
        iconColor = Colors.orange;
        break;
      case 'weather':
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_active;
        iconColor = const Color(0xFFBB86FC);
    }

    bool isUnread = data['is_read'] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ لون البطاقة في الدارك مود
        color: isDarkMode 
            ? (isUnread ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E))
            : (isUnread ? Colors.blue.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // لجعل الأيقونة في الأعلى قليلاً
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ عرض العنوان (تذكير بموعد)
                Text(
                  data['title'] ?? 'تنبيه جديد', 
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ عرض محتوى الرسالة
                Text(
                  data['body'] ?? data['message_content'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_formatTimestamp(data['timestamp']), 
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          if (isUnread) 
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: CircleAvatar(radius: 4, backgroundColor: Colors.blue),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "";
    DateTime dt = (timestamp as Timestamp).toDate();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
