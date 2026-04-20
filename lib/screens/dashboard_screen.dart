import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart'; // Ensure you have this service
import 'request_list_screen.dart'; // The screen that shows matching requests

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final NotificationService _notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Dashboard"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donor')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found."));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          bool isDonor = data['userType'] == 'Donor';
          String myBloodGroup = data['bloodGroup'] ?? "?";

          // --- NOTIFICATION LOGIC ---
          // This automatically subscribes the donor to their blood group topic
          // so they only get alerts meant for them.
          if (isDonor && myBloodGroup != "?") {
            _notificationService.subscribeToBloodGroup(myBloodGroup);
          }

          // Calculate 90-day progress
          DateTime lastDonation =
              (data['lastDonationDate'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          DateTime nextEligible = lastDonation.add(const Duration(days: 90));
          int daysLeft = nextEligible.difference(DateTime.now()).inDays;
          if (daysLeft < 0) daysLeft = 0;
          double progress = (90 - daysLeft) / 90;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. User Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: Text(
                        myBloodGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      data['displayName'] ?? "User",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(data['email'] ?? ""),
                  ),
                ),

                const SizedBox(height: 25),

                // 2. VIEW MATCHING REQUESTS BUTTON
                // This allows donors to see only the requests that match them
                if (isDonor)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestListScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active),
                      label: Text("View Requests for $myBloodGroup"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                if (isDonor) ...[
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    "Donation Eligibility",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 3. ELIGIBILITY CIRCLE
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            daysLeft == 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            daysLeft == 0 ? "READY" : "$daysLeft",
                            style: const TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("Days Left"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 4. "I DONATED" BUTTON (Sets them offline)
                  ElevatedButton.icon(
                    onPressed: () async {
                      bool? confirm = await _showConfirm(context);
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('donor')
                            .doc(user?.uid)
                            .update({'lastDonationDate': Timestamp.now()});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Heroic act recorded! You are now offline for 90 days.",
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.volunteer_activism),
                    label: const Text("I Donated Today"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Confirmation Dialog
  Future<bool?> _showConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Donation"),
        content: const Text(
          "Did you complete a blood donation today? This will hide you from the search list for 90 days.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, I Donated"),
          ),
        ],
      ),
    );
  }
}
