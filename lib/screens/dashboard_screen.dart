import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // --- LOGIC: ACCEPTANCE (Donor clicks this) ---
  Future<void> _handleAcceptance(String docId, String collection) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .update({
            "status": "Accepted",
            "acceptedBy": user?.uid,
            "acceptedAt": FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request Accepted! You are now matched."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- LOGIC: PHONE CALL (Requester clicks this) ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // --- PREVIOUS FEATURE: ELIGIBILITY RESET ---
  Future<void> _recordDonation() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Donation"),
        content: const Text("Reset your 90-day timer?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NO"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("YES"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('donor')
          .doc(user?.uid)
          .update({'lastDonationDate': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Dashboard"),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donor')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String myBlood = userData['bloodGroup'] ?? "?";
          String myCity = userData['city'] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ELIGIBILITY TRACKER (Kept from original)
                _buildProfileAndTimer(userData, myBlood),

                const SizedBox(height: 30),
                const Divider(),

                // 2. DONOR FEED: WHO NEEDS YOUR HELP?
                _sectionTitle(
                  "Emergency Alerts in $myCity",
                  Icons.bolt,
                  Colors.orange,
                ),
                _buildDonorFeed('blood_requests', myBlood, myCity),

                const SizedBox(height: 25),
                _sectionTitle("Planned Pre-bookings", Icons.event, Colors.blue),
                _buildDonorFeed('pre_bookings', myBlood, myCity),

                const Divider(height: 50),

                // 3. REQUESTER VIEW: MY POSTS & THE CALL BUTTON
                _sectionTitle(
                  "My Requests & Matched Donors",
                  Icons.person_pin_circle,
                  Colors.green,
                ),
                _buildMyRequestsSection(user!.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET: ELIGIBILITY TIMER ---
  Widget _buildProfileAndTimer(Map<String, dynamic> data, String blood) {
    DateTime lastDonation =
        (data['lastDonationDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
    int daysLeft = 90 - DateTime.now().difference(lastDonation).inDays;
    if (daysLeft < 0) daysLeft = 0;
    double progress = (90 - daysLeft) / 90;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red,
                child: Text(
                  blood,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                data['displayName'] ?? "Donor",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("City: ${data['city']}"),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: daysLeft == 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      daysLeft == 0 ? "OK" : "$daysLeft",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _recordDonation,
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text("I DONATED TODAY"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: DONOR VIEW (ACCEPT BUTTON) ---
  Widget _buildDonorFeed(String collection, String blood, String city) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('bloodGroup', isEqualTo: blood)
          .where('city', isEqualTo: city)
          .where('status', whereIn: ['Pending', 'Active'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Text(
            "No nearby requests.",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var req = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text("${req['bloodGroup']} at ${req['hospitalName']}"),
                subtitle: Text("Reason: ${req['reason']}"),
                trailing: ElevatedButton(
                  onPressed: () =>
                      _handleAcceptance(docs[index].id, collection),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ACCEPT"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET: REQUESTER VIEW (THE GREEN CALL LOGO) ---
  Widget _buildMyRequestsSection(String myUid) {
    // We combine streams from both collections to show all your posts
    return Column(
      children: [
        _requestStream('blood_requests', myUid),
        _requestStream('pre_bookings', myUid),
      ],
    );
  }

  Widget _requestStream(String collection, String myUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('requestedBy', isEqualTo: myUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var req = docs[index].data() as Map<String, dynamic>;
            bool isAccepted = req['status'] == "Accepted";
            String donorUid = req['acceptedBy'] ?? "";

            return Card(
              elevation: isAccepted ? 5 : 1,
              color: isAccepted ? Colors.green.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isAccepted ? Colors.green : Colors.grey.shade300,
                  width: isAccepted ? 2 : 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Text(
                  "${req['bloodGroup']} Request (${req['hospitalName']})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "STATUS: ${req['status'].toUpperCase()}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAccepted
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                      ),
                    ),
                    if (isAccepted)
                      const Text(
                        "✅ Donor Found! Tap the call icon to contact.",
                      ),
                  ],
                ),
                trailing: isAccepted
                    ? _buildLargeCallLogo(donorUid)
                    : const Icon(
                        Icons.timer_outlined,
                        color: Colors.orange,
                        size: 30,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET: HIGH VISIBILITY CALL BUTTON ---
  Widget _buildLargeCallLogo(String donorUid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donor')
          .doc(donorUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();
        var donorData = snapshot.data!.data() as Map<String, dynamic>;
        String phone = donorData['phone'] ?? "";

        return Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.call, color: Colors.white, size: 30),
            onPressed: () => _makePhoneCall(phone),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String t, IconData i, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        Icon(i, color: c, size: 24),
        const SizedBox(width: 8),
        Text(
          t,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
